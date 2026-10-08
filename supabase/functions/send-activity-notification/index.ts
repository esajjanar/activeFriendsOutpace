/**
 * send-activity-notification
 *
 * Triggered by a DB trigger on `activities` INSERT (via pg_net).
 * Generates a creative push notification (title + body) using Gemini
 * Flash, falls back to magnitude-aware templates on any LLM failure,
 * then fans out via FCM to all co-members across shared clubs.
 *
 * Guardrails:
 *   - Internal secret header verification
 *   - Daily Gemini budget (atomic DB counter), claimed only for calls
 *     that actually succeed (failed calls are rolled back)
 *   - Gemini timeout → fallback
 *   - Output sanitization (bad JSON / length → fallback)
 *   - Stale FCM token cleanup on UNREGISTERED/NOT_FOUND
 *   - Logging every notification to activity_notifications_log
 */

import { createClient } from "npm:@supabase/supabase-js@2";

// ── Environment & constants ──────────────────────────────────

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;
const FIREBASE_SERVICE_ACCOUNT = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON")!,
);
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
// Alias that auto-tracks the current stable Flash model, so a future
// model retirement never 404s us again. Override via the GEMINI_MODEL
// secret to pin a specific version (e.g. "gemini-2.5-flash").
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-flash-latest";
const INTERNAL_SECRET = Deno.env.get("INTERNAL_WEBHOOK_SECRET") ??
  "outpace-internal-webhook-2026";
const GEMINI_TIMEOUT_MS = 8_000;
const DAILY_LLM_BUDGET = Number(Deno.env.get("LLM_DAILY_BUDGET") ?? "500");
const TITLE_MIN_CHARS = 2;
const TITLE_MAX_CHARS = 80;
const BODY_MIN_CHARS = 10;
const BODY_MAX_CHARS = 200;
const STALE_TOKEN_ERRORS = ["UNREGISTERED", "NOT_FOUND", "INVALID_ARGUMENT"];

interface Copy {
  title: string;
  body: string;
}

interface GeminiResult {
  copy: Copy | null;
  error: string | null;
}

// ── Payload from DB trigger ──────────────────────────────────

interface ActivityPayload {
  activity_id: string;
  user_id: string;
  type: string;
  source: string; // phone_gps | health_connect | healthkit | manual
  distance_m: number | null;
  moving_time_s: number | null;
  elapsed_s: number | null;
  calories: number | null;
  started_at: string;
}

// ── Main handler ─────────────────────────────────────────────

