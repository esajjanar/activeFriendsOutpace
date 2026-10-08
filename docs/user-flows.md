# activeFriends — Detailed User Flows

**Version:** 1.1 — Sept 2026
**Companion to:** docs/plan.md (§3 journeys map to flows below)

Flows are written as: trigger → steps (screens/actions) → alternate & error paths.
Screen names refer to the navigation structure defined first.

---

## 0. Navigation Structure

Bottom navigation (4 tabs + center action):

```
┌──────────────────────────────────────────────┐
│  [Leaderboard]  [Feed]   (TRACK)  [Me]       │
│     home        club-wide   big FAB  profile │
│                             button           │
└──────────────────────────────────────────────┘
```

- **Leaderboard** (home): this week's standings, week switcher, "Last synced:
  X h ago" line, Share button.
- **Feed**: chronological activity feed (J6) — activities of members of the
  **active club** (D12: same underlying activities render per club; switching
  active club re-scopes this list). Unread badge lives here.
- **Track** (center button): starts phone GPS tracking flow (F3).
- **Me**: profile, own activity history, flagged duplicates, club info, invite
  (admin), settings (points config display, privacy, sign out, delete account).

Pushed screens (no tab): Onboarding, Activity Detail, Duplicate Resolution,
Card Preview, Manual Log, Connect Watch guide.

---

## F1 — First-Run Onboarding

**Trigger:** first app launch (no auth session).

**Happy path:**
1. **Welcome** — club name/logo, "Join your club" CTA.
2. **Sign up** — email + password (Supabase Auth). Option: "Already a member?
   Sign in."
3. **Profile** — display name (pre-filled from email, editable), avatar
   (optional, pick from gallery or initials default).
4. **Invite code** — 6–8 char code (from admin) OR deep-link auto-fills.
   Validation: code exists, active, not expired, under max uses.
5. **Connect your watch** — device picker (Garmin / Samsung / Amazfit / Huawei /
   Google Fit / Apple Watch / No watch — I'll use phone tracking). Per-device
   instruction page (from the JSON config, plan §J2c).
6. **Hub permission** — Health Connect / HealthKit permission prompt with
   plain-language rationale ("read your workouts to build the club leaderboard").
7. **Backfill import** — spinner with count; imports available history
   (typically ~30 days). Skippable.
8. **Done** — lands on Leaderboard with a welcome toast; first import visible.

**Alternate / error paths:**
- Wrong/expired invite code → inline error, retry, "ask admin for a new code."
- Hub permission denied → app continues (can still track with phone GPS and log
   manually); banner on Leaderboard: "Watch import off — connect" → re-prompt.
- No watch selected → skip steps 5–7; onboarding complete, phone tracking is
   default path.
- Email already registered → "Sign in instead" link, then continue at step 4
  (join club with existing account).

**State at end:** authenticated, profile complete, joined club set as active
club, import source configured (or explicitly none), backfill imported or
skipped. (D12: if joining a second club later, F9 — the new club becomes
selectable in the switcher; imports never re-run per club.)

---

## F2 — Watch Import (recurring, foreground)

**Trigger:** app open (cold start or resume), and pull-to-refresh on Leaderboard
or Feed.

**Happy path:**
1. Foreground job: read new ExerciseSessions from hub since last import
   watermark (per-source, stored locally).
2. Filter to activity types (run/walk/cycle/strength; unknown types →
   "Other," excluded from points, shown in feed greyed out). Note: import is
   club-agnostic (D12) — it runs once and every member club picks the
   activity up automatically.
3. Dedupe check per plan §J2c: exact type match + >80% overlap of shorter
   duration → mark both `needs_review` (F4).
4. New sessions insert to local DB with `external_id` (no points stored —
   D12), queued for sync.
5. Sync queue drains to Supabase (idempotent upsert).
6. UI: "Last synced: just now." Leaderboard/Feed update (Realtime if
   foregrounded).

**Alternate / error paths:**
- Hub permission revoked (user revoked in system settings) → detect on read
  failure → banner "Watch import paused — reconnect" → re-prompt.
- Vendor app hasn't synced (watch → vendor app chain broken; e.g. Garmin
  Connect not opened since the run) → nothing new in hub; "Last synced" line
  shows age; tap → per-device "open your watch app to sync" hint.
- No connectivity → import still works (hub is on-device); Supabase sync
  deferred to queue; badge on Me tab shows pending count.
