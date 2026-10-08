# Gemini Notifications — Diagnosis & Resume Notes

**Status:** 🟡 Fixes written, deployed & verified-in-source; **final confirmation blocked by a warm-instance lag.** One cold invocation should confirm `source: gemini`.
**Last updated:** 2026-10-04 (~evening IST)
**Scope:** Creative push notifications (activity + daily nudge) were always `fallback`, never Gemini. All work here is **backend edge functions — no app build needed.**

---

## TL;DR for tomorrow
Everything is fixed and deployed. The only reason you still saw `fallback` tonight is a **stale warm isolate** on Supabase serving the OLD function code during continuous club traffic. After the overnight quiet, the next activity (or the 7pm nudge) should run the new code and come up `source: gemini`.

**First thing tomorrow — one query:**
```bash
cd supabase && supabase db query --linked \
 "select to_char(created_at at time zone 'Asia/Kolkata','MM-DD HH24:MI') ist, source, gemini_error, message \
  from public.activity_notifications_log order by created_at desc limit 10;" --output-format json
```
- `source=gemini`, `gemini_error=null` → **DONE, working.** Update memory, close this out.
- `source=fallback`, `gemini_error` **populated** → v7 is serving; the error names the exact remaining cause (e.g. `HTTP 403` = the Supabase `GEMINI_API_KEY` secret is a stale/restricted key → re-set it).
- `source=fallback`, `gemini_error=null` → warm isolate STILL serving old code → force a republish (redeploy `send-activity-notification`, then trigger after a brief gap).

---

## Root causes (two, both confirmed)
1. **Dead model.** Function hardcoded `gemini-2.0-flash`, which Google retired → every call 404'd → always fell back. (NOT billing/free-tier; 404≠quota.) Fixed: model now from `GEMINI_MODEL` secret = `gemini-flash-latest` (resolves to **gemini-3.8-flash**; alias won't 404 on future retirements).
2. **Thinking-default.** gemini-3.8-flash enables "thinking" by default; with the old small token cap + structured JSON, thinking ate the budget → empty/truncated output → `parseCopy` rejected → fallback. **Confirmed by a direct curl**: same request with `thinkingConfig:{thinkingBudget:0}` + `maxOutputTokens:800` returns clean JSON (`finishReason: STOP`). Fixed in code.

Also fixed: fallbacks were magnitude-blind ("0.2km journey") → now tiered + dynamic titles; budget was burned on failures → now claim/rollback via `decrement_llm_usage`.

## What's deployed (verified by `supabase functions download`)
- **send-activity-notification v7**: `gemini-flash-latest`, structured `{title,body}`, `thinkingBudget:0`, `maxOutputTokens:800`, magnitude-aware fallbacks, dynamic FCM title, budget claim/release, and `geminiError` captured in BOTH the function response and the `activity_notifications_log.gemini_error` column.
- **send-daily-nudge v12**: Gemini group-shaming titles (same thinking fix), random fallback (no more day-of-year repeat). First fresh fire = **tomorrow 7pm IST**.
- **Migrations applied:** `20261004000000_llm_usage_decrement`, `20261004002000_import_diagnostics` (import, separate), `20261004003000_notif_gemini_error_and_timeout` (adds `gemini_error` column + bumps the trigger's pg_net timeout 5s→15s).
- **config.toml:** `[functions.send-activity-notification] verify_jwt = false` guard.
- **Secrets:** `GEMINI_MODEL=gemini-flash-latest`, `LLM_DAILY_BUDGET=500`; user re-set `GEMINI_API_KEY` to the key proven working in the curl.

## Evidence it's actually working at the API layer
Gemini dashboard (1-day) at test time: **Gemini 3.8 Flash**, ~28 requests, ~6K in / ~2K out tokens, **~100% success**. So key + model + request are good; the only gap is the warm isolate serving old code that mishandles the thinking response.

## The warm-instance lag (why tonight still showed fallback)
- `functions list` → v7 deployed 19:33:47. Downloaded deployed source → it HAS all fixes.
- But notification responses at 19:37/19:40 had **no `geminiError` field** → only the OLD code omits it → an old isolate was still answering ~7 min+ post-deploy (continuous club traffic kept it warm; Supabase didn't recycle it).
- Resolution: idle → recycle → next request = v7. The overnight gap should do it.

## Gotchas / useful commands
- **Throttle:** trigger `trigger_activity_notification` = max **3 notifications/actor/day** + **5-min debounce**. To re-test as "Vikas DK" when capped, delete today's rows:
  `delete from public.activity_notifications_log where actor_user_id=(select id from public.profiles where display_name='Vikas DK') and created_at >= (current_date::timestamp at time zone 'Asia/Kolkata');`
- **Deploy:** `supabase functions deploy send-activity-notification --no-verify-jwt --project-ref eswypmvrdgilkljytrxq` (the "Docker is not running" warning is harmless — deploys land; verified via `functions download`).
- **Daily nudge check (after 7pm):** read `net._http_response` latest body for the nudge response (`geminiTitles>0` or a `geminiError`), or just the on-screen... it's push-only, so check `net._http_response`.
- **Dashboard timezone is UTC-8**; IST = UTC-8 +13:30.
- `supabase db query --linked "<sql>"` runs remote SQL via keychain auth (no token file). It runs as admin (bypasses RLS) and does NOT hit PostgREST `max_rows`.

## Not Gemini, but related (separate threads, see other docs)
- iOS push (no tokens) → `issues/ios-push-notifications.md`.
- Health Connect import (0 activities, missing sub-read perms) → fixed in v3 app build.
