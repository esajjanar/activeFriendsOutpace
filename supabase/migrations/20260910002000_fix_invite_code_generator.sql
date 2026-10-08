create or replace function public.create_invite_code(target_club_id uuid)
returns public.invite_codes
language plpgsql
security definer
set search_path = public
as $$
declare
  generated_code text;
  created_invite public.invite_codes;
  attempt integer := 0;
begin
  if not public.is_club_admin(target_club_id) then
    raise exception 'Only club admins can create invite codes';
  end if;

  loop
    generated_code := upper(substring(encode(extensions.gen_random_bytes(5), 'hex') from 1 for 8));
    begin
      insert into public.invite_codes (code, club_id, created_by, expires_at, max_uses)
      values (generated_code, target_club_id, auth.uid(), now() + interval '14 days', 10)
      returning * into created_invite;
      return created_invite;
    exception when unique_violation then
      attempt := attempt + 1;
      if attempt = 5 then
        raise;
      end if;
    end;
  end loop;
end;
$$;