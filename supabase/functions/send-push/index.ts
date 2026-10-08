import { createClient } from "npm:@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;
const FIREBASE_SERVICE_ACCOUNT = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON")!,
);

interface WebhookPayload {
  type: "INSERT";
  table: string;
  record: {
    id: string;
    user_id: string;
    type: "reaction" | "comment";
    activity_id: string;
    from_user_id: string;
  };
}

Deno.serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json();
    const { record } = payload;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const [{ data: tokens }, { data: actor }] = await Promise.all([
      supabase
        .from("device_tokens")
        .select("token")
        .eq("user_id", record.user_id),
      supabase
        .from("profiles")
        .select("display_name")
        .eq("id", record.from_user_id)
        .single(),
    ]);

    if (!tokens || tokens.length === 0) {
      return new Response("no tokens", { status: 200 });
    }

    const actorName = actor?.display_name ?? "Someone";
    const body = record.type === "reaction"
      ? `${actorName} liked your activity`
      : `${actorName} commented on your activity`;

    const accessToken = await getFcmAccessToken();

    const results = await Promise.allSettled(
      tokens.map((t: { token: string }) =>
        sendFcmMessage(accessToken, t.token, "Outpace", body, record.activity_id)
      ),
    );
    const failures = results.filter(
      (result): result is PromiseRejectedResult => result.status === "rejected",
    );
    for (const failure of failures) {
      console.error("social notification delivery failed:", failure.reason);
    }

    return new Response(JSON.stringify({
      sent: tokens.length - failures.length,
      failed: failures.length,
    }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("send-push error:", err);
    return new Response(String(err), { status: 500 });
  }
});

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
  const { access_token } = await res.json();
  return access_token;
}

async function sendFcmMessage(
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
          apns: { payload: { aps: { sound: "default" } } },
        },
      }),
    },
  );
  if (!res.ok) {
    throw new Error(
      `FCM error for token ...${token.slice(-6)}: ${await res.text()}`,
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
