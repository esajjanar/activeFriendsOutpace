insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

create policy "Authenticated users can upload their avatar"
on storage.objects for insert to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Authenticated users can update their avatar"
on storage.objects for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Authenticated users can delete their avatar"
on storage.objects for delete to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);