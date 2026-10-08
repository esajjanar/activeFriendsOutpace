-- ============================================================
-- activity_route(p_activity_id)
-- ============================================================
-- Returns an activity's GPS route as a single JSON array of
-- {lat, lon} points, DOWNSAMPLED server-side to ~800 points
-- across the full route.
--
-- Why: the feed/detail map previously read `track_points` directly
-- via the Data API, which is capped by PostgREST `max_rows` (1000).
-- Long rides (e.g. a 16km ride = ~1800 points) were truncated to
-- the first 1000, so the map showed only the first ~half of the
-- route. An RPC returns ONE row (the json array), so the row cap
-- never applies, and downsampling keeps the payload tiny while
-- preserving the full route shape.
--
-- SECURITY INVOKER (default): the SELECT below runs as the calling
-- user, so the existing track_points RLS SELECT policy still governs
-- who can see a route (owner, or opted-in club members).
-- ============================================================

CREATE OR REPLACE FUNCTION public.activity_route(p_activity_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  WITH pts AS (
    SELECT
      lat,
      lon,
      row_number() OVER (ORDER BY seq) AS rn,
      count(*)      OVER ()            AS total
    FROM public.track_points
    WHERE activity_id = p_activity_id
  ),
  step AS (
    -- Keep every k-th point so the result is ~800 points max.
    -- k = 1 when the route already has <= 800 points (full fidelity).
    SELECT GREATEST(1, ceil(MAX(total)::numeric / 800))::int AS k
    FROM pts
  )
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object('lat', pts.lat, 'lon', pts.lon)
      ORDER BY pts.rn
    ),
    '[]'::jsonb
  )
  FROM pts, step
  WHERE pts.rn = 1                 -- always keep the first point
     OR pts.rn = pts.total         -- always keep the last point
     OR (pts.rn % step.k) = 0;     -- even sample in between
$$;

GRANT EXECUTE ON FUNCTION public.activity_route(uuid) TO authenticated;
