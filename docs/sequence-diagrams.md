# activeFriends — Sequence Diagrams (sequencediagram.org syntax)

**Version:** 1.1 — Sept 2026
**Companion to:** docs/user-flows.md (F1–F9)

Paste each fenced block directly into https://sequencediagram.org.

## Participant legend (consistent across all diagrams)

| Participant | Component (plan §5) | Runs on |
|-------------|--------------------|---------|
| User / MemberA / MemberB / Admin | Human | — |
| AppUI | Flutter widgets/screens | Phone |
| ImportSvc | Import service (hub reader, dedupe, backfill) | Phone |
| TrackEngine | GPS tracking engine | Phone |
| GPS | OS location provider (FusedLocationProvider / CLLocationManager) | Phone (OS) |
| NotifSvc | Notification service (Realtime subscription) | Phone |
| LocalDB | Drift/SQLite (activities, watermarks, sync queue) | Phone |
| Hub | Health Connect (Android) / HealthKit (iOS) | Phone (OS) |
| VendorApp | Garmin Connect / Samsung Health / Zepp / Google Health | Phone |
| Auth | Supabase Auth | Cloud |
| Postgres | Supabase Postgres + RLS + triggers (via PostgREST) | Cloud |
| Realtime | Supabase Realtime channel | Cloud |
| ShareSheet | OS share sheet → WhatsApp | Phone (OS) |

Notes (not fragments) are used for alternate/error paths — sequencediagram.org
has no alt/loop blocks; significant error paths get their own diagram.

---

## SD1 — F1 First-Run Onboarding

```text
title F1 Onboarding — signup, join club, connect watch, backfill
User->AppUI: Launch app (first run)
AppUI->LocalDB: check auth session
LocalDB-->AppUI: none
AppUI->User: Welcome + Sign up screen
User->AppUI: email + password
AppUI->Auth: signUp(email, password)
Auth-->AppUI: session (user_id)
User->AppUI: display name, avatar
AppUI->Postgres: insert profile (user_id)
User->AppUI: invite code (or deep link auto-fill)
AppUI->Postgres: validate code (active, not expired, uses < max)
Postgres-->AppUI: valid, club_id
AppUI->Postgres: insert club_members (user_id, club_id, role=member)
AppUI->LocalDB: store session + ACTIVE club context (D12)
User->AppUI: pick device (Garmin / Samsung / Amazfit / Huawei / Google / AW / none)
AppUI->User: per-device guide page (JSON config)
User->AppUI: "Connect" 
AppUI->Hub: requestPermissions(READ_EXERCISE, READ_HEART_RATE, READ_DISTANCE, READ_STEPS)
Hub-->AppUI: granted
note right of Hub: If denied: skip import, app still works.\nBanner offers re-connect later.\n"No watch": phone GPS becomes default.
AppUI->ImportSvc: startBackfill()
ImportSvc->Hub: read ExerciseSessions (~30 days history)
Hub-->ImportSvc: session list
ImportSvc->ImportSvc: map HC/HK types -> canonical enum\n(run/walk/cycle/strength; else 'other'), dedupe (no points stored — D12)
ImportSvc->LocalDB: insert activities (external_id)
ImportSvc->Postgres: upsert activities (idempotent by external_id)
Postgres-->ImportSvc: ok
note over ImportSvc: Offline: queue stays local,\nsyncs on next app open.
ImportSvc-->AppUI: imported N activities
AppUI->User: Leaderboard + "Last synced: just now"
```

---

## SD2 — F2 Recurring Watch Import

