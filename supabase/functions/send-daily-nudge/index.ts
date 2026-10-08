import { createClient } from "npm:@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;
const FIREBASE_SERVICE_ACCOUNT = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON")!,
);
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
// Alias that auto-tracks the current stable Flash model (see
// send-activity-notification for rationale). Override via GEMINI_MODEL.
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-flash-latest";
const GEMINI_TIMEOUT_MS = 8_000;
const DAILY_LLM_BUDGET = Number(Deno.env.get("LLM_DAILY_BUDGET") ?? "500");

// Fallback titles by bucket: none | low (1-33%) | mid (34-66%) |
// high (67-99%) | all (100%). Used when Gemini is unavailable.
const TITLES: Record<string, string[]> = {
  none: [
    "🦥 Zero. Absolutely zero.",
    "🛋️ The couch won today.",
    "💀 Not a single soul moved.",
    "😴 Everyone's in hibernation mode.",
    "☠️ 0 activities. Historic laziness.",
    "🥱 Even the pigeons got more steps.",
    "🌚 Dark day. Nobody logged. Shameful.",
  ],
  low: [
    "🐢 A brave few showed up.",
    "👀 Someone's watching you not log.",
    "😤 A handful of legends. The rest… resting.",
    "🔦 Tiny spark. Can it grow?",
    "🙄 That's it? That's all we got?",
    "🫠 Most of us dissolved into the sofa.",
    "🥴 Off to a rough start.",
  ],
  mid: [
    "⚔️ The group is split. Choose a side.",
    "🏃 Half in, half out. Classic.",
    "🤝 Exactly balanced. Like a fitness coin flip.",
    "😬 The logged are judging the unlogged.",
    "📊 50/50 day. Mediocrity in perfect form.",
    "🌓 Half the squad showed up. Literally.",
    "🎲 You had a 50% chance of logging. Did you?",
  ],
  high: [
    "🔥 Almost everyone. Don't be the reason 'almost'.",
    "😅 One straggler holds back perfection.",
    "💪 Peer pressure is clearly working.",
    "🏆 So close to a full house.",
    "👑 Most of the squad delivered.",
    "📣 The group is on fire. Catch up.",
    "😤 Everyone except a few. You know who you are.",
  ],
  all: [
    "🎉 FULL HOUSE. Everyone logged. Unreal.",
    "💯 Nobody made excuses today. Respect.",
    "🙌 The whole squad showed up. Legendary.",
    "🤯 All of you moved? On the same day?",
    "👑 Perfect day. Screenshot this.",
    "🏅 Zero excuses. Absolute beasts.",
    "🚀 Every. Single. One. Let's go.",
  ],
};

interface ClubStats {
  clubName: string;
  logged: number;
  total: number;
}

const BUCKET_ORDER: Record<string, number> = {
  none: 0, low: 1, mid: 2, high: 3, all: 4,
};

function getBucket(logged: number, total: number): string {
  if (logged === 0) return "none";
  if (logged === total) return "all";
  const pct = total > 0 ? logged / total : 0;
  if (pct <= 0.33) return "low";
  if (pct <= 0.66) return "mid";
  return "high";
}

