create policy "Club admins can delete member activities"
on public.activities for delete to authenticated
using (
  exists (
    select 1
    from public.club_members admin_membership
    join public.club_members owner_membership
      on owner_membership.club_id = admin_membership.club_id
    where admin_membership.user_id = auth.uid()
      and admin_membership.role = 'admin'
      and owner_membership.user_id = activities.user_id
  )
);