```text
title F2 Watch Import — app open / pull-to-refresh
note over VendorApp,Hub: Before this diagram: watch recorded a run;\nuser opened vendor app (BT sync);\nvendor app wrote session to hub.
VendorApp->Hub: write ExerciseSession (+HR, distance)
User->AppUI: open app / pull-to-refresh
AppUI->ImportSvc: runImport()
ImportSvc->LocalDB: get import watermark (per source)
ImportSvc->Hub: read ExerciseSessions since watermark
Hub-->ImportSvc: new sessions
note right of Hub: Empty result = vendor app hasn't synced.\nUI shows "Last synced: Xh ago" hint.
ImportSvc->ImportSvc: filter to club types (unknown -> "Other", not scored)
ImportSvc->ImportSvc: dedupe check (exact type + >80% overlap)
note right of ImportSvc: Flagged pairs -> needs_review state (SD6).\nNormal path continues below.
ImportSvc->LocalDB: insert activities
ImportSvc->Postgres: upsert batch (idempotent by external_id)
Postgres-->ImportSvc: ok
ImportSvc->LocalDB: advance watermark
ImportSvc-->AppUI: done — "Last synced: just now"
AppUI->Postgres: query leaderboard view for ACTIVE club
(D12: activity_points(activity, club) via that club's points_config;
RLS: activity owner must share a club with me)
Postgres-->AppUI: standings
AppUI->User: updated leaderboard
```

---

## SD3 — F3 Phone GPS Tracking

```text
title F3 Phone GPS Tracking — record, finish, save, sync
User->AppUI: tap Track
AppUI->User: type picker (sticky last choice)
User->AppUI: Run
AppUI->AppUI: request location permission if needed
AppUI->AppUI: wait for GPS fix (accuracy < 20m)
User->AppUI: Start
AppUI->TrackEngine: startSession(type=run)
TrackEngine->TrackEngine: start foreground service (Android)\n/ background location mode (iOS)
note right of TrackEngine: Persistent notification on Android\n(system requirement).
GPS->TrackEngine: location fixes (1-2s interval)
TrackEngine->TrackEngine: accuracy filter -> plausibility ->\nsmooth -> auto-pause state machine
note right of TrackEngine: <0.7 m/s for 20s = paused (hysteresis 1.4 m/s).\nMoving time excludes pauses.
TrackEngine->LocalDB: persist state + trace every fix
note over TrackEngine: GPS lost: banner + timer continues;\n<60s gap extrapolated, else split marked.
User->AppUI: Finish
AppUI->User: confirm stop? (prevents accidental)
User->AppUI: confirm
TrackEngine-->AppUI: summary (distance, moving time, pace, trace)
User->AppUI: Save
AppUI->LocalDB: insert activity
AppUI->Postgres: upsert activity (sync queue drains)
Postgres-->AppUI: ok
note over Postgres: Activity appears in other members' Feed\nvia Realtime (if foregrounded).
AppUI->User: Summary — "Synced"
```

---

## SD4 — F5 Weekly Leaderboard Share

```text
title F5 Leaderboard Share — card render to WhatsApp
User->AppUI: open app (home = Leaderboard)
AppUI->Postgres: query weekly standings for ACTIVE club (RLS + D12 scoring)
Postgres-->AppUI: ranked rows (per-club points via
activity_points(activity, club) — D12, distance, time)
AppUI->User: leaderboard + "Last synced: Xh ago"
User->AppUI: Share
AppUI->AppUI: render card widget (club name, week range, ranked list)
AppUI->AppUI: RepaintBoundary -> PNG (1080x1350)
note right of AppUI: Works offline: card renders from last\nsnapshot + local per-club points estimate (D12:\npoints computed per club, not stored).
AppUI->User: Card Preview
User->AppUI: Share
AppUI->ShareSheet: share PNG
User->ShareSheet: choose WhatsApp > club group
note right of ShareSheet: Text fallback: "Copy as text" gives\nplain ranking for pasting.
```

---

## SD5 — F6 Reaction → Notification Loop (the social core)

