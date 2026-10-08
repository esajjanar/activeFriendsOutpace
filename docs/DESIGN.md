# Outpace — Plan & Design Document

**Version:** 2.0 — Oct 2026
**Status:** Implemented (open-source release)
**Companion docs:** [user-flows.md](user-flows.md) (F1–F9), [sequence-diagrams.md](sequence-diagrams.md)

---

## 1. Vision

A minimal, invite-only activity app for friends clubs, replacing a
Strava club + manual WhatsApp leaderboard. Two moments matter:

1. **Zero-effort tracking** — members keep using their watches (Garmin, Fitbit,
   Samsung, Apple Watch, Polar, Coros, etc.); the app imports activities
   automatically. Phone GPS tracking is the fallback, not the requirement.
2. **The weekly ritual** — a leaderboard card that lands in WhatsApp every week.

No algorithmic feed, no segments, no follower graphs — a simple club-wide
activity feed with reactions, comments, and push notifications is the full
social surface. Import, compete, share, encourage.

**Core principle: the app is an aggregator, not a tracker.** Members' watches are
the source of truth; the app collects, scores, ranks, and shares.

---

## 2. Scope

### Implemented

- **Import activities from wearables via Health Connect (Android) / HealthKit
  (iOS)** — the primary capture path. Garmin, Fitbit (Google Health), Samsung
  Health, Polar, Coros, etc. all write to Health Connect on Android; Apple
  Watch and most fitness apps write to HealthKit on iOS.
- Phone GPS recording for run / walk / cycle (fallback for watch-less members);
  manual log for strength (duration, no GPS)
- Activities: **Run, Walk, Cycle, Strength Training** (extensible enum),
  per-type metric capture including watch-provided heart rate and calories
- Weekly leaderboard with a fair cross-activity points system (10x whole-number
  scaling — see section 6)
- Weekly summary card generator with WhatsApp share sheet (image)
- **Activity reactions + comments** (club members only) with in-app unread
  indicator and live updates via Supabase Realtime while foregrounded
- **Push notifications** via Firebase Cloud Messaging (Android + iOS) — social
  notifications (reactions/comments), new activity alerts with AI-generated copy
  (Gemini Flash), daily nudges, and weekly leaderboard reminders
- Club management: admin invites via code, member list
- Auth: email + password with custom OTP email verification (Brevo), Supabase Auth
- Offline-first: local SQLite (Drift), connectivity-aware UI with graceful
  offline degradation
- **Route sharing** with club members: opt-out by default (routes are shared
  unless the member disables it in their profile)
- **Paginated and searchable activity feed** with server-side filtering
- **Account deletion** — full GDPR-style cascade delete via edge function
- Multi-club support: club-agnostic activities with per-club scoring lenses;
  single-active-club UI with switcher

### Out of scope (future)

- Direct vendor cloud APIs (Garmin Activity API, Fitbit/Google Health API) —
  approval-gated; Health Connect/HealthKit need no approvals
- Live tracking, segments, route planning, live sensor streams / HR-zone
  analytics, weather, gear
- Direct WhatsApp API integration (uses OS share sheet; WhatsApp Business API
  automated posting is a future candidate)
- Treadmill/manual GPS-type activities (model allows it; UI deferred)
- Public discovery — invite-only via code
- WorkManager background sync on Android (sync runs on app open)

---

## 3. User Journeys

### J1 — Track an activity (GPS)
Open app, tap Start, choose type (sticky last choice), phone in pocket, screen
locks. Foreground service keeps recording with auto-pause. Tap Finish for a
summary screen (distance, moving time, avg pace/speed, map trace). Save syncs
in background. Two taps + lock screen controls.

**Edge cases:** incoming call mid-activity, GPS lost mid-activity (show banner,
keep timer, reconnect), accidental app kill (restore recording state on relaunch),
low battery warning.

### J2 — Check standings mid-week
Open app — leaderboard is the home screen: this week, rank, name, points, primary
metric. Pull-to-refresh. Weekly period: Monday 00:00 to Sunday 23:59 in the
club timezone (configurable per club in club settings).

