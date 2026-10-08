-- ============================================================
-- activity_detail v2
--
-- Adds profile info to reactions and comments:
--   reactions[].display_name  — reactor's display name
--   reactions[].avatar_url    — reactor's avatar URL
--   comments[].avatar_url     — commenter's avatar URL (display_name already existed)
--
-- Returns jsonb so CREATE OR REPLACE works without DROP.
-- ============================================================

CREATE OR REPLACE FUNCTION public.activity_detail(
  target_activity_id uuid,
  target_club_id     uuid
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_club     public.clubs;
  activity_detail jsonb;
BEGIN
  IF NOT public.is_club_member(target_club_id)
     OR NOT public.can_view_activity(target_activity_id) THEN
    RAISE EXCEPTION 'You cannot view this activity';
  END IF;

  SELECT * INTO target_club FROM public.clubs WHERE id = target_club_id;
  IF target_club IS NULL THEN
    RAISE EXCEPTION 'Club not found';
  END IF;

  SELECT jsonb_build_object(
    'activity', jsonb_build_object(
      'id',           activity.id,
      'member_id',    activity.user_id,
      'display_name', profile.display_name,
      'type',         activity.type,
      'started_at',   activity.started_at,
      'ended_at',     activity.ended_at,
      'distance_m',   activity.distance_m,
      'moving_time_s',activity.moving_time_s,
      'avg_hr',       activity.avg_hr,
      'max_hr',       activity.max_hr,
      'calories',     activity.calories,
      'source',       activity.source,
      'notes',        activity.notes,
      'excluded',     activity.excluded,
      'points',       public.activity_points(activity, target_club)
    ),
    'reactions', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'user_id',      reaction.user_id,
        'reaction',     reaction.reaction,
        'display_name', reactor.display_name,
        'avatar_url',   reactor.avatar_url
      ) ORDER BY reaction.created_at)
      FROM public.activity_reactions reaction
      JOIN public.profiles reactor ON reactor.id = reaction.user_id
      WHERE reaction.activity_id = activity.id
    ), '[]'::jsonb),
    'comments', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id',           comment.id,
        'user_id',      comment.user_id,
        'display_name', commenter.display_name,
        'avatar_url',   commenter.avatar_url,
        'body',         comment.body,
        'created_at',   comment.created_at
      ) ORDER BY comment.created_at)
      FROM public.activity_comments comment
      JOIN public.profiles commenter ON commenter.id = comment.user_id
      WHERE comment.activity_id = activity.id
    ), '[]'::jsonb)
  ) INTO activity_detail
  FROM public.activities activity
  JOIN public.profiles profile ON profile.id = activity.user_id
  WHERE activity.id = target_activity_id;

  IF activity_detail IS NULL THEN
    RAISE EXCEPTION 'Activity not found';
  END IF;

  RETURN activity_detail;
END;
$$;
