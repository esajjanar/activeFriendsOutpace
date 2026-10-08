-- ============================================================
-- club_activity_feed v3
--
-- Adds three columns to the feed RPC:
--   has_reacted    boolean  — did the calling user react to this activity?
--   top_reactors   json     — up to 4 reactors with display_name + avatar_url
--   top_commenters json     — up to 4 unique commenters with display_name + avatar_url
--
-- Replaces the v1 function (original) and v2 (has_reacted + top_reactors only).
-- Return type changes require DROP + CREATE.
-- ============================================================

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
    -- Did the calling user already react to this activity?
    EXISTS (
      SELECT 1 FROM public.activity_reactions reaction
      WHERE reaction.activity_id = activity.id
        AND reaction.user_id = auth.uid()
    ),
    -- Up to 4 reactors with profile info for stacked avatar display
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
    -- Up to 4 unique commenters (deduplicated) for stacked avatar display
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
