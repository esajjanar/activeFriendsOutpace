-- Scale points multipliers by 10x so the UI shows whole numbers instead of decimals.
-- Old: run=1.0, walk=0.7, cycle=0.3, strength=1.0
-- New: run=10,  walk=7,   cycle=3,   strength=10

-- 1. Update the activity_points function defaults to 10x
drop function if exists public.activity_points(public.activities, public.clubs);

create function public.activity_points(a public.activities, c public.clubs)
returns numeric
language sql
stable
as $$
  select case
    when a.excluded then 0
    when a.type = 'run' then round(coalesce(a.distance_m, 0) / 1000.0 * coalesce((c.points_config ->> 'run')::numeric, 10), 0)
    when a.type = 'walk' then round(coalesce(a.distance_m, 0) / 1000.0 * coalesce((c.points_config ->> 'walk')::numeric, 7), 0)
    when a.type = 'cycle' then round(coalesce(a.distance_m, 0) / 1000.0 * coalesce((c.points_config ->> 'cycle')::numeric, 3), 0)
    when a.type = 'strength' then floor(coalesce(a.moving_time_s, a.elapsed_s, 0) / 900.0 * coalesce((c.points_config ->> 'strength')::numeric, 10))
    else 0
  end
$$;

revoke all on function public.activity_points(public.activities, public.clubs) from public, anon;
grant execute on function public.activity_points(public.activities, public.clubs) to authenticated;

-- 2. Update create_club_with_admin default config
create or replace function public.create_club_with_admin(
  club_name text,
  club_timezone text default 'Asia/Kolkata',
  club_week_start_day smallint default 1,
  club_points_config jsonb default '{"run": 10, "walk": 7, "cycle": 3, "strength": 10}'::jsonb
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

-- 3. Update existing clubs to the new 10x scale
update public.clubs
set points_config = '{"run": 10, "walk": 7, "cycle": 3, "strength": 10}'::jsonb
where points_config = '{"run": 1, "walk": 0.7, "cycle": 0.3, "strength": 1}'::jsonb
   or points_config = '{"run": 1.0, "walk": 0.7, "cycle": 0.3, "strength": 1.0}'::jsonb;