### J3 — The Sunday share
Any member taps "Share" on the leaderboard. App renders a branded card (rank,
name, points, distance/time). OS share sheet to WhatsApp. Also a plain-text
fallback (copy). Card generated client-side so it works offline.

### J4 — Invite a friend
Admin (club creator) taps Invite, generates invite code / deep link. Friend
installs app from store, signs up, enters code, joins club.

**Multi-club:** one account can join multiple clubs. An activity is never
"posted" anywhere — it automatically appears in every club the user belongs
to, scored by each club's own points config. Joining a second club reuses the
same invite-code flow.

### J5 — Watch user (the default path)
Member runs with their Garmin/Fitbit/Samsung watch as always. Vendor app syncs
the session to Health Connect / Apple Health. Member opens the app. App pulls
new sessions, de-duplicates via stored external record IDs, maps activity type;
leaderboard points are computed per club at query time using that club's
points config. **Zero change to anyone's routine.**

Onboarding: "Connect your watch" screen with per-brand instructions
(Garmin Connect toggle, Fitbit toggle, etc.) and a one-time historical backfill
(typically 30 days available).

### J6 — Browse and react (club activity feed)
Open app, Activity Feed tab. Chronological list of all club members'
activities (newest first: avatar, name, type, distance/time, points,
comment/reaction counts). Tap row for activity detail (metrics, reaction bar,
comments). React (single tap, emoji picker) or comment. Owner receives a push
notification with AI-generated creative copy. Paginated (20 items per page)
with search on activity notes.

### J7 — Log strength training
Open app, Log, Strength, duration input + optional description, Save.
Counts toward weekly points via a time-based conversion.

### Device support matrix

The app reads only from Health Connect / HealthKit and contains **zero
per-device code**. "Supporting a device" = an onboarding guide entry. Any
future watch that writes to the health hub works automatically.

| Device | Phone | Path | Notes |
|--------|-------|------|-------|
| Garmin Forerunner / Venu / etc. | Android | Garmin Connect -> Health Connect -> direct | Enable Health Connect in Garmin Connect settings |
| Garmin | iOS | Garmin Connect -> Apple Health -> direct | Workouts sync natively |
| Apple Watch | iOS | Workout app -> HealthKit -> direct | Fully native |
| Samsung Galaxy Watch | Android | Samsung Health -> Health Connect -> direct | Launch partner; smooth |
| Fitbit / Google Health | Android | Google Health -> Health Connect -> direct | First-party HC integration |
| Amazfit (Zepp) | Android | Zepp -> Health Connect -> direct (or Health Sync bridge) | Zepp HC write can be flaky on some models; Health Sync fallback |
| Amazfit (Zepp) | iOS | Zepp -> Apple Health -> direct | Reliable |
| Huawei watches | Android | Huawei Health -> Health Sync bridge -> Health Connect | Huawei Health does not write to HC natively |
| Strava-only members | any | Use phone GPS tracking, or Strava -> Health Connect | Source-agnostic import |

**De-duplication:** each imported activity stores the source record ID
(`external_id` unique per user). Cross-source overlaps (phone GPS + watch for
the same session) are detected by time-window overlap (80% of shorter duration)
and flagged for the user to resolve.

**Known limitation:** imported activities carry distance/time/pace/HR/calories
but typically no GPS route map (Garmin does not write routes to Health Connect).
Phone-tracked activities keep their map trace.

---

