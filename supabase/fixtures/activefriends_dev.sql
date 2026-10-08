-- Development-only fixture data for activefriends-dev.
-- Run in the hosted Supabase SQL Editor. This script is safe to rerun.

do $$
declare
  mayya_id uuid;
  rags_id uuid;
  paro_id uuid;
  dk_id uuid;
  dotc_id uuid;
  irene_id uuid;
  lagoon_club_id uuid;
  cycle_club_id uuid;
  mayya_cycle_id uuid;
  rags_run_id uuid;
  paro_walk_id uuid;
  dk_run_id uuid;
  duplicate_group_id uuid := '11111111-1111-1111-1111-111111111111';
begin
  select id into mayya_id from auth.users where email = 'mayya.dev@activefriends.in';
  select id into rags_id from auth.users where email = 'rags.dev@activefriends.in';
  select id into paro_id from auth.users where email = 'paro.dev@activefriends.in';
  select id into dk_id from auth.users where email = 'dk.dev@activefriends.in';
  select id into dotc_id from auth.users where email = 'dotc.dev@activefriends.in';
  select id into irene_id from auth.users where email = 'irene.dev@activefriends.in';

  if mayya_id is null or rags_id is null or paro_id is null or dk_id is null or dotc_id is null or irene_id is null then
    raise exception 'Create and confirm all six @activefriends.in fixture Auth users before running this script';
  end if;

  insert into public.profiles (id, display_name)
  values
    (mayya_id, 'Mayya'),
    (rags_id, 'Rags'),
    (paro_id, 'Paro'),
    (dk_id, 'DK'),
    (dotc_id, 'Dotc'),
    (irene_id, 'Irene')
  on conflict (id) do update set display_name = excluded.display_name;

  update public.clubs set name = 'Circuit Runners' where name = 'Lagoon Runners' and created_by = mayya_id;
  update public.clubs set name = 'Circuit Cyclists' where name = 'Dawn Cyclists' and created_by = dk_id;

  select id into lagoon_club_id from public.clubs where name = 'Circuit Runners' and created_by = mayya_id;
  if lagoon_club_id is null then
    insert into public.clubs (name, timezone, week_start_day, points_config, created_by)
    values ('Circuit Runners', 'Asia/Kolkata', 1, '{"run": 1.0, "walk": 0.7, "cycle": 0.3, "strength": 1.0}'::jsonb, mayya_id)
    returning id into lagoon_club_id;
  end if;

  select id into cycle_club_id from public.clubs where name = 'Circuit Cyclists' and created_by = dk_id;
  if cycle_club_id is null then
    insert into public.clubs (name, timezone, week_start_day, points_config, created_by)
    values ('Circuit Cyclists', 'Asia/Kolkata', 1, '{"run": 0.8, "walk": 0.5, "cycle": 0.5, "strength": 1.0}'::jsonb, dk_id)
    returning id into cycle_club_id;
  end if;

  insert into public.club_members (club_id, user_id, role)
  values
    (lagoon_club_id, mayya_id, 'admin'),
    (lagoon_club_id, rags_id, 'member'),
    (lagoon_club_id, paro_id, 'member'),
    (lagoon_club_id, dk_id, 'member'),
    (lagoon_club_id, dotc_id, 'member'),
    (lagoon_club_id, irene_id, 'member'),
    (cycle_club_id, mayya_id, 'member'),
    (cycle_club_id, dk_id, 'admin'),
    (cycle_club_id, rags_id, 'member'),
    (cycle_club_id, irene_id, 'member')
  on conflict (club_id, user_id) do update set role = excluded.role;

  delete from public.activities where external_id like 'fixture-%';

  insert into public.activities (
    user_id, type, started_at, ended_at, distance_m, moving_time_s, elapsed_s,
    avg_hr, max_hr, calories, source, external_id, notes, review_state, dup_group_id, excluded, status
  )
  values
    (dk_id, 'run', '2026-09-07 01:00:00+00', '2026-09-07 01:32:00+00', 10500, 1920, 1920, 148, 171, 720, 'health_connect', 'fixture-dk-run-1', 'Easy long run before breakfast.', 'clean', null, false, 'synced'),
    (dk_id, 'strength', '2026-09-09 13:00:00+00', '2026-09-09 13:45:00+00', null, 2700, 2700, null, null, 260, 'health_connect', 'fixture-dk-strength-1', 'Full body strength.', 'clean', null, false, 'synced'),
    (rags_id, 'run', '2026-09-08 00:40:00+00', '2026-09-08 01:25:00+00', 8200, 2700, 2700, 154, 179, 610, 'health_connect', 'fixture-rags-run-1', 'Tempo effort.', 'clean', null, false, 'synced'),
    (rags_id, 'cycle', '2026-09-10 00:30:00+00', '2026-09-10 02:15:00+00', 36000, 6300, 6300, 138, 162, 840, 'health_connect', 'fixture-rags-cycle-1', 'Morning ride.', 'clean', null, false, 'synced'),
    (paro_id, 'walk', '2026-09-07 12:00:00+00', '2026-09-07 12:48:00+00', 5200, 2880, 2880, 112, 126, 270, 'healthkit', 'fixture-paro-walk-1', 'Evening walk.', 'clean', null, false, 'synced'),
    (paro_id, 'strength', '2026-09-10 12:30:00+00', '2026-09-10 13:00:00+00', null, 1800, 1800, null, null, 180, 'manual', 'fixture-paro-strength-1', 'Mobility and core.', 'clean', null, false, 'synced'),
    (mayya_id, 'cycle', '2026-09-07 00:15:00+00', '2026-09-07 03:00:00+00', 62000, 9900, 9900, 142, 169, 1420, 'health_connect', 'fixture-mayya-cycle-1', 'Sunday endurance ride.', 'clean', null, false, 'synced'),
    (dotc_id, 'run', '2026-09-09 00:45:00+00', '2026-09-09 01:15:00+00', 5000, 1800, 1800, 161, 183, 430, 'phone_gps', 'fixture-dotc-run-1', 'Park loop.', 'clean', null, false, 'synced'),
    (irene_id, 'other', '2026-09-08 12:00:00+00', '2026-09-08 13:00:00+00', null, 3600, 3600, null, null, 310, 'healthkit', 'fixture-irene-yoga-1', 'Yoga recovery.', 'clean', null, false, 'synced'),
    (irene_id, 'run', '2026-09-09 01:00:00+00', '2026-09-09 01:28:00+00', 4700, 1680, 1680, 156, 177, 390, 'health_connect', 'fixture-irene-run-1', 'Short run.', 'needs_review', duplicate_group_id, false, 'synced'),
    (irene_id, 'run', '2026-09-09 01:01:00+00', '2026-09-09 01:29:00+00', 4750, 1680, 1680, null, null, 380, 'phone_gps', 'fixture-irene-run-duplicate-1', 'Duplicate source record.', 'needs_review', duplicate_group_id, true, 'synced')
  ;

  select id into mayya_cycle_id from public.activities where user_id = mayya_id and external_id = 'fixture-mayya-cycle-1';
  select id into rags_run_id from public.activities where user_id = rags_id and external_id = 'fixture-rags-run-1';
  select id into paro_walk_id from public.activities where user_id = paro_id and external_id = 'fixture-paro-walk-1';
  select id into dk_run_id from public.activities where user_id = dk_id and external_id = 'fixture-dk-run-1';

  insert into public.activity_reactions (activity_id, user_id, reaction)
  values
    (mayya_cycle_id, rags_id, 'fire'),
    (mayya_cycle_id, paro_id, 'clap'),
    (rags_run_id, mayya_id, 'strong'),
    (dk_run_id, irene_id, 'clap')
  on conflict (activity_id, user_id) do update set reaction = excluded.reaction;

  insert into public.activity_comments (activity_id, user_id, body)
  select mayya_cycle_id, rags_id, 'Strong start to the week.'
  where not exists (select 1 from public.activity_comments where activity_id = mayya_cycle_id and user_id = rags_id and body = 'Strong start to the week.');
  insert into public.activity_comments (activity_id, user_id, body)
  select dk_run_id, mayya_id, 'Strong start to the week.'
  where not exists (select 1 from public.activity_comments where activity_id = dk_run_id and user_id = mayya_id and body = 'Strong start to the week.');

  insert into public.weekly_snapshots (club_id, week_start, member_stats)
  values (
    lagoon_club_id,
    '2026-08-31',
    '[{"rank":1,"name":"Rags","points":42.6},{"rank":2,"name":"Mayya","points":36.0},{"rank":3,"name":"DK","points":31.4}]'::jsonb
  )
  on conflict (club_id, week_start) do update set member_stats = excluded.member_stats;
end;
$$;