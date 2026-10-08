import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response("Missing authorization", { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace("Bearer ", ""),
  );

  if (authError || !user) {
    return new Response("Unauthorized", { status: 401 });
  }

  const userId = user.id;
  const email = user.email;

  // Must delete before auth user to lift ON DELETE RESTRICT on profiles
  const { error: inviteError } = await supabase
    .from("invite_codes")
    .delete()
    .eq("created_by", userId);

  if (inviteError) {
    console.error("Failed to delete invite codes:", inviteError);
    return new Response("Failed to delete account", { status: 500 });
  }

  // Deleting clubs cascades any remaining invite_codes for those clubs
  const { error: clubError } = await supabase
    .from("clubs")
    .delete()
    .eq("created_by", userId);

  if (clubError) {
    console.error("Failed to delete clubs:", clubError);
    return new Response("Failed to delete account", { status: 500 });
  }

  if (email) {
    await supabase
      .from("email_verifications")
      .delete()
      .eq("email", email.toLowerCase());
  }

  // Deleting the auth user cascades: profiles → club_members, activities, device_tokens, notifications
  const { error: deleteError } = await supabase.auth.admin.deleteUser(userId);

  if (deleteError) {
    console.error("Failed to delete auth user:", deleteError);
    return new Response("Failed to delete account", { status: 500 });
  }

  return new Response(JSON.stringify({ deleted: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