## 4. Key Decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| D1 | Mobile stack | **Flutter** | Single codebase for Android+iOS; mature GPS/background plugins |
| D2 | Backend | **Supabase** | Postgres + Auth + RLS + Realtime + Edge Functions; no server ops |
| D3 | Metrics model | **Flexible per-activity-type** | Run/walk/cycle = distance + time; strength = time only |
| D4 | Leaderboard | **Points system (10x whole numbers)** | Fair cross-activity competition; whole numbers display better |
| D5 | Distribution | **Public stores** | Play Store + App Store |
| D6 | Offline-first | **SQLite (Drift) + connectivity-aware UI** | Reliability over connectivity; graceful degradation |
| D7 | Tracking | **geolocator plugin + foreground service** | Well-tested native layer |
| D8 | Share target | **OS share sheet** | No API dependency |
| D9 | Watch data | **Health Connect + HealthKit** | No vendor API approvals; all major watch brands supported |
| D10 | Build order | **Import + leaderboard first, GPS later** | Fastest path to weekly WhatsApp value |
| D11 | Vendor cloud APIs | **Hub-only** | Business-gated; route maps are the only loss |
| D12 | Multi-club | **Club-agnostic activities + per-club scoring** | One activity appears in every member club |
| D13 | Push notifications | **FCM + Supabase Edge Functions** | Social notifications, activity alerts, daily nudges, weekly reminders |
| D14 | Notification copy | **Gemini Flash with budget + fallback** | AI-generated creative copy; graceful degradation to templates |
| D15 | Email verification | **Custom OTP via Brevo** | Control over the verification UX; not dependent on Supabase email |
| D16 | Route sharing | **Opt-out (shared by default)** | Social value of route maps outweighs privacy concern in a friends club |
| D17 | Account deletion | **Full cascade via edge function** | App Store compliance (Apple guideline 5.1.1) |

---

## 5. Architecture

```
+--------------------------------------------------------------------+
|  Flutter App (app/)                                                |
|  +----------+  +-----------+  +----------------------------------+ |
|  | features |  |   core/   |  |          data/                   | |
|  | auth     |  |   theme   |  |   local/ (Drift/SQLite)          | |
|  | feed     |  |   config  |  |   services/ (active club store,  | |
|  | tracking |  |   widgets |  |     last activity type store)    | |
|  | clubs    |  |   connect |  +----------------+-----------------+ |
|  | leader.. |  +-----------+                   |                   |
|  | profile  |                                  |                   |
|  | import   |                                  |                   |
|  | notif..  |                                  |                   |
|  | onboard  |                                  |                   |
|  | home     |                                  |                   |
|  | bootstrap|                                  |                   |
|  +----------+                                  |                   |
+--------------------------------------------+---+-------------------+
                                             | HTTPS (PostgREST / Realtime)
+--------------------------------------------+------------------------+
|  Supabase (supabase/)                      |                        |
|  +----------------+  +--------------------+v----------------------+ |
|  | Postgres       |  | Edge Functions                             | |
|  |  + Auth        |  |  send-push (social: reactions/comments)    | |
|  |  + Realtime    |  |  send-activity-notification (Gemini Flash) | |
|  |  + Storage     |  |  send-daily-nudge (Gemini Flash)           | |
|  |  + pg_cron     |  |  send-weekly-reminder                     | |
|  +----------------+  |  verify-email (Brevo OTP)                  | |
|                      |  delete-account                            | |
|                      +--------------------------------------------+ |
+---------------------------------------------------------------------+
```

### App module layout (Flutter)

```
lib/
  main.dart                          # Entry point, Firebase + Supabase init
  firebase_options.dart              # Generated per-contributor (gitignored)
  core/
    app.dart                         # Root MaterialApp widget
    config/supabase_config.dart      # Compile-time env var reader
    data/connectivity_service.dart   # Online/offline stream
    presentation/                    # Shared widgets (ConnectionAwareBuilder, etc.)
    theme/                           # AppTheme (light + dark), AppColors
  data/
    local/app_database.dart          # Drift schema (activities, track points, etc.)
    services/                        # ActiveClubStore, LastActivityTypeStore
  features/
    auth/          {data/, presentation/}   # Sign up, sign in, password reset
    bootstrap/     {presentation/}          # App init / unconfigured-state screen
    clubs/         {data/, presentation/}   # Club management, invite codes
    feed/          {data/, presentation/}   # Club-wide activity feed, reactions, comments
    home/          {presentation/}          # Bottom navigation shell
    import/        {data/, presentation/}   # Health Connect / HealthKit import
    leaderboard/   {data/, presentation/}   # Weekly leaderboard, share card
    notifications/ {data/, presentation/}   # Push notification service, in-app badge
    onboarding/    {presentation/}          # Watch connection guides
    profile/       {data/, presentation/}   # User profile, avatar, settings
    tracking/      {data/, presentation/}   # GPS tracker, recording UI, summary
```

