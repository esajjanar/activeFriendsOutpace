drop function public.club_activity_feed(uuid, integer, integer);

create function public.club_activity_feed(target_club_id uuid, page_size integer default 20, page_offset integer default 0)
returns table (
  activity_id uuid,
  member_id uuid,
  display_name text,
  activity_type public.activity_type,
  started_at timestamptz,
  distance_m integer,
  moving_time_s integer,
  points numeric,
  source public.activity_source,
  notes text,
  review_state public.activity_review_state,
  excluded boolean,
  route_visible boolean,
  reaction_count bigint,
  comment_count bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  target_club public.clubs;
begin
  if not public.is_club_member(target_club_id) then
    raise exception 'You are not a member of this club';
  end if;

  select * into target_club from public.clubs where id = target_club_id;
  if target_club is null then
    raise exception 'Club not found';
  end if;

  return query
  select
    activity.id, activity.user_id, profile.display_name, activity.type,
    activity.started_at, activity.distance_m, activity.moving_time_s,
    public.activity_points(activity, target_club), activity.source,
    activity.notes, activity.review_state, activity.excluded,
    exists (select 1 from public.track_points point where point.activity_id = activity.id)
      and (activity.user_id = auth.uid() or owner_profile.share_routes),
    (select count(*) from public.activity_reactions reaction where reaction.activity_id = activity.id),
    (select count(*) from public.activity_comments comment where comment.activity_id = activity.id)
  from public.activities activity
  join public.club_members membership on membership.user_id = activity.user_id and membership.club_id = target_club_id
  join public.profiles profile on profile.id = activity.user_id
  join public.profiles owner_profile on owner_profile.id = activity.user_id
  order by activity.started_at desc
  limit greatest(least(page_size, 50), 1)
  offset greatest(page_offset, 0);
end;
$$;

revoke all on function public.club_activity_feed(uuid, integer, integer) from public, anon;
grant execute on function public.club_activity_feed(uuid, integer, integer) to authenticated;