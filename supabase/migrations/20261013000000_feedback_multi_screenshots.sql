-- Upgrade feedback from single screenshot to multiple (up to 3).
-- Migrates existing data, then drops the old column.

alter table public.feedback
  add column screenshot_urls jsonb not null default '[]'::jsonb;

update public.feedback
  set screenshot_urls = jsonb_build_array(screenshot_url)
  where screenshot_url is not null;

alter table public.feedback
  drop column screenshot_url;
