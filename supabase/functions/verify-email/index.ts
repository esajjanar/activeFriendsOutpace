import { createClient } from "npm:@supabase/supabase-js@2";

const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY")!;
const BREVO_FROM_EMAIL = Deno.env.get("BREVO_FROM_EMAIL")!;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  let body: { action?: string; email?: string; code?: string };
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const { action, email, code } = body;

  if (!action || !email) {
    return new Response("Missing action or email", { status: 400 });
  }

  const normalizedEmail = email.toLowerCase().trim();

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  if (action === "send") {
    const newCode = String(Math.floor(1000 + Math.random() * 9000));
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    const { error: dbError } = await supabase
      .from("email_verifications")
      .upsert(
        {
          email: normalizedEmail,
          code: newCode,
          expires_at: expiresAt,
          created_at: new Date().toISOString(),
        },
        { onConflict: "email" },
      );

    if (dbError) {
      console.error("DB upsert error:", dbError);
      return new Response("Failed to store code", { status: 500 });
    }

    const emailRes = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        "api-key": BREVO_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        sender: { name: "Outpace", email: BREVO_FROM_EMAIL },
        to: [{ email: normalizedEmail }],
        subject: "Your Outpace verification code",
        textContent: `Your Outpace verification code is: ${newCode}\n\nThis code expires in 10 minutes. If you didn't request this, ignore this email.`,
      }),
    });

    if (!emailRes.ok) {
      const errBody = await emailRes.text();
      console.error("Brevo error:", errBody);
      return new Response("Failed to send email", { status: 500 });
    }

    return new Response(JSON.stringify({ sent: true }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  if (action === "check") {
    if (!code) {
      return new Response(
        JSON.stringify({ verified: false, error: "Missing code" }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    const { data, error: dbError } = await supabase
      .from("email_verifications")
      .select("code, expires_at")
      .eq("email", normalizedEmail)
      .single();

    if (dbError || !data) {
      return new Response(
        JSON.stringify({
          verified: false,
          error: "No code found for this email. Request a new code.",
        }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    if (new Date(data.expires_at) < new Date()) {
      return new Response(
        JSON.stringify({
          verified: false,
          error: "Code expired. Request a new one.",
        }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    if (data.code !== code.trim()) {
      return new Response(
        JSON.stringify({
          verified: false,
          error: "Incorrect code. Check the email and try again.",
        }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    await supabase
      .from("email_verifications")
      .delete()
      .eq("email", normalizedEmail);

    return new Response(JSON.stringify({ verified: true }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response("Unknown action", { status: 400 });
});
