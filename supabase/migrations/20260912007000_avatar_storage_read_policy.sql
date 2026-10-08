drop policy if exists "Authenticated users can read their avatar" on storage.objects;

create policy "Authenticated users can read their avatar"
on storage.objects for select to authenticated
using (
  bucket_id = 'avatars'
  and name like (select auth.uid()::text) || '/%'
);
