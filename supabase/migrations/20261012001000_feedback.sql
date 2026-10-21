-- ============================================================
-- In-app Feedback (beta)
-- ============================================================
-- Lets beta testers submit bugs, feature requests, and UI/UX
-- feedback directly from the app. Admins are push-notified on
-- each submission. Status is updated via Supabase dashboard.
--
-- Rate limit: 5 submissions per user per calendar day
-- (enforced client-side; server guard below as safety net).
-- ============================================================

-- Enums
create type public.feedback_category as enum ('bug', 'feature', 'ui_ux', 'general');
create type public.feedback_screen   as enum ('tracking', 'leaderboard', 'share_card', 'clubs', 'health_import', 'profile', 'other');
create type public.feedback_status   as enum ('submitted', 'reviewing', 'fixed', 'noted');

-- Table
create table public.feedback (
  id             uuid                    primary key default gen_random_uuid(),
  user_id        uuid                    not null references public.profiles(id) on delete cascade,
  category       public.feedback_category not null,
  screen         public.feedback_screen   not null,
  description    text                    not null check (char_length(btrim(description)) between 1 and 2000),
  screenshot_url text,
  app_version    text,
  platform       text,
  os_version     text,
  status         public.feedback_status  not null default 'submitted',
  created_at     timestamptz             not null default now()
);

create index feedback_user_created_idx on public.feedback (user_id, created_at desc);

-- RLS
alter table public.feedback enable row level security;

create policy "Users can insert own feedback"
  on public.feedback for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and (
      select count(*)
      from public.feedback f
      where f.user_id = auth.uid()
        and f.created_at >= date_trunc('day', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata'
    ) < 5
  );

create policy "Users can read own feedback"
  on public.feedback for select
  to authenticated
  using (user_id = auth.uid());

-- Service-role (dashboard) can read/update all — no policy needed, bypasses RLS.

-- ============================================================
-- Storage bucket for screenshots
-- ============================================================
insert into storage.buckets (id, name, public)
values ('feedback-screenshots', 'feedback-screenshots', true)
on conflict (id) do nothing;

create policy "Users upload own feedback screenshots"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'feedback-screenshots'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Public read feedback screenshots"
  on storage.objects for select
  to public
  using (bucket_id = 'feedback-screenshots');

-- ============================================================
-- Push-notify admins on new feedback
-- ============================================================
-- Reuses the existing send-push Edge Function (extended to
-- handle table = 'feedback'). Sends one FCM push per admin.
-- ============================================================
create or replace function public.trigger_feedback_notify_admins()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  admin_rec record;
  submitter  text;
begin
  select display_name into submitter
  from public.profiles where id = new.user_id;

  for admin_rec in
    select distinct cm.user_id
    from public.club_members cm
    where cm.role = 'admin'
      and cm.user_id != new.user_id
  loop
    perform net.http_post(
      url     := 'https://eswypmvrdgilkljytrxq.supabase.co/functions/v1/send-push',
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body    := jsonb_build_object(
        'type',   'INSERT',
        'table',  'feedback',
        'record', jsonb_build_object(
          'id',           new.id,
          'user_id',      admin_rec.user_id,
          'from_user_id', new.user_id,
          'type',         'feedback',
          'category',     new.category,
          'screen',       new.screen,
          'submitter',    coalesce(submitter, 'Someone')
        )
      )
    );
  end loop;

  return new;
end;
$$;

create trigger feedback_notify_admins
after insert on public.feedback
for each row execute function public.trigger_feedback_notify_admins();