// The user's "worst" club bucket drives the headline tone (max guilt).
function worstBucket(stats: ClubStats[]): string {
  let worst = "all";
  let worstOrder = 999;
  for (const cs of stats) {
    const b = getBucket(cs.logged, cs.total);
    const order = BUCKET_ORDER[b] ?? 999;
    if (order < worstOrder) {
      worstOrder = order;
      worst = b;
    }
  }
  return worst;
}

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Today's midnight in IST (UTC+5:30)
    const istOffsetMs = 5.5 * 60 * 60 * 1000;
    const istNow = new Date(Date.now() + istOffsetMs);
    const todayMidnightUtc = new Date(
      Date.UTC(istNow.getUTCFullYear(), istNow.getUTCMonth(), istNow.getUTCDate())
        - istOffsetMs,
    );

    // ── 1. Fetch all clubs ──────────────────────────────────────────────
    const { data: clubs, error: clubsError } = await supabase
      .from("clubs")
      .select("id, name");
    if (clubsError) throw clubsError;
    if (!clubs || clubs.length === 0) {
      return json({ sent: 0, reason: "no_clubs" });
    }

    // ── 2. Per-club: get members and today's activity count ─────────────
    const userClubStats = new Map<string, ClubStats[]>();

    for (const club of clubs) {
      const { data: memberRows } = await supabase
        .from("club_members")
        .select("user_id")
        .eq("club_id", club.id);

      const memberIds = (memberRows ?? []).map(
        (r: { user_id: string }) => r.user_id,
      );
      if (memberIds.length === 0) continue;

      // Who in this club logged today?
      const { data: activityRows } = await supabase
        .from("activities")
        .select("user_id")
        .in("user_id", memberIds)
        .gte("started_at", todayMidnightUtc.toISOString());

      const loggedSet = new Set(
        (activityRows ?? []).map((r: { user_id: string }) => r.user_id),
      );

      const stats: ClubStats = {
        clubName: club.name,
        logged: loggedSet.size,
        total: memberIds.length,
      };

      for (const uid of memberIds) {
        const existing = userClubStats.get(uid);
        if (existing) {
          existing.push(stats);
        } else {
          userClubStats.set(uid, [stats]);
        }
      }
    }

    if (userClubStats.size === 0) {
      return json({ sent: 0, reason: "no_members" });
    }

    // ── 3. Fetch device tokens grouped by user ──────────────────────────
    const allUserIds = [...userClubStats.keys()];

    const { data: tokenRows, error: tokenError } = await supabase
      .from("device_tokens")
      .select("user_id, token")
      .in("user_id", allUserIds);
    if (tokenError) throw tokenError;

    const userTokens = new Map<string, Set<string>>();
    for (const row of (tokenRows ?? []) as { user_id: string; token: string }[]) {
      const set = userTokens.get(row.user_id);
      if (set) {
        set.add(row.token);
      } else {
        userTokens.set(row.user_id, new Set([row.token]));
      }
    }

    if (userTokens.size === 0) {
      return json({ sent: 0, reason: "no_tokens" });
    }

    // ── 4. Generate titles, deduped by standings signature ──────────────
    // Many users share identical club standings (e.g. everyone in the same
    // single club), so we generate one title per unique signature and
    // reuse it — this keeps Gemini calls low and the group message
    // consistent across the group.
    const titleCache = new Map<string, string>();
    let geminiTitles = 0;
    let geminiError: string | null = null;

    async function titleForUser(stats: ClubStats[]): Promise<string> {
      const sig = JSON.stringify(
        [...stats]
          .sort((a, b) => a.clubName.localeCompare(b.clubName))
          .map((s) => [s.clubName, s.logged, s.total]),
      );
      const cached = titleCache.get(sig);
      if (cached) return cached;

      let title: string | null = null;
      if (GEMINI_API_KEY) {
        const r = await tryGeminiTitle(supabase, stats);
        if (r.title) {
          title = r.title;
          geminiTitles++;
        } else if (!geminiError) {
          geminiError = r.error;
        }
      }
      if (!title) {
        // Varied fallback: RANDOM pick (not day-of-year), so the title
        // differs day to day even without Gemini.
        const list = TITLES[worstBucket(stats)];
        title = list[Math.floor(Math.random() * list.length)];
      }
      titleCache.set(sig, title);
      return title;
    }

    // ── 5. Build per-user notification and send ─────────────────────────
    const accessToken = await getFcmAccessToken();
    let totalSent = 0;
    let totalFailed = 0;

    const sendTasks: Promise<void>[] = [];

    for (const [userId, tokens] of userTokens) {
      const clubStatsList = userClubStats.get(userId);
      if (!clubStatsList || clubStatsList.length === 0) continue;

      const title = await titleForUser(clubStatsList);

      // Body: one factual line per club (the grounded, real numbers).
      const body = clubStatsList
        .map((cs) => `${cs.clubName} — ${cs.logged} of ${cs.total} logged`)
        .join("\n");

      for (const token of tokens) {
        sendTasks.push(
          sendFcmMessage(supabase, accessToken, token, title, body)
            .then(() => { totalSent++; })
            .catch((err) => {
              totalFailed++;
              console.error("daily nudge delivery failed:", err);
            }),
        );
      }
    }

    await Promise.allSettled(sendTasks);

    return json({
      clubs: clubs.length,
      users: userClubStats.size,
      tokens: [...userTokens.values()].reduce((n, s) => n + s.size, 0),
      geminiTitles,
      geminiError,
      sent: totalSent,
      failed: totalFailed,
    });
  } catch (err) {
    console.error("send-daily-nudge error:", err);
    return new Response(String(err), { status: 500 });
  }
});

// ── Gemini title generation (budget + timeout + fallback) ─────
//
// Produces one short, funny GROUP headline grounded in the real
// standings. Group-framed only — never calls out an individual.

