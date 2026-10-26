import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let t0 = CFAbsoluteTimeGetCurrent()
    NSLog("[outpace][push] ── didFinishLaunchingWithOptions START ──")
    NSLog("[outpace][push] iOS %@, %@", UIDevice.current.systemVersion, UIDevice.current.model)

    // ── 1. Configure Firebase natively BEFORE plugins register ──
    FirebaseApp.configure()
    NSLog("[outpace][push] FirebaseApp.configure() done (+%.0fms)",
          (CFAbsoluteTimeGetCurrent() - t0) * 1000)

    // ── 2. Notification-center delegate for foreground delivery ──
    UNUserNotificationCenter.current().delegate = self

    // ── 3. Explicitly register for remote notifications NOW ──
    application.registerForRemoteNotifications()
    NSLog("[outpace][push] registerForRemoteNotifications() called (+%.0fms)",
          (CFAbsoluteTimeGetCurrent() - t0) * 1000)

    // ── 4. Dump current notification authorization state ──
    NSLog("[outpace][push] isRegisteredForRemoteNotifications = %@",
          application.isRegisteredForRemoteNotifications ? "YES" : "NO")
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      NSLog("[outpace][push] UNAuthorizationStatus = %d (0=notDetermined 1=denied 2=authorized 3=provisional)",
            settings.authorizationStatus.rawValue)
      NSLog("[outpace][push]   alert=%d badge=%d sound=%d",
            settings.alertSetting.rawValue,
            settings.badgeSetting.rawValue,
            settings.soundSetting.rawValue)
    }

    NSLog("[outpace][push] ── didFinishLaunchingWithOptions END (+%.0fms) ──",
          (CFAbsoluteTimeGetCurrent() - t0) * 1000)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // This fires AFTER didFinishLaunching — proves the plugin timing gap.
    NSLog("[outpace][push] ── didInitializeImplicitFlutterEngine → registering plugins ──")
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    NSLog("[outpace][push] ── plugin registration complete ──")
  }

  // Explicit APNs → FCM handoff — swizzling may not hook this delegate form.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    NSLog("[outpace][push] ✅ APNs token received (%d bytes) hex=%@…",
          deviceToken.count, String(hex.prefix(16)))
    Messaging.messaging().apnsToken = deviceToken

    // Confirm FCM can map the APNs token → registration token
    Messaging.messaging().token { fcmToken, error in
      if let fcm = fcmToken {
        NSLog("[outpace][push] ✅ FCM token mapped OK: %@…(%d chars)",
              String(fcm.prefix(20)), fcm.count)
      } else if let err = error {
        NSLog("[outpace][push] ⚠️ FCM token mapping failed: %@", err.localizedDescription)
      }
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let nserr = error as NSError
    NSLog("[outpace][push] ❌ APNs register FAILED: domain=%@ code=%d — %@",
          nserr.domain, nserr.code, nserr.localizedDescription)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