Deno.serve(async (req) => {
  try {
    // ── Verify internal secret ──
    const secret = req.headers.get("x-internal-secret");
    if (secret !== INTERNAL_SECRET) {
      return new Response("unauthorized", { status: 401 });
    }

    const payload: ActivityPayload = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // ── Fetch actor name ──
    const { data: actor } = await supabase
      .from("profiles")
      .select("display_name")
      .eq("id", payload.user_id)
      .single();

    const actorName = actor?.display_name ?? "Someone";

    // ── Find all co-members across shared clubs ──
    const { data: actorClubs } = await supabase
      .from("club_members")
      .select("club_id")
      .eq("user_id", payload.user_id);

    if (!actorClubs || actorClubs.length === 0) {
      return new Response("user not in any club", { status: 200 });
    }

    const clubIds = actorClubs.map((c: { club_id: string }) => c.club_id);

    const { data: coMembers } = await supabase
      .from("club_members")
      .select("user_id")
      .in("club_id", clubIds)
      .neq("user_id", payload.user_id);

    if (!coMembers || coMembers.length === 0) {
      return new Response("no co-members to notify", { status: 200 });
    }

    // Deduplicate user IDs (a user may share multiple clubs)
    const recipientIds = [
      ...new Set(coMembers.map((m: { user_id: string }) => m.user_id)),
    ];

    // ── Fetch device tokens for all recipients ──
    const { data: allTokens } = await supabase
      .from("device_tokens")
      .select("user_id, token")
      .in("user_id", recipientIds);

    if (!allTokens || allTokens.length === 0) {
      return new Response("no tokens for co-members", { status: 200 });
    }

    // ── Format activity stats ──
    const distanceKm = payload.distance_m
      ? payload.distance_m / 1000
      : null;
    const durationSecs = payload.moving_time_s ?? payload.elapsed_s ?? null;
    const durationStr = durationSecs ? formatDuration(durationSecs) : null;
    const caloriesStr = payload.calories ? `${payload.calories}` : null;

    // ── Generate creative message (Gemini → fallback) ──
    let content: Copy;
    let notifSource: "gemini" | "fallback";

    let geminiError: string | null = null;
    const gemini = GEMINI_API_KEY
      ? await tryGemini(
        supabase,
        actorName,
        payload.type,
        payload.source,
        distanceKm,
        durationStr,
        caloriesStr,
      )
      : { copy: null, error: "no_api_key" };

    if (gemini.copy) {
      content = gemini.copy;
      notifSource = "gemini";
    } else {
      content = pickFallback(
        actorName,
        payload.type,
        payload.source,
        distanceKm,
        durationStr,
        durationSecs,
      );
      notifSource = "fallback";
      geminiError = gemini.error;
    }

    // ── Send FCM to all co-members ──
    const accessToken = await getFcmAccessToken();

    const sendResults = await Promise.allSettled(
      allTokens.map((t: { user_id: string; token: string }) =>
        sendFcmMessage(
          supabase,
          accessToken,
          t.token,
          content.title,
          content.body,
          payload.activity_id,
        )
      ),
    );

    const sent = sendResults.filter((r) => r.status === "fulfilled").length;
    const failed = sendResults.filter((r) => r.status === "rejected").length;

    // ── Log the notification ──
    await supabase.from("activity_notifications_log").insert({
      actor_user_id: payload.user_id,
      activity_id: payload.activity_id,
      source: notifSource,
      message: `${content.title} — ${content.body}`,
      recipients_count: sent,
      gemini_error: geminiError,
    });

    return new Response(
      JSON.stringify({ source: notifSource, sent, failed, geminiError, ...content }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("send-activity-notification error:", err);
    return new Response(String(err), { status: 500 });
  }
});

// ── Gemini Flash call with budget + timeout + sanitization ───

async function tryGemini(
  supabase: ReturnType<typeof createClient>,
  name: string,
  type: string,
  activitySource: string,
  distanceKm: number | null,
  duration: string | null,
  calories: string | null,
): Promise<GeminiResult> {
  // ── Claim daily budget (atomic). Rolled back below if the call fails,
  //    so a failed/404 call never permanently burns a slot. ──
  const { data: claimed } = await supabase.rpc("increment_llm_usage", {
    budget_limit: DAILY_LLM_BUDGET,
  });
  if (!claimed) {
    console.log("LLM daily budget exhausted, using fallback");
    return { copy: null, error: "budget_exhausted" };
  }

  try {
    const distanceStr = distanceKm !== null ? `${distanceKm.toFixed(2)}km` : null;
    const statsLine = buildStatsLine(name, type, activitySource, distanceStr, duration, calories);

    const systemPrompt =
      `You write push notifications for "Outpace", a friends fitness club app. ` +
      `A member's activity was recorded and their friends receive this notification.\n` +
      `The input tells you HOW it was recorded:\n` +
      `- "just finished" = live GPS tracking from their phone (exciting, real-time)\n` +
      `- "synced from their watch" = imported from a smartwatch (still impressive, but not live — ` +
      `acknowledge it's a watch sync rather than pretending they just did it)\n` +
      `- "manually logged" = typed in by hand (respect the honesty, lighter energy)\n` +
      `Return JSON with "title" and "body".\n` +
      `- title: a short, punchy hook, max 40 characters, 0-1 emoji. Do NOT use the word "Outpace".\n` +
      `  For watch syncs, include ⌚ in the title. For manual logs, include ✍️.\n` +
      `- body: ONE witty, friendly line, max 110 characters, that references the ACTUAL stats given.\n` +
      `Rules:\n` +
      `- Be funny and lightly competitive to motivate others — never mean or discouraging.\n` +
      `- Match the real scale of the effort honestly: a 0.3km walk is a nice little stroll, ` +
      `NOT an epic journey; a 20km run is genuinely huge. Never exaggerate a small effort ` +
      `or downplay a big one.\n` +
      `- Vary the tone: sometimes impressed, sometimes jealous, sometimes dramatic, sometimes playful.\n` +
      `- Plain text only. No URLs, hashtags, code, markdown, or surrounding quotes.`;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);

    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY,
      },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: systemPrompt }] },
        contents: [{ role: "user", parts: [{ text: statsLine }] }],
        generationConfig: {
          temperature: 1.0,
          maxOutputTokens: 800,
          // Flash 2.5/3.x enable "thinking" by default; with a small token cap
          // it can spend the whole budget thinking and return empty/truncated
          // JSON → parse fails → every call silently falls back. Disable it.
          thinkingConfig: { thinkingBudget: 0 },
          responseMimeType: "application/json",
          responseSchema: {
            type: "OBJECT",
            properties: {
              title: { type: "STRING" },
              body: { type: "STRING" },
            },
            required: ["title", "body"],
            propertyOrdering: ["title", "body"],
          },
        },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!res.ok) {
      const errBody = await res.text();
      console.error(`Gemini HTTP ${res.status}: ${errBody}`);
      await supabase.rpc("decrement_llm_usage");
      return { copy: null, error: `http_${res.status}` };
    }

    const data = await res.json();
    const raw = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
    const parsed = parseCopy(raw);

    if (!parsed) {
      console.warn("Gemini output rejected:", raw);
      await supabase.rpc("decrement_llm_usage");
      return { copy: null, error: "parse_rejected" };
    }

    return { copy: parsed, error: null };
  } catch (err) {
    console.error("Gemini call failed:", err);
    await supabase.rpc("decrement_llm_usage");
    return { copy: null, error: String(err) };
  }
}

