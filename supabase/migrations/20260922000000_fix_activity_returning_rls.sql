-- Fix: saving an activity failed with RLS error 42501 on every insert.
--
-- The app upserts into public.activities and reads the row back
-- (INSERT ... ON CONFLICT ... RETURNING). For RETURNING, PostgreSQL applies the
-- SELECT policy to the new row. That policy was `using (can_view_activity(id))`,
-- and can_view_activity() re-queries public.activities by id. The row being
-- inserted is not yet visible to that sub-query (same-statement snapshot), so the
-- function returned false and the RETURNING was rejected as an RLS violation.
--
-- Short-circuit the owner's own rows with a direct column check (evaluated on the
-- new row itself, no self-query), so RETURNING passes. This grants no visibility a
-- user did not already have: a user can always view their own activities.
alter policy "Members can read activities from shared clubs"
on public.activities
using (user_id = auth.uid() or can_view_activity(id));
