# Outpace — Pre-Release Testing Checklist

Functional testing plan for verifying the app on emulators/simulators
before open-sourcing. Work through this checklist on **both Android emulator
and iOS simulator** (or real devices if available).

---

## Phase 0: Build Verification (automated)

```bash
# Set your Supabase credentials (required for backend-connected tests)
export SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"
export SUPABASE_PUBLISHABLE_KEY="your_anon_key"

# Run the automated build verification
chmod +x verify-build.sh
./verify-build.sh
```

- [ ] `verify-build.sh` completes with 0 failures
- [ ] `flutter analyze` reports no errors
- [ ] `flutter test` — all 4 tests pass

---

## Phase 1: App Launch & Offline Mode

Test that the app launches and degrades gracefully without backend.

```bash
cd app
flutter run   # no --dart-define (no backend)
```

- [ ] App launches without crash
- [ ] "OUTPACE" title is visible
- [ ] Unconfigured-state / bootstrap screen is shown (no backend connected)
- [ ] No unhandled exceptions in console

---

## Phase 2: Auth (requires Supabase backend)

```bash
cd app
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY
```

### Sign Up
- [ ] Sign-up screen renders correctly
- [ ] Email field validates input
- [ ] OTP verification email is received (check Brevo delivery)
- [ ] 4-digit OTP code entry works
- [ ] Successful sign-up creates a Supabase auth user
- [ ] Error state: invalid OTP shows error message
- [ ] Error state: expired OTP (wait >10 min) shows error

### Sign In
- [ ] Sign-in screen renders
- [ ] Valid credentials → successful login
- [ ] Invalid credentials → error message shown
- [ ] Session persists across app restart (cold start)

### Sign Out
- [ ] Sign-out button works
- [ ] Returns to auth screen
- [ ] Session is cleared

---

## Phase 3: Onboarding & Club

### Club Join
- [ ] After sign-up, invite code entry screen appears
- [ ] Valid invite code → joins club successfully
- [ ] Invalid code → error message
- [ ] Expired code → error message
- [ ] Club name and member list are displayed after joining

### Profile
- [ ] Profile screen shows display name
- [ ] Avatar upload works (camera or gallery)
- [ ] Avatar displays correctly after upload
- [ ] Display name can be edited
- [ ] Route sharing toggle is visible and functional

---

## Phase 4: Activity Import (Health Connect / HealthKit)

> **Note:** Health Connect is not available on standard Android emulators.
> HealthKit is not available on iOS simulator. These tests require **real
> devices** or a Health Connect-enabled emulator image.

### If on real Android device with Health Connect:
- [ ] Health Connect permission request appears
- [ ] Granting permissions succeeds
- [ ] Historical activities are imported (backfill)
- [ ] Imported activities show in the activity list
- [ ] Activity type mapping is correct (run/walk/cycle/strength)
- [ ] HR and calories are captured when available
- [ ] Duplicate detection works (import same session twice)
- [ ] Duplicate resolution UI shows side-by-side comparison

### If on real iOS device with HealthKit:
- [ ] HealthKit permission sheet appears
- [ ] Activities are imported after permission granted
- [ ] Same validation as Android above

### If on emulator/simulator (no health data):
- [ ] App handles "no Health Connect" gracefully (Android)
- [ ] App handles "no HealthKit data" gracefully (iOS)
- [ ] Manual activity logging still works (see Phase 5)

---

## Phase 5: GPS Tracking

### Start Recording
- [ ] Tap "Start" → type selector appears
- [ ] Last-used type is sticky (pre-selected)
- [ ] Location permission request appears (if not granted)
- [ ] Recording screen shows: timer, distance, pace/speed
- [ ] Map shows current position with trail

### During Recording
- [ ] Distance increments as you move (use emulator GPS simulation)
- [ ] Timer counts up correctly
- [ ] Auto-pause activates when stationary (speed < 0.7 m/s for 20s)
- [ ] Auto-resume when moving again (speed > 1.4 m/s)
- [ ] "Paused" indicator is visible during auto-pause
- [ ] Lock screen → recording continues (foreground service on Android)

### Finish & Save
- [ ] Tap "Finish" → summary screen appears
- [ ] Summary shows: distance, moving time, elapsed time, avg pace/speed
- [ ] Map trace is visible on summary
- [ ] "Save" persists the activity locally
- [ ] Activity appears in the feed after sync

### Strength Training
- [ ] Manual log: select Strength → duration input → optional notes
- [ ] Save → activity appears in feed
- [ ] Points calculated correctly (10 pts per 15 min)

### GPS Simulation (Emulator)
On Android Emulator: Extended Controls → Location → Routes → Play route
On iOS Simulator: Debug → Location → Freeway Drive (or custom GPX)

- [ ] Simulated route produces reasonable distance
- [ ] Map trace follows the simulated route