**State management:** the codebase uses `StatefulWidget` + `setState` throughout.
There is no Provider, Riverpod, or Bloc layer. This is intentional for simplicity
at the current feature count.

---

## 6. Points System

Each activity contributes points; the leaderboard ranks by weekly points, with
distance/time as secondary columns. Points use **10x whole-number scaling** so
the UI never shows decimals.

| Activity | Formula | Example |
|----------|---------|---------|
| Run      | km x 10 | 5 km run = 50 pts |
| Walk     | km x 7  | 5 km walk = 35 pts |
| Cycle    | km x 3  | 20 km ride = 60 pts |
| Strength | 10 pts per 15 min | 45 min session = 30 pts |

Points are **computed at query/snapshot time per club** via the
`activity_points(activity, club)` SQL function using that club's
`points_config` JSONB — the same run can score differently in different clubs,
and retuning weights never requires an app release or data migration.

```sql
create or replace function activity_points(a activities, c clubs)
returns numeric language sql as $$
  select case
    when a.excluded then 0
    when a.type = 'run'      then round(coalesce(a.distance_m,0)/1000.0
                                  * coalesce((c.points_config->>'run')::numeric, 10), 0)
    when a.type = 'walk'     then round(coalesce(a.distance_m,0)/1000.0
                                  * coalesce((c.points_config->>'walk')::numeric, 7), 0)
    when a.type = 'cycle'    then round(coalesce(a.distance_m,0)/1000.0
                                  * coalesce((c.points_config->>'cycle')::numeric, 3), 0)
    when a.type = 'strength' then floor(coalesce(a.moving_time_s, a.elapsed_s, 0)/900.0
                                  * coalesce((c.points_config->>'strength')::numeric, 10))
    else 0 end
$$;
```

The weekly snapshot materializes each club's standings at week close, so past
weeks stay frozen even if config changes later. Mid-week views recompute with
current config. The app renders offline leaderboards from the last snapshot +
locally computed estimates.

**Weekly period:** Monday 00:00 - Sunday 23:59 in the **club timezone**
(configurable per club). Activities belong to the week containing `started_at`
in that club's timezone.

---

## 7. Data Model (Postgres)

**Design principle (D12): activities are club-agnostic.** An activity belongs
to the user, never to a club. Clubs are *scoring lenses*: every club the user
is a member of automatically sees the activity and scores it with its own
points config.

```sql
profiles         (id uuid pk -> auth.users, display_name, avatar_url,
                  share_routes bool default true, created_at)
clubs            (id uuid pk, name, timezone, week_start_day, points_config jsonb,
                  created_by, created_at)
club_members     (club_id, user_id, role ['admin','member'], joined_at,
                  pk (club_id, user_id))
invite_codes     (code text pk, club_id, created_by, expires_at, max_uses,
                  uses_count, active bool)
activities       (id uuid pk, user_id, type, started_at, ended_at,
                  distance_m int, moving_time_s int, elapsed_s int,
                  avg_hr int, max_hr int, calories int,
                  source ['health_connect','healthkit','phone_gps','manual'],
                  external_id text, notes text, track_summary,
                  review_state ['clean','needs_review'] default 'clean',
                  dup_group_id uuid, excluded bool default false,
                  status ['synced','pending'], created_at,
                  unique (user_id, source, external_id))
track_points     (activity_id, seq, lat, lon, ts, ele, accuracy,
                  pk (activity_id, seq))
weekly_snapshots (club_id, week_start date, member_stats jsonb, created_at,
                  pk (club_id, week_start))
activity_reactions (activity_id, user_id, reaction text, created_at,
                  pk (activity_id, user_id))
activity_comments  (id uuid pk, activity_id, user_id, body text, created_at)
notifications    (id uuid pk, user_id, type ['reaction','comment'],
                  activity_id, from_user_id, seen bool default false,
                  created_at)
device_tokens    (user_id, token text, platform text, created_at,
                  pk (user_id, token))
email_verifications (email text pk, code text, expires_at, created_at)
activity_notifications_log (id, activity_id, actor_name, title, body, ...)
llm_usage        (usage_date date pk, call_count int)
```

