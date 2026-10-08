create or replace function public.activity_detail(target_activity_id uuid, target_club_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  target_club public.clubs;
  activity_detail jsonb;
begin
  if not public.is_club_member(target_club_id) or not public.can_view_activity(target_activity_id) then
    raise exception 'You cannot view this activity';
  end if;

  select * into target_club from public.clubs where id = target_club_id;
  if target_club is null then
    raise exception 'Club not found';
  end if;

  select jsonb_build_object(
    'activity', jsonb_build_object(
      'id', activity.id,
      'member_id', activity.user_id,
      'display_name', profile.display_name,
      'type', activity.type,
      'started_at', activity.started_at,
      'ended_at', activity.ended_at,
      'distance_m', activity.distance_m,
      'moving_time_s', activity.moving_time_s,
      'elapsed_s', activity.elapsed_s,
      'avg_hr', activity.avg_hr,
      'max_hr', activity.max_hr,
      'calories', activity.calories,
      'source', activity.source,
      'notes', activity.notes,
      'track_summary', activity.track_summary,
      'excluded', activity.excluded,
      'points', public.activity_points(activity, target_club)
    ),
    'reactions', coalesce((
      select jsonb_agg(jsonb_build_object('user_id', reaction.user_id, 'reaction', reaction.reaction) order by reaction.created_at)
      from public.activity_reactions reaction where reaction.activity_id = activity.id
    ), '[]'::jsonb),
    'comments', coalesce((
      select jsonb_agg(jsonb_build_object('id', comment.id, 'user_id', comment.user_id, 'display_name', commenter.display_name, 'body', comment.body, 'created_at', comment.created_at) order by comment.created_at)
      from public.activity_comments comment
      join public.profiles commenter on commenter.id = comment.user_id
      where comment.activity_id = activity.id
    ), '[]'::jsonb)
  ) into activity_detail
  from public.activities activity
  join public.profiles profile on profile.id = activity.user_id
  where activity.id = target_activity_id;

  if activity_detail is null then
    raise exception 'Activity not found';
  end if;
  return activity_detail;
end;
$$;

revoke all on function public.activity_detail(uuid, uuid) from public, anon;
grant execute on function public.activity_detail(uuid, uuid) to authenticated;