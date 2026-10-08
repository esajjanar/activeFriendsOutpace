-- Schedule daily activity nudge every day at 13:30 UTC (19:00 IST)
-- Sends one push to members who haven't logged yet, only if others already have
select cron.schedule(
  'daily-activity-nudge',
  '30 13 * * *',
  $$
    select net.http_post(
      url    := 'https://eswypmvrdgilkljytrxq.supabase.co/functions/v1/send-daily-nudge',
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body   := '{}'::jsonb
    );
  $$
);
