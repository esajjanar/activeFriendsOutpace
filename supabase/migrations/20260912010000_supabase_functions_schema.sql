-- Restore the supabase_functions schema that powers database webhooks.
-- This is normally provisioned automatically by Supabase but is missing here.

create schema if not exists supabase_functions;

create table if not exists supabase_functions.migrations (
  version text primary key,
  inserted_at timestamptz not null default now()
);

create table if not exists supabase_functions.hooks (
  id bigserial primary key,
  hook_table_id integer not null,
  hook_name text not null,
  created_at timestamptz not null default now(),
  request_id bigint
);

create index if not exists supabase_functions_hooks_request_id_idx
  on supabase_functions.hooks using btree (request_id);

create index if not exists supabase_functions_hooks_h_table_id_h_name_idx
  on supabase_functions.hooks using btree (hook_table_id, hook_name);

create or replace function supabase_functions.http_request()
  returns trigger
  language plpgsql
  as $$
  declare
    request_id bigint;
    url text := tg_argv[0]::text;
    method text := tg_argv[1]::text;
    headers jsonb default '{}'::jsonb;
    params jsonb default '{}'::jsonb;
    timeout_ms integer default 5000;
  begin
    if url is null or url = 'null' then
      raise exception 'url argument is missing';
    end if;
    if method is null or method = 'null' then
      raise exception 'method argument is missing';
    end if;
    if tg_argv[2] is not null and tg_argv[2] != 'null' then
      headers = tg_argv[2]::jsonb;
    end if;
    if tg_argv[3] is not null and tg_argv[3] != 'null' then
      params = tg_argv[3]::jsonb;
    end if;
    if tg_argv[4] is not null and tg_argv[4] != 'null' then
      timeout_ms = tg_argv[4]::integer;
    end if;

    select net.http_post(
      url := url,
      body := to_jsonb(new),
      params := params,
      headers := headers,
      timeout_milliseconds := timeout_ms
    ) into request_id;

    insert into supabase_functions.hooks (hook_table_id, hook_name, request_id)
    values (tg_relid, tg_name, request_id);

    return new;
  end;
$$;

grant usage on schema supabase_functions to postgres, anon, authenticated, service_role;
grant all privileges on all tables in schema supabase_functions to postgres, service_role;
grant all privileges on all sequences in schema supabase_functions to postgres, service_role;
alter default privileges in schema supabase_functions grant all on tables to postgres, service_role;
alter default privileges in schema supabase_functions grant all on sequences to postgres, service_role;
