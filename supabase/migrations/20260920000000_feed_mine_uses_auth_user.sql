drop function if exists public.club_activity_feed(uuid, integer, integer, uuid, text);

create function public.club_activity_feed(
  target_club_id uuid,
  page_size integer default 20,
  page_offset integer default 0,
  target_user_id uuid default null,
  search_query text default null
)
returns table (
  activity_id uuid,
  member_id uuid,
  display_name text,
  avatar_url text,
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

  if target_user_id is not null and target_user_id <> auth.uid() then
    raise exception 'The activity filter must match the signed-in user';
  end if;

  select * into target_club from public.clubs where id = target_club_id;
  if target_club is null then
    raise exception 'Club not found';
  end if;

  return query
  select
    activity.id,
    activity.user_id,
    profile.display_name,
    profile.avatar_url,
    activity.type,
    activity.started_at,
    activity.distance_m,
    activity.moving_time_s,
    public.activity_points(activity, target_club),
    activity.source,
    activity.notes,
    activity.review_state,
    activity.excluded,
    exists (
      select 1 from public.track_points point
      where point.activity_id = activity.id
    ) and (activity.user_id = auth.uid() or owner_profile.share_routes),
    (select count(*) from public.activity_reactions reaction
      where reaction.activity_id = activity.id),
    (select count(*) from public.activity_comments comment
      where comment.activity_id = activity.id)
  from public.activities activity
  join public.club_members membership
    on membership.user_id = activity.user_id
    and membership.club_id = target_club_id
  join public.profiles profile on profile.id = activity.user_id
  join public.profiles owner_profile on owner_profile.id = activity.user_id
  where (target_user_id is null or activity.user_id = auth.uid())
    and (
      search_query is null
      or btrim(search_query) = ''
      or profile.display_name ilike '%' || search_query || '%'
      or activity.type::text ilike '%' || search_query || '%'
      or coalesce(activity.notes, '') ilike '%' || search_query || '%'
    )
  order by activity.started_at desc, activity.id desc
  limit greatest(least(page_size, 50), 1)
  offset greatest(page_offset, 0);
end;
$$;

revoke all on function public.club_activity_feed(uuid, integer, integer, uuid, text)
  from public, anon;
grant execute on function public.club_activity_feed(uuid, integer, integer, uuid, text)
  to authenticated;