# RESUME PROMPT — iOS Push Notifications (STILL BROKEN after ~1 week)

> Paste this whole file into a new session to continue. Project: Outpace
> (`/Users/I589392/mygit/activeFriends`), Flutter + Supabase. Supabase CLI
> works via keychain: `supabase db query --linked "<sql>" --output-format json`
> (remote SQL, runs as admin). Project ref `eswypmvrdgilkljytrxq`.

## TASK
iOS push notifications have **never worked** (~1 week); **Android works flawlessly**. We regenerated the provisioning profile (it had been Invalid) with `aps-environment=production`, rebuilt, shipped to TestFlight — and it **STILL did not work**. Current truth: **`device_tokens` has 11 android, 0 ios.** So we're still stuck at **step 1: the iPhone never obtains/saves an FCM token** — this is a *registration* failure, NOT a delivery/APNs-key problem (there's nothing to deliver to yet). **Instrument to find the exact failure point before more guessing** — that approach just solved the Health Connect import mystery; apply it here.

## CONFIRMED CORRECT — do NOT re-investigate these
- App ID `app.activefriends.app` → Push Notifications capability ENABLED.
- Provisioning profile "Outpace App Store" **regenerated**, contains `aps-environment=production`, installed; and `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` is wired in **all** build configs (so the built app carries the entitlement).
- `app/ios/Runner/Runner.entitlements`: `aps-environment = production`.
- `Info.plist`: `UIBackgroundModes` includes `remote-notification`. `FirebaseAppDelegateProxyEnabled` NOT set → firebase_messaging swizzling defaults ON.
- `GoogleService-Info.plist` valid + matches: bundle `app.activefriends.app`, project `outpace-ab523`, `GCM_SENDER_ID 605083180569`, iOS `GOOGLE_APP_ID`.
- Dart push code present & hardened: `app/lib/features/notifications/data/push_notification_service.dart` requests permission, waits for APNs token (retries), calls `getToken()`, saves with `platform:'ios'`, and (recent fix) attaches `onTokenRefresh` BEFORE `getToken()` with try/catch.
- `_initPush()` runs from `app_shell.dart` (post-login home).

## THE FORK
0 iOS tokens → the device never gets an APNs token → `FirebaseMessaging.getToken()` fails → nothing saved. Everything in the repo is correct, so the break is the **native APNs↔Firebase handoff at runtime**, invisible without on-device logs (no ADB; iOS testers are remote friends — Mayya).

## PRIME SUSPECTS (ranked)
1. **Swizzling not attaching to the new `FlutterImplicitEngineDelegate` AppDelegate.** `app/ios/Runner/AppDelegate.swift` is the minimal new-embedding form (`didInitializeImplicitFlutterEngine`, no Firebase/APNs code). If firebase_messaging's method swizzling doesn't hook `didRegisterForRemoteNotificationsWithDeviceToken` on this embedding, the APNs token never reaches `Messaging.messaging().apnsToken` → `getAPNSToken()` null → `getToken()` fails. **Strongest suspect.**
2. **Mayya isn't on the rebuilt TestFlight build** (not uploaded/processed, or he didn't update), or didn't tap "Allow" on the permission prompt.
3. Runtime: `Firebase.initializeApp` timing, or APNs registration failing with an error we can't see (`didFailToRegisterForRemoteNotificationsWithError`).

## PLAN (do these together in ONE next build — no server component)
**A. Instrument push registration (the move that cracked import).** Add a `push_diagnostics` table (migration) and have `push_notification_service.initialize()` persist on iOS: `getNotificationSettings().authorizationStatus`, whether `getAPNSToken()` returned null (after retries), the `getToken()` result or caught error, and a timestamp — to `push_diagnostics(user_id, platform, payload jsonb)` (RLS: own rows), AND surface it on-screen via SelectableText somewhere reachable (e.g. the account/settings sheet) so Mayya can read/copy it. Then: Mayya opens the app → `supabase db query --linked "select payload from public.push_diagnostics where platform='ios' order by created_at desc limit 5;"`. This shows exactly where it breaks (APNs token null vs getToken error vs permission denied).

**B. Apply the likely fix in the same build — explicit APNs forwarding in AppDelegate** (so it doesn't depend on swizzling):
```swift
import Flutter
import UIKit
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(_ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
  override func application(_ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken        // explicit handoff
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  override func application(_ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error) {
    NSLog("[outpace][push] APNs register FAILED: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
```
Verify `FirebaseMessaging` imports in the Runner target (it's available via the firebase_messaging pod; may need `pod install`).

**C. Fastest path IF any iPhone + Mac is available:** run the app from Xcode on a physical device, watch the console for `didRegisterForRemoteNotificationsWithDeviceToken` (success) vs `didFailToRegisterForRemoteNotificationsWithError` (reason) and the `[outpace][push]` prints. This likely pinpoints it in minutes and may skip A/B.

## CHEAP CHECKS FIRST
- Confirm Mayya is on the **rebuilt** TestFlight build and tapped **Allow** on the notification prompt.
- Confirm the **APNs Auth Key (.p8)** is uploaded in Firebase Console → Project Settings → Cloud Messaging → Apple app config. (Needed for DELIVERY once a token exists — verify now so it's not the next blocker.)

## KEY FACTS / FILES / COMMANDS
- Firebase `outpace-ab523` (605083180569); bundle `app.activefriends.app`; Team `M227339B2J`; profile "Outpace App Store"; Supabase ref `eswypmvrdgilkljytrxq`.
- `device_tokens(user_id, token, platform, updated_at)` — currently 11 android, 0 ios. Check: `supabase db query --linked "select platform,count(*),max(updated_at) from public.device_tokens group by platform;" --output-format json`.
- Push code: `app/lib/features/notifications/data/push_notification_service.dart`. AppDelegate: `app/ios/Runner/AppDelegate.swift`. Build: `./build-ipa.sh` → Transporter → TestFlight.
- The deployed activity-notification/daily-nudge Edge Functions send both `android` + `apns` payloads already — the backend is NOT the problem; it's purely iOS token registration.
