alter table public.profiles
  alter column share_routes set default true;

update public.profiles
set share_routes = true
where share_routes = false;