create or replace function public.trigger_send_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform net.http_post(
    url := 'https://eswypmvrdgilkljytrxq.supabase.co/functions/v1/send-push',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'notifications',
      'schema', 'public',
      'record', to_jsonb(new),
      'old_record', null::jsonb
    )
  );
  return new;
end;
$$;

create trigger push_on_notification
after insert on public.notifications
for each row execute function public.trigger_send_push();
