-- ============================================================
-- trigger_send_push v2
--
-- Replaces the bare Content-Type header with X-Internal-Secret
-- for consistency with trigger_activity_notification.
-- The Edge Function (send-push) must verify this header.
-- ============================================================

CREATE OR REPLACE FUNCTION public.trigger_send_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM net.http_post(
    url     := 'https://eswypmvrdgilkljytrxq.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'X-Internal-Secret', COALESCE(
        current_setting('app.settings.internal_webhook_secret', true),
        'outpace-529db47ea1d8d5caeafb019e69ae1968715833f1aae0bb61b9cb39f96b44f0ab'
      )
    ),
    body    := jsonb_build_object(
      'type',       'INSERT',
      'table',      'notifications',
      'schema',     'public',
      'record',     to_jsonb(NEW),
      'old_record', NULL::jsonb
    )
  );
  RETURN NEW;
END;
$$;
