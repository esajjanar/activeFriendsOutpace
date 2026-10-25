-- ============================================================
-- Add elapsed_s to club_activity_feed and restore it in activity_detail
--
-- Health Connect imports set moving_time_s = NULL because the health
-- Flutter package cannot read active duration. The app falls back to
-- elapsed_s for time display and pace/speed calculations.
--
-- club_activity_feed: return type changes → DROP + CREATE.
-- activity_detail:   returns jsonb → CREATE OR REPLACE is enough.
-- ============================================================

-- ── club_activity_feed ──────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.club_activity_feed(uuid, integer, integer, uuid, text);

CREATE FUNCTION public.club_activity_feed(
  target_club_id  uuid,
  page_size       integer DEFAULT 20,
  page_offset     integer DEFAULT 0,
  target_user_id  uuid    DEFAULT NULL::uuid,
  search_query    text    DEFAULT NULL::text
)
RETURNS TABLE(
  activity_id     uuid,
  member_id       uuid,
  display_name    text,
  avatar_url      text,
  activity_type   activity_type,
  started_at      timestamp with time zone,
  distance_m      integer,
  moving_time_s   integer,
  elapsed_s       integer,
  points          numeric,
  source          activity_source,
  notes           text,
  review_state    activity_review_state,
  excluded        boolean,
  route_visible   boolean,
  reaction_count  bigint,
  comment_count   bigint,
  has_reacted     boolean,
  top_reactors    json,
  top_commenters  json
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  target_club public.clubs;
BEGIN
  IF NOT public.is_club_member(target_club_id) THEN
    RAISE EXCEPTION 'You are not a member of this club';
  END IF;

  IF target_user_id IS NOT NULL AND target_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'The activity filter must match the signed-in user';
  END IF;

  SELECT * INTO target_club FROM public.clubs WHERE id = target_club_id;
  IF target_club IS NULL THEN
    RAISE EXCEPTION 'Club not found';
  END IF;

  RETURN QUERY
  SELECT
    activity.id,
    activity.user_id,
    profile.display_name,
    profile.avatar_url,
    activity.type,
    activity.started_at,
    activity.distance_m,
    activity.moving_time_s,
    activity.elapsed_s,
    public.activity_points(activity, target_club),
    activity.source,
    activity.notes,
    activity.review_state,
    activity.excluded,
    EXISTS (
      SELECT 1 FROM public.track_points point
      WHERE point.activity_id = activity.id
    ) AND (activity.user_id = auth.uid() OR owner_profile.share_routes),
    (SELECT COUNT(*) FROM public.activity_reactions reaction
      WHERE reaction.activity_id = activity.id),
    (SELECT COUNT(*) FROM public.activity_comments comment
      WHERE comment.activity_id = activity.id),
    EXISTS (
      SELECT 1 FROM public.activity_reactions reaction
      WHERE reaction.activity_id = activity.id
        AND reaction.user_id = auth.uid()
    ),
    (
      SELECT COALESCE(json_agg(r), '[]'::json)
      FROM (
        SELECT ar.user_id::text, p.display_name, p.avatar_url
        FROM public.activity_reactions ar
        JOIN public.profiles p ON p.id = ar.user_id
        WHERE ar.activity_id = activity.id
        LIMIT 4
      ) r
    ),
    (
      SELECT COALESCE(json_agg(r), '[]'::json)
      FROM (
        SELECT DISTINCT ON (c.user_id)
          c.user_id::text, p.display_name, p.avatar_url
        FROM public.activity_comments c
        JOIN public.profiles p ON p.id = c.user_id
        WHERE c.activity_id = activity.id
        ORDER BY c.user_id, c.created_at ASC
        LIMIT 4
      ) r
    )
  FROM public.activities activity
  JOIN public.club_members membership
    ON membership.user_id = activity.user_id
    AND membership.club_id = target_club_id
  JOIN public.profiles profile       ON profile.id       = activity.user_id
  JOIN public.profiles owner_profile ON owner_profile.id = activity.user_id
  WHERE (target_user_id IS NULL OR activity.user_id = auth.uid())
    AND (
      search_query IS NULL
      OR btrim(search_query) = ''
      OR profile.display_name       ILIKE '%' || search_query || '%'
      OR activity.type::text        ILIKE '%' || search_query || '%'
      OR COALESCE(activity.notes, '') ILIKE '%' || search_query || '%'
    )
  ORDER BY activity.started_at DESC, activity.id DESC
  LIMIT  GREATEST(LEAST(page_size, 50), 1)
  OFFSET GREATEST(page_offset, 0);
END;
$function$;

REVOKE ALL ON FUNCTION public.club_activity_feed(uuid, integer, integer, uuid, text)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.club_activity_feed(uuid, integer, integer, uuid, text)
  TO authenticated;

-- ── activity_detail — restore elapsed_s ─────────────────────────────

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
      'elapsed_s',    activity.elapsed_s,
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
    ), '[]'::jsonb),
    'track_summary', COALESCE((
      SELECT jsonb_build_object(
        'point_count',      COUNT(*),
        'start_lat',        (ARRAY_AGG(lat ORDER BY recorded_at ASC))[1],
        'start_lng',        (ARRAY_AGG(lng ORDER BY recorded_at ASC))[1],
        'route_visible',    activity.user_id = auth.uid() OR owner_profile.share_routes
      )
      FROM public.track_points
      WHERE track_points.activity_id = activity.id
    ), NULL)
  ) INTO activity_detail
  FROM public.activities activity
  JOIN public.profiles profile       ON profile.id       = activity.user_id
  JOIN public.profiles owner_profile ON owner_profile.id = activity.user_id
  WHERE activity.id = target_activity_id;

  IF activity_detail IS NULL THEN
    RAISE EXCEPTION 'Activity not found';
  END IF;

  RETURN activity_detail;
END;
$$;
