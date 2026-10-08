create extension if not exists pgcrypto;

create type public.club_role as enum ('admin', 'member');
create type public.activity_type as enum ('run', 'walk', 'cycle', 'strength', 'other');
create type public.activity_source as enum ('health_connect', 'healthkit', 'phone_gps', 'manual');
create type public.activity_review_state as enum ('clean', 'needs_review');
create type public.activity_sync_status as enum ('synced', 'pending');
create type public.notification_type as enum ('reaction', 'comment');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  avatar_url text,
  created_at timestamptz not null default now()
);

create table public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 80),
  timezone text not null default 'Asia/Kolkata',
  week_start_day smallint not null default 1 check (week_start_day between 0 and 6),
  points_config jsonb not null default '{"run": 1.0, "walk": 0.7, "cycle": 0.3, "strength": 1.0}'::jsonb,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.club_members (
  club_id uuid not null references public.clubs (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.club_role not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (club_id, user_id)
);

create table public.invite_codes (
  code text primary key check (char_length(btrim(code)) > 0),
  club_id uuid not null references public.clubs (id) on delete cascade,
  created_by uuid not null references public.profiles (id) on delete restrict,
  expires_at timestamptz,
  max_uses integer not null default 10 check (max_uses > 0),
  uses_count integer not null default 0 check (uses_count >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type public.activity_type not null,
  started_at timestamptz not null,
  ended_at timestamptz,
  distance_m integer check (distance_m is null or distance_m >= 0),
  moving_time_s integer check (moving_time_s is null or moving_time_s >= 0),
  elapsed_s integer check (elapsed_s is null or elapsed_s >= 0),
  avg_hr integer check (avg_hr is null or avg_hr >= 0),
  max_hr integer check (max_hr is null or max_hr >= 0),
  calories integer check (calories is null or calories >= 0),
  source public.activity_source not null,
  external_id text,
  notes text,
  track_summary jsonb,
  review_state public.activity_review_state not null default 'clean',
  dup_group_id uuid,
  excluded boolean not null default false,
  status public.activity_sync_status not null default 'pending',
  created_at timestamptz not null default now(),
  check (ended_at is null or ended_at >= started_at),
  unique (user_id, source, external_id)
);

create table public.track_points (
  activity_id uuid not null references public.activities (id) on delete cascade,
  seq integer not null check (seq >= 0),
  lat double precision not null check (lat between -90 and 90),
  lon double precision not null check (lon between -180 and 180),
  ts timestamptz not null,
  ele double precision,
  accuracy double precision check (accuracy is null or accuracy >= 0),
  primary key (activity_id, seq)
);

create table public.weekly_snapshots (
  club_id uuid not null references public.clubs (id) on delete cascade,
  week_start date not null,
  member_stats jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  primary key (club_id, week_start)
);

create table public.activity_reactions (
  activity_id uuid not null references public.activities (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  reaction text not null check (char_length(btrim(reaction)) between 1 and 32),
  created_at timestamptz not null default now(),
  primary key (activity_id, user_id)
);

create table public.activity_comments (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type public.notification_type not null,
  activity_id uuid not null references public.activities (id) on delete cascade,
  from_user_id uuid not null references public.profiles (id) on delete cascade,
  seen boolean not null default false,
  created_at timestamptz not null default now()
);

create index club_members_user_id_idx on public.club_members (user_id, club_id);
create index activities_user_started_at_idx on public.activities (user_id, started_at desc);
create index activities_review_idx on public.activities (user_id, review_state) where review_state = 'needs_review';
create index activity_reactions_activity_id_idx on public.activity_reactions (activity_id);
create index activity_comments_activity_id_created_at_idx on public.activity_comments (activity_id, created_at);
create index notifications_unread_idx on public.notifications (user_id, seen, created_at desc);

create or replace function public.is_club_member(target_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.club_members
    where club_id = target_club_id and user_id = auth.uid()
  )
$$;

create or replace function public.is_club_admin(target_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.club_members
    where club_id = target_club_id
      and user_id = auth.uid()
      and role = 'admin'
  )
$$;

create or replace function public.can_view_activity(target_activity_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.activities activity
    where activity.id = target_activity_id
      and (
        activity.user_id = auth.uid()
        or exists (
          select 1
          from public.club_members viewer_membership
          join public.club_members owner_membership
            on owner_membership.club_id = viewer_membership.club_id
          where viewer_membership.user_id = auth.uid()
            and owner_membership.user_id = activity.user_id
        )
      )
  )
$$;

create or replace function public.is_activity_owner(target_activity_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.activities
    where id = target_activity_id and user_id = auth.uid()
  )
$$;

create or replace function public.activity_points(a public.activities, c public.clubs)
returns numeric
language sql
stable
as $$
  select case
    when a.excluded then 0
    when a.type = 'run' then round(coalesce(a.distance_m, 0) / 1000.0 * coalesce((c.points_config ->> 'run')::numeric, 1.0), 1)
    when a.type = 'walk' then round(coalesce(a.distance_m, 0) / 1000.0 * coalesce((c.points_config ->> 'walk')::numeric, 0.7), 1)
    when a.type = 'cycle' then round(coalesce(a.distance_m, 0) / 1000.0 * coalesce((c.points_config ->> 'cycle')::numeric, 0.3), 1)
    when a.type = 'strength' then floor(coalesce(a.moving_time_s, a.elapsed_s, 0) / 900.0 * coalesce((c.points_config ->> 'strength')::numeric, 1.0))
    else 0
  end
$$;

create or replace function public.create_club_with_admin(
  club_name text,
  club_timezone text default 'Asia/Kolkata',
  club_week_start_day smallint default 1,
  club_points_config jsonb default '{"run": 1.0, "walk": 0.7, "cycle": 0.3, "strength": 1.0}'::jsonb
)
returns public.clubs
language plpgsql
security definer
set search_path = public
as $$
declare
  new_club public.clubs;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required';
  end if;

  insert into public.clubs (name, timezone, week_start_day, points_config, created_by)
  values (club_name, club_timezone, club_week_start_day, club_points_config, auth.uid())
  returning * into new_club;

  insert into public.club_members (club_id, user_id, role)
  values (new_club.id, auth.uid(), 'admin');

  return new_club;
end;
$$;

create or replace function public.join_club_with_invite(invite_code text)
returns public.clubs
language plpgsql
security definer
set search_path = public
as $$
declare
  matching_invite public.invite_codes;
  joined_club public.clubs;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required';
  end if;

  select * into matching_invite
  from public.invite_codes
  where code = upper(btrim(invite_code))
  for update;

  if not found
    or not matching_invite.active
    or (matching_invite.expires_at is not null and matching_invite.expires_at <= now())
    or matching_invite.uses_count >= matching_invite.max_uses then
    raise exception 'Invite code is invalid, inactive, expired, or fully used';
  end if;

  select * into joined_club from public.clubs where id = matching_invite.club_id;

  if exists (
    select 1 from public.club_members
    where club_id = matching_invite.club_id and user_id = auth.uid()
  ) then
    return joined_club;
  end if;

  update public.invite_codes
  set uses_count = uses_count + 1
  where code = matching_invite.code;

  insert into public.club_members (club_id, user_id, role)
  values (matching_invite.club_id, auth.uid(), 'member');

  return joined_club;
end;
$$;

create or replace function public.notify_activity_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  owner_id uuid;
begin
  select user_id into owner_id from public.activities where id = new.activity_id;

  if owner_id <> new.user_id then
    if tg_argv[0] = 'reaction' and exists (
      select 1
      from public.notifications
      where activity_id = new.activity_id
        and from_user_id = new.user_id
        and type = 'reaction'
    ) then
      return new;
    end if;

    insert into public.notifications (user_id, type, activity_id, from_user_id)
    values (owner_id, tg_argv[0]::public.notification_type, new.activity_id, new.user_id);
  end if;

  return new;
end;
$$;

create trigger on_reaction
after insert on public.activity_reactions
for each row execute function public.notify_activity_event('reaction');

create trigger on_comment
after insert on public.activity_comments
for each row execute function public.notify_activity_event('comment');

alter table public.profiles enable row level security;
alter table public.clubs enable row level security;
alter table public.club_members enable row level security;
alter table public.invite_codes enable row level security;
alter table public.activities enable row level security;
alter table public.track_points enable row level security;
alter table public.weekly_snapshots enable row level security;
alter table public.activity_reactions enable row level security;
alter table public.activity_comments enable row level security;
alter table public.notifications enable row level security;

create policy "Profiles are visible to members sharing a club"
on public.profiles for select to authenticated
using (id = auth.uid() or exists (
  select 1
  from public.club_members viewer_membership
  join public.club_members profile_membership
    on profile_membership.club_id = viewer_membership.club_id
  where viewer_membership.user_id = auth.uid()
    and profile_membership.user_id = profiles.id
));

create policy "Users can create their own profile"
on public.profiles for insert to authenticated
with check (id = auth.uid());

create policy "Users can update their own profile"
on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid());

create policy "Members can read their clubs"
on public.clubs for select to authenticated
using (public.is_club_member(id));

create policy "Users can create clubs through the onboarding flow"
on public.clubs for insert to authenticated
with check (created_by = auth.uid());

create policy "Admins can update their clubs"
on public.clubs for update to authenticated
using (public.is_club_admin(id)) with check (public.is_club_admin(id));

create policy "Members can read their club rosters"
on public.club_members for select to authenticated
using (public.is_club_member(club_id));

create policy "Members can leave their own clubs"
on public.club_members for delete to authenticated
using (user_id = auth.uid());

create policy "Admins can remove club members"
on public.club_members for delete to authenticated
using (public.is_club_admin(club_id));

create policy "Admins can manage club invite codes"
on public.invite_codes for all to authenticated
using (public.is_club_admin(club_id))
with check (public.is_club_admin(club_id) and created_by = auth.uid());

create policy "Members can read activities from shared clubs"
on public.activities for select to authenticated
using (public.can_view_activity(id));

create policy "Users can create their own activities"
on public.activities for insert to authenticated
with check (user_id = auth.uid());

create policy "Users can update their own activities"
on public.activities for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "Users can delete their own activities"
on public.activities for delete to authenticated
using (user_id = auth.uid());

create policy "Owners can read their track points"
on public.track_points for select to authenticated
using (public.is_activity_owner(activity_id));

create policy "Owners can create their track points"
on public.track_points for insert to authenticated
with check (public.is_activity_owner(activity_id));

create policy "Owners can update their track points"
on public.track_points for update to authenticated
using (public.is_activity_owner(activity_id)) with check (public.is_activity_owner(activity_id));

create policy "Owners can delete their track points"
on public.track_points for delete to authenticated
using (public.is_activity_owner(activity_id));

create policy "Members can read weekly club snapshots"
on public.weekly_snapshots for select to authenticated
using (public.is_club_member(club_id));

create policy "Members can read reactions on visible activities"
on public.activity_reactions for select to authenticated
using (public.can_view_activity(activity_id));

create policy "Members can add their own reactions"
on public.activity_reactions for insert to authenticated
with check (user_id = auth.uid() and public.can_view_activity(activity_id));

create policy "Members can update their own reactions"
on public.activity_reactions for update to authenticated
using (user_id = auth.uid() and public.can_view_activity(activity_id))
with check (user_id = auth.uid() and public.can_view_activity(activity_id));

create policy "Members can remove their own reactions"
on public.activity_reactions for delete to authenticated
using (user_id = auth.uid());

create policy "Members can read comments on visible activities"
on public.activity_comments for select to authenticated
using (public.can_view_activity(activity_id));

create policy "Members can add their own comments"
on public.activity_comments for insert to authenticated
with check (user_id = auth.uid() and public.can_view_activity(activity_id));

create policy "Members can update their own comments"
on public.activity_comments for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "Members can remove their own comments"
on public.activity_comments for delete to authenticated
using (user_id = auth.uid());

create policy "Users can read their own notifications"
on public.notifications for select to authenticated
using (user_id = auth.uid());

create policy "Users can mark their own notifications seen"
on public.notifications for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

revoke all on public.notifications from anon, authenticated;
grant select, update (seen) on public.notifications to authenticated;

revoke all on function public.notify_activity_event() from public, anon, authenticated;
revoke all on function public.is_club_member(uuid) from public, anon;
revoke all on function public.is_club_admin(uuid) from public, anon;
revoke all on function public.can_view_activity(uuid) from public, anon;
revoke all on function public.is_activity_owner(uuid) from public, anon;
revoke all on function public.activity_points(public.activities, public.clubs) from public, anon;
revoke all on function public.create_club_with_admin(text, text, smallint, jsonb) from public, anon;
revoke all on function public.join_club_with_invite(text) from public, anon;
grant execute on function public.is_club_member(uuid) to authenticated;
grant execute on function public.is_club_admin(uuid) to authenticated;
grant execute on function public.can_view_activity(uuid) to authenticated;
grant execute on function public.is_activity_owner(uuid) to authenticated;
grant execute on function public.activity_points(public.activities, public.clubs) to authenticated;
grant execute on function public.create_club_with_admin(text, text, smallint, jsonb) to authenticated;
grant execute on function public.join_club_with_invite(text) to authenticated;