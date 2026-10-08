-- Push diagnostics table: captures iOS push registration flow results
-- so we can debug remotely (no ADB/Xcode console for remote testers).
create table if not exists public.push_diagnostics (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  platform   text not null,
  payload    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- RLS: users can only read/write their own rows.
alter table public.push_diagnostics enable row level security;

create policy "Users can insert own push diagnostics"
  on public.push_diagnostics for insert
  with check (auth.uid() = user_id);

create policy "Users can read own push diagnostics"
  on public.push_diagnostics for select
  using (auth.uid() = user_id);

-- Index for quick lookups by user + time.
create index idx_push_diagnostics_user_created
  on public.push_diagnostics (user_id, created_at desc);
