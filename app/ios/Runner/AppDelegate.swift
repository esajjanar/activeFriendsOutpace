import Flutter
import UIKit
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // Explicit APNs → FCM handoff — swizzling may not hook this delegate form.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    NSLog("[outpace][push] APNs token received (\(deviceToken.count) bytes)")
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[outpace][push] APNs register FAILED: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