- Partial data (no HR on some types) → import anyway, show what exists.

---

## F3 — Phone GPS Tracking

**Trigger:** Track button.

**Happy path:**
1. **Pre-start** — activity type picker (sticky last choice), GPS signal wait
   (accuracy < 20 m), "Start" enabled when fix is good.
2. **Recording** — elapsed, distance, current pace, map (cached tiles OK);
   notification with ongoing status (Android foreground service). Screen can
   lock; wake-screen glance widget (Android) / Dynamic Island-style live
   activity (iOS).
3. **Auto-pause** — stops < 0.7 m/s for 20 s; banner "paused"; resumes > 1.4 m/s.
   Moving time excludes pauses.
4. **Finish** — tap stop → confirm (prevents accidental stop) → **Summary**:
   distance, moving time, elapsed, avg pace, elevation, map trace, HR if hub
   contributed any. Save or Discard (confirm).
5. **Save** → local insert + sync queue (no points persisted — D12; any
   leaderboard points are computed from the active club's config) → back to
   Summary with "Synced" / "Will sync" state.

**Alternate / error paths:**
- GPS lost mid-activity → banner "Waiting for GPS," timer continues, gap
  recorded; distance across gap extrapolated only if < 60 s, else split marked.
- Incoming call / app backgrounded → recording continues (foreground service /
  background location mode); on return, state intact.
- App killed by user mid-recording → on next open: "Resume or discard last
  activity?" (state persisted every fix).
- Low battery (< 15%) → warning; (< 5%) → auto-finish and save.
- Location permission set to "While using" denied for background → recording
  stops if user leaves app; explain + offer settings deep link.

**Exit states:** saved activity (synced or queued) OR confirmed discard.

---

## F4 — Duplicate Resolution

**Trigger:** duplicates flagged in F2 (or user opens "Needs review" in Me).

**Happy path:**
1. Me tab badge: "2 activities need review."
2. **Resolution screen** — side-by-side cards: type, time window, source
   (watch icon vs phone), distance, duration, HR present/absent.
3. Suggested default: richer record (HR present, more metrics) pre-selected.
4. User picks "Keep this one" (loser gets `excluded=true` + deleted locally /
   tombstone synced; scores 0 in all clubs) or "Keep both" (exactly one of the
   pair gets `excluded=true`; both show in feed with "not scored" chip on the
   excluded one). Resolution is persisted per activity via the `excluded` flag
   + `dup_group_id` grouping (plan §7).
5. Confirm → done, badge decrements.

**Alternate paths:**
- "Not a duplicate" (back-to-back legit activities falsely paired — shouldn't
  happen with exact-type + 80% rule, but escape hatch exists) → unflag both.

---

## F5 — Weekly Leaderboard & Share

**Trigger:** app open (home) or Share button.

**Happy path:**
1. **Leaderboard** — this week (Mon 00:00 → now): rank, avatar, name, points
   (bold), distance + time (secondary), activity-type chips. Current user's row
   highlighted. Week switcher for past weeks (from snapshots).
2. **Share** → **Card Preview** — rendered card for the **active club**
   (club name, week range, ranked list, tagline) → "Share" → OS share sheet
   → WhatsApp.
3. Text fallback: "Copy as text" → monospace ranking for paste.

**Alternate / error paths:**
- Mid-week share → card shows "week to date" and date range; allowed.
- No activities yet this week (fresh club) → empty state with invite prompt.
- Offline → card renders from the last snapshot + a local per-club points
  estimate (D12: points are never a stored field); sync deferred.

---

## F6 — Feed, Reactions, Comments & Notification Loop

**Trigger:** Feed tab; badge states driven by notifications table.

**Happy path:**
1. **Feed** — newest first: avatar, name, type icon, "5.2 km · 31 min · 12 pts"
   (points shown are the active club's scoring, D12),
   reaction summary (emoji + count), comment count, "2 new" chip for
   since-last-visit items. Filter: All / Mine. List = activities of members
   of the active club.
2. Tap row → **Activity Detail** — full metrics, map (phone-tracked only),
   reaction bar (tap emoji to add/remove own), comment thread + composer.
3. Member B reacts to Member A's run → trigger inserts notification row (plan
   §7) → Realtime pushes to A if foregrounded → A's Feed tab badge increments.
4. A taps badge → Feed (sorted so items with unseen reactions/comments bubble
   up) → opens the activity detail → notifications for that activity marked
   `seen` → badge clears.

**Alternate / error paths:**
- Comment while offline → queued locally with optimistic UI; syncs on next
  connectivity (conflict-free: appends only).
- Reaction toggled repeatedly → single row per (activity, user); notification
  inserted only on the **first-ever** reaction per (activity, user) pair —
  un-react + re-react does not notify again. Every comment notifies (no
  dedupe).
- Self-reaction → allowed, but no notification (trigger skips self).
- Feed pagination → 20 items/page, "load more."

---

## F7 — Manual Strength Log

**Trigger:** Me → "Log activity" (also entry point for future manual types).

**Happy path:**
1. Type = Strength (pre-selected). Live timer with pause, or manual
   duration entry.
2. Optional description ("legs — squats/rmps"), no metrics required.
3. Save → activity is stored and synced; it contributes duration-based points
   in leaderboard scoring (duration/15 min, rounded down), with points
   computed per club at query/snapshot time (not stored on the activity row)
   → feed + leaderboard.

**Edge:** edit/delete within 24 h allowed (own activities only; later edits
flagged in feed with "edited" chip).

---

## F8 — Admin: Invite a Member

**Trigger:** admin, Me → Club → Invite.

**Happy path:**
1. Generate code (8-char, expires 14 days, max 10 uses — configurable).
2. Share via OS share sheet: "Join activeFriends! Code: ABCD-1234" + store
   link. Optional deep link that auto-fills the code.
3. Member list shows join events.

**Alternate:** admin deactivates a code at any time; removes a member (kicks
from club; their historical activities stay in past snapshots, hidden from
current views).

---

## F9 — Join a Second Club / Club Switching (multi-club, D12)

**Trigger:** Me → Clubs → Join with code; or tapping a club in the club list.

**Happy path:**
1. **Join** — same invite-code entry as onboarding (F1 step 4); code validates
   against the new club → member now in 2+ clubs.
2. **Active club switcher** — Me → Clubs lists all joined clubs with role
   badges; tapping one sets it as the *active club* (stored locally).
3. Leaderboard, Feed, Share card, and points config all render for the active
   club. **Activities are never posted or duplicated** — every activity the
   user records or imports automatically appears in all their clubs' feeds
   and leaderboards, scored per club.
4. Notifications and reactions are club-agnostic too (a reaction from a
   work-club member shows the same as one from the friends club).

**Rules:**
- Weekly snapshots are per club — leaving/joining mid-week affects only that
  club's snapshot going forward.
- Leaving a club hides its leaderboard/feed; activities stay in the user's
  history and other clubs.
- v1 keeps ONE active club at a time; v2 may show a combined view.

---

## Cross-Cutting Rules

- **Sync states:** every activity row shows Queued / Synced / Needs review;
  Me tab shows pending-sync count.
- **Offline:** leaderboard renders from the last weekly snapshot + a local
  per-club points estimate (never a stored points field); all writes queue;
  banner when offline.
- **Week boundary:** the **club timezone** (v1: IST; configurable per club
  setting — one locked rule, plan §6), Monday start. Activities belong to the
  week containing `started_at` in that club's timezone.
- **Multi-club (D12):** activities are club-agnostic; the active club is a
  local UI setting; every club the user belongs to sees every activity,
  scored by its own points config. No posting, no duplication.
- **Points (D12):** computed **per club** at query/snapshot time from that
  club's config (server-side `activity_points` function is source of truth;
  the app keeps a local estimate for offline rendering). Weekly snapshots
  freeze each club's standings at week close; duplicate-resolution exclusions
  score 0 in all clubs.
- **Permissions (runtime):** location (F3), Health Connect/HealthKit (F2),
  notifications (post/keep-alive only, optional).
- **Account deletion:** Me → Settings → Delete account → confirm (type name) →
  anonymize activities, remove profile, revoke club membership.

---

## Flow-to-Milestone Mapping

| Flow | Milestone |
|------|-----------|
| F1 Onboarding | M1 |
| F2 Watch import | M2 |
| F5 Leaderboard + share | M3 |
| F6 Feed / react / comment / badge | M3 |
| F3 Phone GPS tracking | M4 |
| F4 Duplicate resolution | M4 (algorithm live from M2 as flag-only) |
| F7 Strength log | M3 (trivial, ships with feed) |
| F8 Admin invite | M1 |
| F9 Join second club / switcher | M1 (switcher) — join flow reuses F1 |
