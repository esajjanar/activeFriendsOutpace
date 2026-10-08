# RESUME PROMPT — Watch Import (Health Connect / HealthKit)

> Paste this whole file into a new session to continue. Project: Outpace
> (`/Users/I589392/mygit/activeFriends`), Flutter + Supabase. You have
> Supabase CLI access via keychain: `supabase db query --linked "<sql>"
> --output-format json` (runs remote SQL as admin). Project ref
> `eswypmvrdgilkljytrxq`. Related memory: [[health-connect-import-missing-subread-perms]].

## TASK
**Android watch import is FIXED and working** (verified on a Pixel 9 — activities import correctly). **Now a suspected iOS regression:** iPhone user **Mayya** can't import his **last 2 activities** (10-03, 10-04). Figure out whether my Android fix broke iOS import, and fix it without regressing Android. **Confirm the cause before changing code** (I burned a lot of this project's time guessing — instrument/verify first).

## HOW WATCH IMPORT WORKS
- Watch → vendor app → **Health Connect (Android) / HealthKit (iOS)** → Outpace reads via the `health` Flutter pkg (**v13.3.2**) in `app/lib/features/import/data/health_import_service.dart`. UI: `app/lib/features/import/presentation/watch_import_section.dart`.
- Imported activities are upserted to `public.activities` with `source` = `health_connect` (Android) or `healthkit` (iOS), dedup key `(user_id, source, external_id)`.
- There's a cross-source dedup: an import that overlaps an existing `phone_gps` activity (same type, >80% time overlap) is skipped (`_overlapsOutpaceActivity`). Manual logs are NOT dedup'd (by design).

## WHAT I CHANGED THIS SESSION (all shared Dart unless noted — runs on BOTH platforms)
1. **Android root-cause fix (the big one):** `health` 13.x `handleWorkoutData` (Android native) does per-session sub-reads of DistanceRecord/TotalCaloriesBurnedRecord/StepsRecord; missing READ perms → Health Connect throws SecurityException → the pkg **swallows it and returns [] → "0 imported"**. Fix: split `_readTypes` (WORKOUT, HEART_RATE — what we actually read) from **`_authTypes`** (now also DISTANCE_DELTA, TOTAL_CALORIES_BURNED, STEPS — what we request permission for). Added `android.permission.health.READ_TOTAL_CALORIES_BURNED` to `app/android/app/src/main/AndroidManifest.xml`.
2. **Watermark fix:** `importStart = start` (always rescan last 30 days) instead of forward-only `watermark - 5min`; relies on the external_id upsert to dedup. (Wider window; imports more, not fewer.)
3. **Error-only diagnostics:** when `imported==0 && skipped==0`, gather a breakdown (SDK status, per-type perms, raw read counts, a 365-day WORKOUT probe) → shown on-screen (SelectableText) AND written to `public.import_diagnostics (user_id, platform, payload jsonb)`. Migration `20261004002000_import_diagnostics`.
4. **Result message:** now "`N synced · M already in Outpace · ...`" (surfaces dedup skips).

## LEADING HYPOTHESIS for the iOS regression (verify, don't assume)
**The `_authTypes` expansion runs on iOS too.** On iOS/HealthKit the Android sub-reads don't exist (HKWorkout carries totals natively), so DISTANCE_DELTA/TOTAL_CALORIES_BURNED/STEPS are unnecessary there. If the `health` pkg's iOS `requestAuthorization` returns **false** when the newly-added types aren't authorized, the function throws `'Health permission was not granted.'` at [health_import_service.dart ~L58] → **whole import fails**. Timing fits: Mayya's imports worked through 10-02, then his TestFlight build (with my changes) likely updated and 10-03/10-04 failed.

**Proposed fix (if confirmed):** make the extra types Android-only —
```dart
static const _readTypes = [HealthDataType.WORKOUT, HealthDataType.HEART_RATE];
static final _authTypes = Platform.isAndroid
    ? const [HealthDataType.WORKOUT, HealthDataType.HEART_RATE,
             HealthDataType.DISTANCE_DELTA, HealthDataType.TOTAL_CALORIES_BURNED,
             HealthDataType.STEPS]
    : const [HealthDataType.WORKOUT, HealthDataType.HEART_RATE];
```
(iOS back to the original 2; Android keeps the fix.) Then confirm the `health` pkg iOS `requestAuthorization` behavior justifies it.

## DATA SNAPSHOT (2026-10-04)
- Mayya: 35 `healthkit` + 4 `phone_gps` activities; last successful import 10-02 06:55; **10-03 & 10-04 missing**.
- `import_diagnostics`: 1 android row, **0 ios rows** (note: it only logs when imported==0 && skipped==0, and NOT if the function throws earlier — so absence doesn't prove much).
- Android success confirmed on Pixel 9.

## TROUBLESHOOTING STEPS (next session)
1. **Confirm Mayya's build:** is he on a build WITH my import changes (TestFlight v3-ish) or an older one? If older → my change can't be the cause; look at HealthKit sync lag / his 10-03,10-04 not in HealthKit. (Ask the user; or infer: if he's on the new build and import returns empty, an `import_diagnostics` ios row should appear when he taps Import — have him try and re-query.)
2. **Reproduce with diagnostics:** have Mayya tap Import; read the on-screen diagnostics block (new build shows it on 0) OR `select * from import_diagnostics where platform='ios' order by created_at desc`. Look at `authorized`, `permissions`, `raw_workouts`, `probe_workouts_365d`.
3. **Check the `health` pkg iOS `requestAuthorization` semantics** for v13.3.2 (source in `~/.pub-cache/hosted/pub.dev/health-13.3.2/`): does requesting un-granted READ types make it return false on iOS? If yes → apply the platform-split fix above.
4. **Also consider non-code causes:** Apple Watch→HealthKit sync lag (his last 2 may simply not be in HealthKit yet), or Mayya needing to re-grant HealthKit permissions after the build update.
5. Fix → ship in next iOS build → have Mayya re-import his 10-03/10-04 → verify they land in `activities` (source=healthkit).

## KEY COMMANDS
- Mayya's activities: `supabase db query --linked "select to_char(a.started_at at time zone 'Asia/Kolkata','MM-DD HH24:MI') started, a.type, a.source from public.activities a join public.profiles p on p.id=a.user_id where p.display_name ilike 'Mayya%' order by a.started_at desc limit 15;" --output-format json`
- iOS diagnostics: `supabase db query --linked "select d.created_at, d.payload from public.import_diagnostics d where d.platform='ios' order by d.created_at desc;" --output-format json`
- `flutter analyze lib/features/import/` after edits.
- Import changes ship in an app build (no server component). Android via Play internal track; iOS via TestFlight.

## FILES
- `app/lib/features/import/data/health_import_service.dart` (core logic, `_authTypes`/`_readTypes`)
- `app/lib/features/import/presentation/watch_import_section.dart` (UI + result message)
- `app/android/app/src/main/AndroidManifest.xml` (health READ perms)
- `supabase/migrations/20261004002000_import_diagnostics.sql`
