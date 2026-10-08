import { createClient } from "npm:@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;
const FIREBASE_SERVICE_ACCOUNT = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON")!,
);

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: clubs, error: clubsError } = await supabase
      .from("clubs")
      .select("id, name");

    if (clubsError) throw clubsError;
    if (!clubs || clubs.length === 0) {
      return new Response(JSON.stringify({ clubs: 0, tokens: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const accessToken = await getFcmAccessToken();

    // Collect unique tokens across all clubs — one notification per device regardless
    // of how many clubs the user belongs to.
    const tokenToClub = new Map<string, { clubId: string; clubName: string }>();

    for (const club of clubs) {
      const { data: memberRows } = await supabase
        .from("club_members")
        .select("user_id")
        .eq("club_id", club.id);

      const memberIds = (memberRows ?? []).map((r: { user_id: string }) => r.user_id);
      if (memberIds.length === 0) continue;

      const { data: tokenRows } = await supabase
        .from("device_tokens")
        .select("token")
        .in("user_id", memberIds);

      for (const row of (tokenRows ?? []) as { token: string }[]) {
        if (!tokenToClub.has(row.token)) {
          tokenToClub.set(row.token, { clubId: club.id, clubName: club.name });
        }
      }
    }

    const results = await Promise.allSettled(
      [...tokenToClub.entries()].map(([token, { clubId, clubName }]) =>
        sendFcmMessage(supabase, accessToken, token, clubId, clubName)
      ),
    );
    const failures = results.filter(
      (result): result is PromiseRejectedResult => result.status === "rejected",
    );
    for (const failure of failures) {
      console.error("weekly notification delivery failed:", failure.reason);
    }

    return new Response(
      JSON.stringify({
        clubs: clubs.length,
        tokens: tokenToClub.size,
        sent: tokenToClub.size - failures.length,
        failed: failures.length,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("send-weekly-reminder error:", err);
    return new Response(String(err), { status: 500 });
  }
});

// FCM error codes that indicate a permanently invalid token.
const STALE_TOKEN_ERRORS = ["UNREGISTERED", "NOT_FOUND", "INVALID_ARGUMENT"];

async function sendFcmMessage(
  supabase: ReturnType<typeof createClient>,
  accessToken: string,
  token: string,
  clubId: string,
  clubName: string,
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
          notification: {
            title: "🏆 Weekly Leaderboard",
            body: `How did ${clubName} do this week? Tap to share the results.`,
          },
          data: {
            type: "weekly_reminder",
            club_id: clubId,
          },
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
  const sigB64 = toBase64UrlFromBuffer(signature);
  const jwt = `${signingInput}.${sigB64}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!res.ok || !json.access_token) {
    throw new Error(`Google OAuth failed: ${JSON.stringify(json)}`);
  }
  return json.access_token as string;
}

function toBase64Url(str: string): string {
  return btoa(unescape(encodeURIComponent(str)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function toBase64UrlFromBuffer(buffer: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}
