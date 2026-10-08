alter table public.profiles
add column share_routes boolean not null default false;

drop policy "Owners can read their track points" on public.track_points;

create policy "Owners or opted-in club members can read track points"
on public.track_points for select to authenticated
using (
  public.is_activity_owner(activity_id)
  or exists (
    select 1
    from public.activities activity
    join public.profiles owner_profile on owner_profile.id = activity.user_id
    join public.club_members viewer_membership on viewer_membership.user_id = auth.uid()
    join public.club_members owner_membership on owner_membership.club_id = viewer_membership.club_id
    where activity.id = track_points.activity_id
      and owner_membership.user_id = activity.user_id
      and owner_profile.share_routes = true
  )
);