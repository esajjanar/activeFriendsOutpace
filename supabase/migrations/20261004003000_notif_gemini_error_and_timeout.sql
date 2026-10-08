-- ============================================================
-- Activity-notification diagnosability + pg_net timeout
-- ============================================================
-- Two fixes for debugging why Gemini falls back:
--  1. Capture the Gemini failure reason on the log row (gemini_error),
--     so it is readable regardless of pg_net timeouts.
--  2. Bump the pg_net call timeout from the default 5s to 15s. The
--     function (cold start + Gemini + FCM fan-out) can run ~10-12s; at
--     5s pg_net gave up, which both hid the response AND killed the
--     function before it could roll back the LLM budget counter
--     (llm_usage was climbing on failed calls).
-- ============================================================

ALTER TABLE public.activity_notifications_log
  ADD COLUMN IF NOT EXISTS gemini_error text;

CREATE OR REPLACE FUNCTION public.trigger_activity_notification()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  ist_hour integer;
  daily_count integer;
  recent_count integer;
  webhook_url text;
BEGIN
  -- ── Quiet hours: only 7am–22pm IST ──
  ist_hour := EXTRACT(HOUR FROM (now() AT TIME ZONE 'Asia/Kolkata'));
  IF ist_hour < 7 OR ist_hour >= 22 THEN
    RETURN NEW;
  END IF;

  -- ── Per-user throttle: max 3 notifications/user/day ──
  SELECT COUNT(*) INTO daily_count
  FROM public.activity_notifications_log
  WHERE actor_user_id = NEW.user_id
    AND created_at >= (CURRENT_DATE AT TIME ZONE 'Asia/Kolkata');
  IF daily_count >= 3 THEN
    RETURN NEW;
  END IF;

  -- ── 5-minute debounce ──
  SELECT COUNT(*) INTO recent_count
  FROM public.activity_notifications_log
  WHERE actor_user_id = NEW.user_id
    AND created_at >= now() - interval '5 minutes';
  IF recent_count > 0 THEN
    RETURN NEW;
  END IF;

  -- ── Fire the Edge Function (15s pg_net timeout; default 5s was too short) ──
  webhook_url := current_setting('app.settings.supabase_url', true);
  IF webhook_url IS NULL THEN
    webhook_url := 'https://eswypmvrdgilkljytrxq.supabase.co';
  END IF;

  PERFORM net.http_post(
    url    := webhook_url || '/functions/v1/send-activity-notification',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'X-Internal-Secret', coalesce(
        current_setting('app.settings.internal_webhook_secret', true),
        'outpace-529db47ea1d8d5caeafb019e69ae1968715833f1aae0bb61b9cb39f96b44f0ab'
      )
    ),
    body   := jsonb_build_object(
      'activity_id',   NEW.id,
      'user_id',       NEW.user_id,
      'type',          NEW.type,
      'distance_m',    NEW.distance_m,
      'moving_time_s', NEW.moving_time_s,
      'elapsed_s',     NEW.elapsed_s,
      'calories',      NEW.calories,
      'started_at',    NEW.started_at
    ),
    timeout_milliseconds := 15000
  );

  RETURN NEW;
END; $$;
