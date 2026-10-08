create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

alter table public.device_tokens enable row level security;

create policy "Users manage own device tokens"
on public.device_tokens for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

grant all on public.device_tokens to authenticated;
