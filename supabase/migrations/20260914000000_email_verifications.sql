create table public.email_verifications (
  email      text        primary key,
  code       text        not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

-- No RLS, no public/authenticated grant.
-- Accessed only via service_role key from the verify-email Edge Function.