**Activity type enum:** `'run' | 'walk' | 'cycle' | 'strength'` (extensible).
Import mapping from Health Connect / HealthKit exercise types to this enum is
defined in the import feature. Unmapped types map to `'other'` (stored, shown
in feed greyed out, scores 0).

**RLS:** members of a club can read activities of fellow members (via membership
join) and their clubs' data; users write only their own rows. Track points are
readable by club members only when the owner has `share_routes = true`.

**Duplicate lifecycle:** import detects an overlapping pair (same user, same
type, >80% time overlap of shorter duration). Both rows get
`review_state='needs_review'` and share a `dup_group_id`. User picks which to
keep; the other gets `excluded=true` and scores 0 in all clubs.

---

## 8. Tracking Engine Design

Pipeline per GPS fix: **raw -> accuracy filter -> gap handling -> elevation -> session**.

1. **Accuracy filter:** drop fixes with accuracy > 25 m; if accuracy < 10 m
   use fix, else average with previous.
2. **Auto-pause:** speed < 0.7 m/s for 20 s = paused; resume when speed > 1.4 m/s
   (hysteresis). Moving time excludes pauses.
3. **Distance:** haversine between consecutive accepted fixes; reject jumps
   beyond physically plausible speeds (> 12 m/s for run/walk = drop fix).
4. **Smoothing:** light EMA on position before distance calc; no over-smoothing —
   distance integrity over prettiness.
5. **State machine:** idle -> requesting-permission -> recording -> paused -> finished;
   crash-safe (state + points persisted every fix, WAL mode).
6. **Battery:** 1-2 s fix interval during recording (geolocator foreground service);
   no recording when battery < 5% (warn at 15%).
7. **Platform notes:**
   - Android: foreground service type `location`, persistent notification required.
   - iOS: `UIBackgroundModes: location`, blue pill indicator; same engine.

**Strength training:** no GPS; simple timer with pause; start/end timestamps.

---

## 9. Push Notification Architecture

Push notifications are delivered via **Firebase Cloud Messaging** (FCM) with
server-side fan-out from Supabase Edge Functions.

### Notification types

| Type | Trigger | Function | AI-generated? |
|------|---------|----------|---------------|
| Social (reaction/comment) | DB trigger on `notifications` INSERT | `send-push` | No |
| New activity alert | DB trigger on `activities` INSERT | `send-activity-notification` | Yes (Gemini Flash) |
| Daily nudge | `pg_cron` (daily 19:00 IST) | `send-daily-nudge` | Yes (Gemini Flash) |
| Weekly leaderboard reminder | `pg_cron` (Sunday 21:00 IST) | `send-weekly-reminder` | No |

### Guardrails

- **Quiet hours:** activity notifications only fire between 07:00-22:00 IST
- **Per-user throttle:** max 3 activity notifications per user per day
- **Batch debounce:** 5-minute delay for watch imports (multiple sessions at once)
- **LLM budget:** atomic daily counter with rollback on failure; default 500
  calls/day globally, 100/day for activity notifications
- **Graceful degradation:** Gemini timeout (8s) or budget exhaustion falls back
  to magnitude-aware template strings (e.g., distance buckets for run copy)
- **Token cleanup:** stale FCM tokens (`UNREGISTERED`/`NOT_FOUND`) are deleted

### Client-side

`PushNotificationService` singleton handles:
- FCM permission request and token registration
- Android notification channel configuration
- Foreground / background / cold-start message routing
- APNs token retry logic on iOS
- Deep-link tap navigation to activity detail

---

## 10. Email Verification

A custom OTP flow sits **in front of** Supabase Auth. Before creating the
Supabase account, the app calls the `verify-email` edge function:

1. `action=send` — generates a 4-digit code, stores it in `email_verifications`
   with a 10-minute TTL, sends it via the **Brevo** transactional email API
2. `action=check` — validates the submitted code; on success, the app proceeds
   to `supabase.auth.signUp`

This gives full control over the verification UX without depending on
Supabase's built-in email delivery.

---

## 11. Sync Design

- Local-first: every activity row has `status` (pending/synced) + client UUID.
- On save / on connectivity change / on app open: push pending activities
  (idempotent upsert by client UUID).
