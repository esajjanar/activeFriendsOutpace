-- Allow club admins to delete their clubs.
-- All dependent rows (club_members, invite_codes, weekly_snapshots) cascade-delete
-- via the existing ON DELETE CASCADE foreign keys.
-- Activities are club-agnostic (no club_id FK) and remain untouched.

create policy "Admins can delete their clubs"
on public.clubs for delete to authenticated
using (public.is_club_admin(id));
