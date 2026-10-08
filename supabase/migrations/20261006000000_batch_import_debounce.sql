-- ============================================================
-- Batch-import notification debounce
-- ============================================================
-- Problem: when a user imports activities from their watch
-- (Health Connect / HealthKit), each INSERT fires the
-- trigger_activity_notification trigger. The existing 5-minute
-- debounce checks activity_notifications_log, but that table is
-- populated ASYNC by the edge function (via pg_net). During a
-- bulk import, all triggers fire before any edge function
-- completes → all debounce checks find 0 rows → every import
-- sends a push notification. 10 imported activities = 10 pushes
-- to every co-member. Worse than spam.
--
-- Fix: add a second debounce specifically for import sources
-- that checks the activities table itself. Activity rows are
-- committed synchronously (the trigger runs AFTER INSERT within
-- the same transaction), so a subsequent INSERT's trigger will
-- see the previous row and skip. The sequential await loop in
-- the Flutter import service guarantees ordering.
--
-- The existing notification-log debounce remains unchanged for
-- manual / GPS activities (where the async race doesn't apply
-- because users don't log 10 manual activities in 5 minutes).
-- ============================================================

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

  -- ── 5-minute debounce (notification log — covers manual / GPS) ──
  SELECT COUNT(*) INTO recent_count
  FROM public.activity_notifications_log
  WHERE actor_user_id = NEW.user_id
    AND created_at >= now() - interval '5 minutes';
  IF recent_count > 0 THEN
    RETURN NEW;
  END IF;

  -- ── Batch-import debounce (activities table — covers watch imports) ──
  -- The notification log debounce above can't catch rapid-fire imports
  -- because the log is written async by the edge function. Instead, check
  -- if this user already has another recently-created imported activity.
  -- That activity's trigger already fired the edge function; this one
  -- would just flood co-members with duplicate push notifications.
  IF NEW.source IN ('health_connect', 'healthkit') THEN
    SELECT COUNT(*) INTO recent_count
    FROM public.activities
    WHERE user_id = NEW.user_id
      AND id != NEW.id
      AND source IN ('health_connect', 'healthkit')
      AND created_at >= now() - interval '5 minutes';
    IF recent_count > 0 THEN
      RETURN NEW;
    END IF;
  END IF;

  -- ── Fire the Edge Function (15s pg_net timeout) ──
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
      'source',        NEW.source,
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
