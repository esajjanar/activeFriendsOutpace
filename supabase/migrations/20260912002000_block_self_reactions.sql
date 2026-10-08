drop policy "Members can add their own reactions" on public.activity_reactions;
drop policy "Members can update their own reactions" on public.activity_reactions;

create policy "Members can add reactions to others activities"
on public.activity_reactions for insert to authenticated
with check (
  user_id = auth.uid()
  and public.can_view_activity(activity_id)
  and not exists (
    select 1 from public.activities activity
    where activity.id = activity_id and activity.user_id = auth.uid()
  )
);

create policy "Members can update reactions on others activities"
on public.activity_reactions for update to authenticated
using (
  user_id = auth.uid()
  and public.can_view_activity(activity_id)
  and not exists (
    select 1 from public.activities activity
    where activity.id = activity_id and activity.user_id = auth.uid()
  )
)
with check (
  user_id = auth.uid()
  and public.can_view_activity(activity_id)
  and not exists (
    select 1 from public.activities activity
    where activity.id = activity_id and activity.user_id = auth.uid()
  )
);