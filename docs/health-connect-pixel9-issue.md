# Health Connect "Needs Update" Issue — RESOLVED

**Status:** ✅ Resolved (root cause found + fix verified on device)
**Verified:** Galaxy S23 (RZCW40WJC5L), 2026-09-26 — Health Connect now shows the permission dialog and lists Outpace under Allowed access.
**Pending:** Confirm on corporate Pixel 9 via a Play Store release (device can't be sideloaded — no developer mode). Fix is verified on S23, so this is a low-risk confirmation, not a guess.

---

## Symptom

Health Connect showed "Outpace needs to be updated to continue syncing with Health Connect." Outpace never appeared in the "Allowed access" list, and `requestAuthorization()` could not present the permission dialog. iOS/HealthKit always worked with the same shared Dart logic.

## Root cause

**The AndroidManifest was missing the `ViewPermissionUsageActivity` activity-alias required by Android 14+ integrated Health Connect.**

When Health Connect became a platform-integrated component (Android 14+), Google added a new requirement: apps must declare an activity that handles the `android.intent.action.VIEW_PERMISSION_USAGE` intent with the `android.intent.category.HEALTH_PERMISSIONS` category, guarded by the `android.permission.START_VIEW_PERMISSION_USAGE` permission. This is the entry point integrated Health Connect uses to resolve an app's permission-usage / privacy-policy screen.

The app declared **only** the older `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE` intent filter, which covers Android 13 and below. Without the new alias, integrated Health Connect cannot recognise the app as a compatible client and flags it as "needs to be updated."

This is a documented requirement in the `health` Flutter package's own Android setup instructions.

### Why the evidence pointed here

| Observation | Explanation |
|-------------|-------------|
| iOS/HealthKit always worked | HealthKit has no equivalent requirement |
| Failed on Pixel 9 (Android 14+) | Integrated Health Connect enforces the alias |
| **Then started failing on Galaxy S23 too** | The S23 received the Health Connect update that enforces it — proving this is **not device-specific** |
| Previously worked on Samsung | Older Health Connect didn't require the alias |

## The fix

**1. `app/android/app/src/main/AndroidManifest.xml`** — added the activity-alias:

```xml
<activity-alias
    android:name="ViewPermissionUsageActivity"
    android:exported="true"
    android:targetActivity=".MainActivity"
    android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
    <intent-filter>
        <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />
        <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
    </intent-filter>
</activity-alias>
```

**2. `app/android/app/build.gradle.kts`** — removed a harmful override:

```kotlin
// REMOVED — this pinned connect-client OLDER than the 1.2.0-alpha02 the health
// plugin (13.3.2) is compiled against, risking runtime API mismatches:
// implementation("androidx.health.connect:connect-client:1.1.0-rc03")
```

**3. `app/lib/features/import/data/health_import_service.dart`** — kept a diagnostic: on Android, `getHealthConnectSdkStatus()` is captured and appended to any `HealthImportException`, so the on-screen error reveals the actual HC state (useful for the Pixel 9, which can't be inspected via ADB).

---

## Red herring to avoid (what the previous investigation got wrong)

The earlier version of this doc assumed the problem was **Pixel-9-specific** and chased the `androidx.health.connect:connect-client` version (trying `1.1.0-rc03`, considering `1.2.0-alphaXX`). This was the wrong axis entirely. The connect-client version was never the cause — the missing manifest alias was. The "Pixel-specific" framing (untrue — it reproduced on Samsung once that device updated) is what misdirected the diagnosis.

**Lesson:** If Health Connect says an app "needs to be updated" but iOS works, check the `ViewPermissionUsageActivity` manifest alias FIRST. Don't chase connect-client versions, and never pin connect-client below what the `health` plugin bundles.

---

## Related files

- `app/android/app/src/main/AndroidManifest.xml` — activity-alias (the fix)
- `app/android/app/build.gradle.kts` — connect-client override removed
- `app/lib/features/import/data/health_import_service.dart` — HC SDK-status diagnostic
- `app/android/app/src/main/kotlin/app/activefriends/app/MainActivity.kt` — `FlutterFragmentActivity` (correct, unchanged)