async function tryGeminiTitle(
  supabase: ReturnType<typeof createClient>,
  stats: ClubStats[],
): Promise<{ title: string | null; error: string | null }> {
  const { data: claimed } = await supabase.rpc("increment_llm_usage", {
    budget_limit: DAILY_LLM_BUDGET,
  });
  if (!claimed) {
    console.log("LLM daily budget exhausted, using fallback title");
    return { title: null, error: "budget_exhausted" };
  }

  try {
    const standings = stats
      .map((s) => `${s.clubName}: ${s.logged} of ${s.total} members logged a workout`)
      .join("; ");

    const systemPrompt =
      `You write a short, funny push-notification TITLE for the daily 7pm recap of ` +
      `a friends fitness club app called "Outpace". The title hypes or playfully shames ` +
      `the WHOLE GROUP based on how many people logged a workout today — never a single person.\n` +
      `Rules:\n` +
      `- Max 50 characters. 0-1 emoji. Plain text only — no quotes, no newlines, no hashtags.\n` +
      `- Be playful and a little savage, but never cruel or demotivating.\n` +
      `- Reflect the real turnout honestly (lots logged = hype; few logged = cheeky nudge).\n` +
      `- Output ONLY the title text.`;

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
        contents: [{
          role: "user",
          parts: [{ text: `Today's turnout — ${standings}.` }],
        }],
        generationConfig: {
          temperature: 1.1,
          maxOutputTokens: 120,
          // Disable Flash "thinking" (on by default on 2.5/3.x) — it eats the
          // token budget and returns empty text → title falls back every time.
          thinkingConfig: { thinkingBudget: 0 },
        },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!res.ok) {
      const body = await res.text();
      console.error(`Gemini HTTP ${res.status}: ${body}`);
      await supabase.rpc("decrement_llm_usage");
      return { title: null, error: `HTTP ${res.status}: ${body.slice(0, 300)}` };
    }

    const data = await res.json();
    const finish = data.candidates?.[0]?.finishReason;
    const text = (data.candidates?.[0]?.content?.parts?.[0]?.text ?? "")
      .trim()
      .replace(/^["']|["']$/g, ""); // strip stray wrapping quotes

    if (!text || text.length < 2 || text.length > 80 || text.includes("\n")) {
      console.warn("Gemini title rejected:", text);
      await supabase.rpc("decrement_llm_usage");
      return {
        title: null,
        error: `bad_output(finish=${finish}): ${text.slice(0, 120) || "<empty>"}`,
      };
    }

    return { title: text, error: null };
  } catch (err) {
    console.error("Gemini title call failed:", err);
    await supabase.rpc("decrement_llm_usage");
    return { title: null, error: `exception: ${String(err).slice(0, 200)}` };
  }
}

// FCM error codes that indicate a permanently invalid token.
const STALE_TOKEN_ERRORS = ["UNREGISTERED", "NOT_FOUND", "INVALID_ARGUMENT"];

async function sendFcmMessage(
  supabase: ReturnType<typeof createClient>,
  accessToken: string,
  token: string,
  title: string,
  body: string,
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
          data: { type: "daily_nudge" },
          android: {
            priority: "high",
            notification: {
              channel_id: "outpace_social_v2",
              icon: "ic_notification_wrapper",
            },
          },
          apns: { payload: { aps: { sound: "default" } } },
        },
      }),
    },
  );
  if (!res.ok) {
    const errorText = await res.text();
    // Auto-cleanup: delete permanently invalid tokens from the database
    const isStale = STALE_TOKEN_ERRORS.some((code) => errorText.includes(code));
    if (isStale) {
      const { error: delErr } = await supabase
        .from("device_tokens")
        .delete()
        .eq("token", token);
      if (delErr) {
        console.error(`failed to delete stale token ...${token.slice(-6)}:`, delErr);
      } else {
        console.log(`deleted stale token ...${token.slice(-6)}`);
      }
    }
    throw new Error(
      `FCM error for token ...${token.slice(-6)}: ${errorText}`,
    );
  }
}

function json(data: unknown): Response {
  return new Response(JSON.stringify(data), {
    headers: { "Content-Type": "application/json" },
  });
}

async function getFcmAccessToken(): Promise<string> {
  const encoder = new TextEncoder();
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
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(signingInput),
  );

  const jwt = `${signingInput}.${toBase64UrlFromBuffer(signature)}`;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const result = await res.json();
  if (!res.ok || !result.access_token) {
    throw new Error(`Google OAuth failed: ${JSON.stringify(result)}`);
  }
  return result.access_token as string;
}

function toBase64Url(str: string): string {
  return btoa(unescape(encodeURIComponent(str)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function toBase64UrlFromBuffer(buffer: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}