---

## Phase 6: Leaderboard

- [ ] Leaderboard is the home screen
- [ ] Shows current week (Monday–Sunday)
- [ ] Ranks members by points (highest first)
- [ ] Each row shows: rank, avatar, name, points, distance/time
- [ ] Pull-to-refresh updates the leaderboard
- [ ] Points match expected formula:
  - Run: km × 10 (e.g., 5 km = 50 pts)
  - Walk: km × 7
  - Cycle: km × 3
  - Strength: 10 pts per 15 min

### Share Card
- [ ] "Share" button generates a leaderboard card image
- [ ] Card shows club name, week range, ranked members
- [ ] OS share sheet opens with the image
- [ ] Plain-text fallback available

---

## Phase 7: Activity Feed

- [ ] Feed tab shows all club members' activities
- [ ] Newest first (chronological)
- [ ] Each card shows: avatar, name, type, distance/time, points
- [ ] Pagination works (scroll to load more, 20 per page)
- [ ] "My activities" filter works
- [ ] Search on activity notes works

### Activity Detail
- [ ] Tap an activity → detail screen opens
- [ ] Shows all metrics (distance, time, pace, HR, calories)
- [ ] Route map visible if GPS activity + route sharing enabled
- [ ] Route map hidden if owner disabled route sharing

### Reactions
- [ ] Tap reaction → emoji picker appears
- [ ] Selecting an emoji adds the reaction
- [ ] Reaction count updates in feed
- [ ] Cannot react to own activity (blocked)
- [ ] Un-react works (tap same reaction again)

### Comments
- [ ] Comment input field visible on detail screen
- [ ] Posting a comment works
- [ ] Comment appears immediately
- [ ] Comment count updates in feed

---

## Phase 8: Push Notifications

> **Note:** Push notifications require a real device with Google Play
> Services (Android) or APNs (iOS). FCM does not work on most emulators.

### If on real device:
- [ ] FCM permission prompt appears on first launch
- [ ] Accepting registers the device token in Supabase
- [ ] Reaction on your activity → push notification received
- [ ] Comment on your activity → push notification received
- [ ] New activity by club member → push notification with creative copy
- [ ] Tapping notification deep-links to the activity detail
- [ ] Notification channel "Outpace Social" appears in Android settings

### If on emulator:
- [ ] App does not crash if FCM is unavailable
- [ ] In-app unread badge still works (via Supabase Realtime)

---

## Phase 9: Notifications (In-App)

- [ ] Unread badge appears on feed tab when new reactions/comments exist
- [ ] Opening activity detail marks notifications as seen
- [ ] Badge clears after viewing
- [ ] Real-time updates while app is foregrounded (Supabase Realtime)

---

## Phase 10: Offline Behavior

- [ ] Enable airplane mode
- [ ] App launches from cold start (shows cached data)
- [ ] Leaderboard shows last-known data
- [ ] Recording a GPS activity works offline (local SQLite)
- [ ] Saving an activity while offline works (status = pending)
- [ ] Offline indicator/banner is visible
- [ ] Re-enable network → pending activities sync automatically
- [ ] Leaderboard refreshes with latest data

---

## Phase 11: Account Deletion

- [ ] Account deletion option is accessible (Profile → Settings or similar)
- [ ] Confirmation dialog warns about data loss
- [ ] Confirming deletion removes the account
- [ ] User is returned to the auth screen
- [ ] Re-signing up with the same email works (clean slate)

---

## Phase 12: Edge Cases

- [ ] Very long activity notes (500+ chars) — no UI overflow
- [ ] Activity with 0 distance (stationary GPS) — handled gracefully
- [ ] Rapid tap on "Save" button — no double-save
- [ ] Network disconnect mid-sync — no crash, retry on reconnect
- [ ] Switch between light and dark mode — all screens render correctly
- [ ] Rotate device (landscape) — no layout crashes
- [ ] Deep link with invite code (if implemented)
- [ ] Multiple clubs: switch active club → leaderboard and feed update

---

## Results Summary

| Phase | Android | iOS | Notes |
|-------|---------|-----|-------|
| 0. Build verification | | | |
| 1. App launch / offline | | | |
| 2. Auth | | | |
| 3. Onboarding / club | | | |
| 4. Activity import | | | Needs real device |
| 5. GPS tracking | | | Use GPS simulation |
| 6. Leaderboard | | | |
| 7. Activity feed | | | |
| 8. Push notifications | | | Needs real device |
| 9. In-app notifications | | | |
| 10. Offline behavior | | | |
| 11. Account deletion | | | |
| 12. Edge cases | | | |

**Pass criteria:** All phases pass on at least one platform (Android or iOS).
Phases 4 and 8 require real devices — document as known limitations if
emulator-only testing is performed.
