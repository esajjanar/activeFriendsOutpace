-- When a device token is registered for a user, remove it from all other users.
-- This prevents the same physical device from receiving duplicate notifications
-- after sign-out / sign-in with a different account.
create or replace function public.claim_device_token()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.device_tokens
  where token = NEW.token
    and user_id <> NEW.user_id;
  return NEW;
end;
$$;

create trigger trg_claim_device_token
before insert or update on public.device_tokens
for each row execute function public.claim_device_token();