// Parse + validate the structured {title, body} JSON from Gemini.
function parseCopy(raw: string): Copy | null {
  try {
    const obj = JSON.parse(raw);
    const title = typeof obj.title === "string" ? obj.title.trim() : "";
    const body = typeof obj.body === "string" ? obj.body.trim() : "";
    if (
      title.length < TITLE_MIN_CHARS || title.length > TITLE_MAX_CHARS ||
      body.length < BODY_MIN_CHARS || body.length > BODY_MAX_CHARS ||
      title.includes("\n")
    ) {
      return null;
    }
    return { title, body };
  } catch {
    return null;
  }
}

// ── Magnitude-aware fallback templates ───────────────────────
//
// Keyed by activity type, then by a magnitude tier derived from the
// REAL distance (or duration for strength). This is what stops a
// 0.2km walk from being announced as "a journey".

type Tier = "tiny" | "short" | "long";

const FALLBACK: Record<string, Record<Tier, Copy[]>> = {
  walk: {
    tiny: [
      { title: "{name} got some steps 🚶", body: "{name} walked {distance}km. Every step counts — your move!" },
      { title: "A little stroll", body: "{name} squeezed in a {distance}km walk. Small, but moving beats sitting." },
    ],
    short: [
      { title: "{name} is out walking", body: "{name} walked {distance}km. Solid stroll — the couch misses you." },
      { title: "Steps logged 👟", body: "{name} knocked out a {distance}km walk. What's your excuse?" },
    ],
    long: [
      { title: "{name} went the distance", body: "{name} walked {distance}km. That's a proper trek!" },
      { title: "Big walk alert 🚶", body: "{name} covered {distance}km on foot. Legs of steel." },
    ],
  },
  run: {
    tiny: [
      { title: "{name} got moving 🏃", body: "{name} ran {distance}km. Short and sharp — it all adds up!" },
      { title: "Quick one in", body: "{name} logged a {distance}km run. Momentum started." },
    ],
    short: [
      { title: "{name} just ran", body: "{name} knocked out a {distance}km run. Respect." },
      { title: "Run logged 🏃", body: "{name} ran {distance}km. The leaderboard just got interesting." },
    ],
    long: [
      { title: "{name} is a machine", body: "{name} ran {distance}km. Lace up or fall behind!" },
      { title: "Huge run 🔥", body: "{name} ran {distance}km. Out there while you read this." },
    ],
  },
  cycle: {
    tiny: [
      { title: "{name} spun the wheels 🚴", body: "{name} cycled {distance}km. Quick spin, still counts!" },
      { title: "Short ride in", body: "{name} rode {distance}km. Wheels turning." },
    ],
    short: [
      { title: "{name} went for a ride", body: "{name} cycled {distance}km. Pedal power!" },
      { title: "Ride logged 🚴", body: "{name} rode {distance}km. Your bike is collecting dust." },
    ],
    long: [
      { title: "Tour de Friend Group", body: "{name} cycled {distance}km. Absolutely unstoppable." },
      { title: "Monster ride 🚴", body: "{name} rode {distance}km. Someone's chasing the leaderboard." },
    ],
  },
  strength: {
    tiny: [
      { title: "{name} hit the weights 💪", body: "{name} did {duration} of strength work. Quick hits still count." },
      { title: "Reps in", body: "{name} trained for {duration}. Showed up — that's the hard part." },
    ],
    short: [
      { title: "{name} is lifting 💪", body: "{name} trained for {duration}. Gains incoming." },
      { title: "Gym session logged", body: "{name} put in {duration} of strength work. Respect." },
    ],
    long: [
      { title: "{name} chose violence 💪", body: "{name} lifted for {duration}. Somewhere a dumbbell is crying." },
      { title: "Beast mode", body: "{name} trained for {duration} straight. Absolute unit." },
    ],
  },
};

const FALLBACK_OTHER: Copy[] = [
  { title: "{name} logged a session", body: "{name} is out there getting it done. What about you? 👀" },
  { title: "New activity 👀", body: "{name} just logged an activity. The club is watching." },
  { title: "{name} showed up", body: "{name} moved today. Your turn — no excuses left." },
];