```text
title F6 Reaction Loop — trigger, Realtime, badge, mark-seen
note over MemberB: MemberB sees MemberA's run in the
Feed because they share a club (D12:
feed/leaderboard scope = shared membership,\nnot an activity-level club_id).
MemberB->AppUI: open Activity Detail (MemberA's run)
MemberB->AppUI: tap reaction (fire emoji)
AppUI->Postgres: insert activity_reactions (activity_id, user_id=B)
Postgres->Postgres: TRIGGER on_reaction -> notify_activity_event('reaction')
note right of Postgres: SECURITY DEFINER trigger runs as\nfunction owner (postgres); table owner\nbypasses RLS = the documented\ntrusted path (plan §7). API roles\nhave insert: deny on notifications.\nSkips if owner = actor.\nReaction notifies FIRST-ever per\n(activity,user) pair only (plan §7).
Postgres->Postgres: insert notifications (user_id=A, from_user_id=B, seen=false)
Postgres->Realtime: broadcast notifications insert (RLS-filtered)
Realtime->MemberA: INSERT event (A's device, app foregrounded)
note right of Realtime: If A's app is backgrounded: no push in v1 —\nA sees the badge on next app open (unread count query).
MemberA->AppUI: tap Feed tab (badge showing)
AppUI->Postgres: select count(*) where user_id=A and seen=false
Postgres-->AppUI: 3 unread
AppUI->MemberA: Feed — items with new activity bubble up
MemberA->AppUI: tap the activity row
AppUI->Postgres: update notifications set seen=true\nwhere user_id=A and activity_id=X
AppUI->MemberA: Activity Detail (reaction bar + comments)
note right of AppUI: Badge clears. First reaction only notifies;\nreactions toggle one row per (activity, user).
```

---

## SD6 — F4 Duplicate Resolution

```text
title F4 Duplicate Resolution — flag, compare, choose
ImportSvc->LocalDB: dedupe check flags pair (watch + phone, same type, >80% overlap)
ImportSvc->LocalDB: mark both activities needs_review
LocalDB-->AppUI: badge on Me tab — "2 activities need review"
User->AppUI: open resolution screen
AppUI->LocalDB: load both rows (source, HR, distance, duration)
AppUI->User: side-by-side cards (richer record pre-selected)
User->AppUI: "Keep this one"
AppUI->LocalDB: keep chosen; delete other locally
AppUI->Postgres: upsert chosen; tombstone for discarded
note right of Postgres: "Keep both" alternative: both shown in feed,\nonly selected counts for points ("not scored" chip).\nExcluded duplicates score 0 in ALL clubs (D12).
AppUI->User: done — badge decrements
```

---

## SD7 — F9 Join a Second Club / Switch Active Club (multi-club, D12)

```text
title F9 Multi-Club — join second club, switch, shared activities
User->AppUI: Me > Clubs > Join with code
AppUI->Postgres: validate invite code (active, uses < max)
Postgres-->AppUI: valid, club_id
AppUI->Postgres: insert club_members (user_id, club_id, role=member)
Postgres-->AppUI: ok
note over Postgres: User's EXISTING activities are now
visible in the new club automatically — nothing
to re-post (no club_id on activity rows).
AppUI->User: club list — new club now selectable
User->AppUI: tap club B (switch active)
AppUI->LocalDB: set active_club = B (local UI setting)
AppUI->Postgres: query feed: activities of members of club B
Postgres-->AppUI: feed rows
note right of Postgres: Same activities the user recorded appear
for club B members too — scored by B's
points_config, not A's (activity_points fn).
AppUI->Postgres: query leaderboard view for club B
Postgres-->AppUI: B's standings (different points than A's)
AppUI->User: Feed + Leaderboard now scoped to club B
```

---

## What the diagrams surface (design validation notes)

1. **Postgres triggers are the only trusted write path to `notifications`** — SD5
   shows RLS cannot be the guard there; the trigger runs as postgres. No API
   may insert into notifications (enforced by RLS `insert: deny`).
2. **Two sync directions, one queue** — upserts to Postgres (activities,
   reactions, comments) and pulls (leaderboard, feed) both flow through the
   same connectivity gate; SD1/SD2/SD3 show offline queuing consistently.
3. **Realtime is foreground-only by design** — SD5 makes the background gap
   explicit: no push in v1, badge caught up on next open. This matches plan A6.
4. **The vendor-app step in SD2 is outside our control** — the "open Garmin
   Connect" human step is why the "Last synced" line exists; it's a UX
   compensation for an architectural dependency we can't automate in v1.
5. **Import watermark is per-source** — one watermark per source (health_connect,
   healthkit) enables mixed-device users without double-imports.
6. **Membership is the join key, not activity rows** (SD5, SD7) — feed/leaderboard
   visibility derives from shared club membership at query time; joining a new
   club retroactively surfaces all existing activities there with zero writes.
   The flip side (SD7): leaving a club hides activities instantly, also with
   zero writes — there is no per-club copy to clean up.
