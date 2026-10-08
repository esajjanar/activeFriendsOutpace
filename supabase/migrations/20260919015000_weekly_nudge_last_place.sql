-- Returns the last-placed member on the weekly leaderboard across all clubs.
-- Called by the daily nudge edge function via service role (no auth check needed).
create or replace function public.weekly_nudge_last_place()
returns table(display_name text, rank int, total_members int)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  with member_points as (
    select
      cm.user_id,
      p.display_name,
      coalesce(sum(public.activity_points(a, c)), 0) as total_points
    from public.club_members cm
    join public.profiles p on p.id = cm.user_id
    join public.clubs c on c.id = cm.club_id
    left join public.activities a
      on a.user_id = cm.user_id
      and not coalesce(a.excluded, false)
      and (a.started_at at time zone c.timezone)::date
          >= date_trunc('week', now() at time zone c.timezone)::date
    group by cm.user_id, p.display_name
  ),
  ranked as (
    select
      display_name,
      row_number() over (order by total_points asc, display_name asc)::int as rnk,
      count(*) over ()::int as total
    from member_points
  )
  select display_name, rnk, total
  from ranked
  order by rnk desc
  limit 1;
end;
$$;

grant execute on function public.weekly_nudge_last_place() to service_role;