- Pull: leaderboard + members via Supabase views with RLS; Realtime subscription
  for live leaderboard and notification updates while foregrounded.
- `ConnectivityService` singleton monitors online/offline state;
  `ConnectionAwareBuilder` widget conditionally renders offline fallback UI.
- Conflict: none expected (single-writer per activity). Edge: server rejects ->
  keep local, flag for retry.

**iOS sync reality:** iOS has no reliable background processing for network
sync — sync runs when the app is opened (plus opportunistic Background App
Refresh, OS-controlled). User-facing messaging says "opens app -> data syncs."

---

## 12. Security & Privacy

- Email + password auth with custom OTP verification; invite code required at
  signup (closed club).
- RLS is the enforcement layer, not the UI: member-only reads, own-row writes.
- Route traces: RLS-enforced. Club members can view routes only when the owner
  has `share_routes = true` (default). The owner can opt out in profile settings.
- **Account deletion:** `delete-account` edge function performs a full cascade:
  owned invite codes -> owned clubs (cascades their invites) ->
  email verifications -> `auth.admin.deleteUser()` (cascades profiles ->
  club_members, activities, device_tokens, notifications).
- No third-party analytics.

---

## 13. Weekly Card Design

Rendered client-side from the weekly snapshot query: RepaintBoundary -> PNG.

- Card: club name + week range header, ranked rows (rank badge, avatar, name,
  points bold, distance/time secondary), footer with club tagline.
- Dark theme, brand colors, 1080x1350 or 1080x1080.
- Plain-text fallback for copy-paste.

---

## 14. Distribution & Release

- **Android:** Play Store. Internal testing -> closed testing -> production.
- **Health Connect verification:** separate Google review process required for
  any app reading Health Connect data (READ_EXERCISE, READ_HEART_RATE,
  READ_DISTANCE, etc.). Requires a live privacy policy and per-data-type
  justification. Approval typically takes 2-6 weeks.
- **iOS:** App Store via TestFlight. Background location justification and
  privacy manifest required.

---

## 15. Edge Functions Reference

| Function | Trigger | Secrets Required |
|----------|---------|-----------------|
| `send-push` | DB trigger (`notifications` INSERT) | `FCM_SERVICE_ACCOUNT_KEY` |
| `send-activity-notification` | DB trigger (`activities` INSERT) | `FCM_SERVICE_ACCOUNT_KEY`, `GEMINI_API_KEY` |
| `send-daily-nudge` | `pg_cron` (daily) | `FCM_SERVICE_ACCOUNT_KEY`, `GEMINI_API_KEY` |
| `send-weekly-reminder` | `pg_cron` (Sunday) | `FCM_SERVICE_ACCOUNT_KEY` |
| `verify-email` | HTTP POST (pre-auth) | `BREVO_API_KEY`, `BREVO_FROM_EMAIL` |
| `delete-account` | HTTP POST (authenticated) | Supabase service role (auto) |

See [SECRETS_TEMPLATE.md](../supabase/SECRETS_TEMPLATE.md) for setup instructions.

---

## 16. Known Issues & Future Work

- [ ] Test coverage is low — unit tests exist for duplicate detection, feed
      parsing, and widget smoke, but most features lack tests
- [ ] No state management library (StatefulWidget + setState throughout)
- [ ] WorkManager background sync not implemented (sync on app open only)
- [ ] Health Connect on Pixel 9 with Android 14+ requires compileSdk 36
      (already configured)
- [ ] iOS push notifications require `aps-environment = production` in
      entitlements for TestFlight builds
- [ ] Zepp (Amazfit) Health Connect write can be unreliable on some models
- [ ] Huawei Health requires Health Sync bridge app (closed-source, single
      maintainer — risk if abandoned)
- [ ] Google Fit is being phased out (merged into Google Health app); members
      should migrate

### Future candidates
- Vendor cloud APIs for richer data (GPS routes from Garmin)
- WhatsApp Business API automated posting
- Treadmill / manual GPS-type activities
- Multi-club UX polish (full club management beyond the switcher)
- Start/end route segment hiding for privacy
- Per-brand onboarding guides served from remote JSON config