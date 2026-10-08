drop policy if exists "Authenticated users can upload their avatar" on storage.objects;
drop policy if exists "Authenticated users can update their avatar" on storage.objects;
drop policy if exists "Authenticated users can delete their avatar" on storage.objects;

create policy "Authenticated users can upload their avatar"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars'
  and name like (select auth.uid()::text) || '/%'
);

create policy "Authenticated users can update their avatar"
on storage.objects for update to authenticated
using (
  bucket_id = 'avatars'
  and name like (select auth.uid()::text) || '/%'
)
with check (
  bucket_id = 'avatars'
  and name like (select auth.uid()::text) || '/%'
);

create policy "Authenticated users can delete their avatar"
on storage.objects for delete to authenticated
using (
  bucket_id = 'avatars'
  and name like (select auth.uid()::text) || '/%'
);
