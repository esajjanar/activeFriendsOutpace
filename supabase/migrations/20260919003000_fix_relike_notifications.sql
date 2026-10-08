create or replace function public.notify_activity_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  owner_id uuid;
begin
  select user_id into owner_id
  from public.activities
  where id = new.activity_id;

  if owner_id <> new.user_id then
    insert into public.notifications (user_id, type, activity_id, from_user_id)
    values (owner_id, tg_argv[0]::public.notification_type, new.activity_id, new.user_id);
  end if;

  return new;
end;
$$;