function tierFor(
  type: string,
  distanceKm: number | null,
  durationSecs: number | null,
): Tier {
  // Distance-based types tier on km; strength tiers on minutes.
  if (type === "strength") {
    const mins = durationSecs ? durationSecs / 60 : 0;
    if (mins < 20) return "tiny";
    if (mins < 45) return "short";
    return "long";
  }
  if (distanceKm === null) {
    // No distance (e.g. GPS-less) → tier on duration if we have it.
    const mins = durationSecs ? durationSecs / 60 : 0;
    if (mins < 15) return "tiny";
    if (mins < 40) return "short";
    return "long";
  }
  const t = THRESHOLDS[type] ?? THRESHOLDS.walk;
  if (distanceKm < t[0]) return "tiny";
  if (distanceKm < t[1]) return "short";
  return "long";
}

// [tiny<x, short<y, else long] boundaries in km, tuned per activity.
const THRESHOLDS: Record<string, [number, number]> = {
  walk: [1, 4],
  run: [2, 7],
  cycle: [3, 15],
};

function pickFallback(
  name: string,
  type: string,
  activitySource: string,
  distanceKm: number | null,
  duration: string | null,
  durationSecs: number | null,
): Copy {
  const byTier = FALLBACK[type];
  let choices: Copy[];
  if (byTier) {
    const tier = tierFor(type, distanceKm, durationSecs);
    choices = byTier[tier];
    // If a distance-type has no usable distance AND no duration, the copy
    // would reference "{distance}km" with no value — prefer the generic set.
    if (type !== "strength" && distanceKm === null && !duration) {
      choices = FALLBACK_OTHER;
    }
  } else {
    choices = FALLBACK_OTHER;
  }

  const pick = choices[Math.floor(Math.random() * choices.length)];
  const distanceStr = distanceKm !== null ? distanceKm.toFixed(1) : "a few";
  const fill = (s: string) =>
    s
      .replace(/\{name\}/g, name)
      .replace(/\{distance\}/g, distanceStr)
      .replace(/\{duration\}/g, duration ?? "a session");

  let title = fill(pick.title);
  const body = fill(pick.body);

  // Prefix title with source indicator for non-GPS activities
  if (activitySource === "health_connect" || activitySource === "healthkit") {
    title = `⌚ ${title}`;
  } else if (activitySource === "manual") {
    title = `✍️ ${title}`;
  }

  return { title, body };
}

// ── Helpers ──────────────────────────────────────────────────

function buildStatsLine(
  name: string,
  type: string,
  activitySource: string,
  distance: string | null,
  duration: string | null,
  calories: string | null,
): string {
  const verb =
    activitySource === "health_connect" || activitySource === "healthkit"
      ? "synced from their watch a"
      : activitySource === "manual"
        ? "manually logged a"
        : "just finished a";
  const parts = [`${name} ${verb} ${type}`];
  if (distance) parts.push(distance);
  if (duration) parts.push(`in ${duration}`);
  if (calories) parts.push(`burning ${calories} calories`);
  return parts.join(", ") + ".";
}

function formatDuration(totalSeconds: number): string {
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  if (hours > 0) return `${hours}h ${minutes.toString().padStart(2, "0")}min`;
  return `${minutes}min`;
}

// ── FCM infrastructure (reused from send-push) ───────────────

async function getFcmAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const headerB64 = toBase64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payloadB64 = toBase64Url(
    JSON.stringify({
      iss: FIREBASE_SERVICE_ACCOUNT.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    }),
  );

  const signingInput = `${headerB64}.${payloadB64}`;

  const pemBody = FIREBASE_SERVICE_ACCOUNT.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const keyData = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const encoder = new TextEncoder();
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(signingInput),
  );

  const sigB64 = toBase64UrlFromBuffer(signature);
  const jwt = `${signingInput}.${sigB64}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const { access_token } = await res.json();
  return access_token;
}

async function sendFcmMessage(
  supabase: ReturnType<typeof createClient>,
  accessToken: string,
  token: string,
  title: string,
  body: string,
  activityId: string,
): Promise<void> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: { activity_id: activityId },
          android: {
            priority: "high",
            notification: {
              channel_id: "outpace_social_v2",
              icon: "ic_notification_wrapper",
            },
          },
          apns: {
            headers: { "apns-priority": "10" },
            payload: { aps: { sound: "default" } },
          },
        },
      }),
    },
  );

  if (!res.ok) {
    const errText = await res.text();
    // ── Stale token cleanup ──
    if (STALE_TOKEN_ERRORS.some((e) => errText.includes(e))) {
      console.warn(`Deleting stale token ...${token.slice(-6)}`);
      await supabase.from("device_tokens").delete().eq("token", token);
    }
    throw new Error(
      `FCM error for token ...${token.slice(-6)}: ${errText}`,
    );
  }
}

function toBase64Url(str: string): string {
  return btoa(unescape(encodeURIComponent(str)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function toBase64UrlFromBuffer(buffer: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}
