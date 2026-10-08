-- Enable pg_cron and pg_net extensions
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Schedule weekly leaderboard reminder every Sunday at 15:30 UTC (21:00 IST)
select cron.schedule(
  'weekly-leaderboard-reminder',
  '30 15 * * 0',
  $$
    select net.http_post(
      url    := 'https://eswypmvrdgilkljytrxq.supabase.co/functions/v1/send-weekly-reminder',
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body   := '{}'::jsonb
    );
  $$
);
