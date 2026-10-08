create or replace function public.weekly_leaderboard(target_club_id uuid)
returns table (
  member_id uuid,
  display_name text,
  points numeric,
  distance_m bigint,
  moving_time_s bigint,
  activity_types public.activity_type[]
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  target_club public.clubs;
  week_start date;
begin
  if not public.is_club_member(target_club_id) then
    raise exception 'You are not a member of this club';
  end if;

  select * into target_club from public.clubs where id = target_club_id;
  if target_club is null then
    raise exception 'Club not found';
  end if;

  week_start := date_trunc('week', now() at time zone target_club.timezone)::date;

  return query
  with member_activities as (
    select
      activity.user_id,
      public.activity_points(activity, target_club) as activity_points,
      activity.distance_m,
      activity.moving_time_s,
      activity.type
    from public.activities activity
    join public.club_members membership
      on membership.user_id = activity.user_id
      and membership.club_id = target_club_id
    where (activity.started_at at time zone target_club.timezone)::date >= week_start
      and (activity.started_at at time zone target_club.timezone)::date < week_start + 7
  )
  select
    membership.user_id,
    profile.display_name,
    coalesce(sum(member_activities.activity_points), 0) as points,
    coalesce(sum(member_activities.distance_m), 0)::bigint as distance_m,
    coalesce(sum(member_activities.moving_time_s), 0)::bigint as moving_time_s,
    coalesce(array_agg(distinct member_activities.type) filter (where member_activities.type is not null), '{}')::public.activity_type[] as activity_types
  from public.club_members membership
  join public.profiles profile on profile.id = membership.user_id
  left join member_activities on member_activities.user_id = membership.user_id
  where membership.club_id = target_club_id
  group by membership.user_id, profile.display_name
  order by points desc, distance_m desc, profile.display_name asc;
end;
$$;

revoke all on function public.weekly_leaderboard(uuid) from public, anon;
grant execute on function public.weekly_leaderboard(uuid) to authenticated;