import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _channelId = 'outpace_social_v2';
const _channelName = 'Activity updates';
const _channelDescription = 'Reactions and comments on your activities';

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Latest iOS push diagnostics — readable from the UI for remote debugging.
  Map<String, dynamic>? lastDiagnostics;

  void Function(String activityId)? onActivityTapped;
  void Function(String clubId)? onWeeklyReminderTapped;

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(
          '@drawable/ic_notification_wrapper',
        ),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        _routePayload(details.payload);
      },
    );

    if (Platform.isAndroid) {
      final androidNotifications = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidNotifications?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
      await androidNotifications?.requestNotificationsPermission();
    }

    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeMessage(message);
    });

    // On iOS, FCM needs an APNs token first. It may not be ready immediately
    // after permission is granted (APNs registration is async). Retry a few
    // times before giving up — onTokenRefresh will catch it later regardless.
    String? apnsStatus;
    if (Platform.isIOS) {
      var apnsToken = await _messaging.getAPNSToken();
      if (apnsToken == null) {
        for (var attempt = 0; attempt < 3; attempt++) {
          await Future<void>.delayed(const Duration(seconds: 2));
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) break;
        }
        if (apnsToken == null) {
          apnsStatus = 'null_after_retries';
          if (kDebugMode) {
            debugPrint('[outpace][push] APNs token still null after retries — '
                'will rely on onTokenRefresh');
          }
        }
      }
      apnsStatus ??= 'present_${apnsToken!.length}bytes';
    }

    // Always attempt to get the FCM token AND register the refresh listener,
    // even if APNs wasn't ready yet. onTokenRefresh fires once APNs completes.
    // Attach the refresh listener FIRST, so that if the initial getToken()
    // fails (on iOS it can throw apns-token-not-set when APNs registration
    // hasn't completed yet), we still capture the token once APNs finishes
    // and onTokenRefresh fires. Previously a throw here skipped the listener
    // entirely, leaving the device permanently unregistered.
    _messaging.onTokenRefresh.listen(_saveToken);
    String? fcmToken;
    String? fcmError;
    try {
      fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await _saveToken(fcmToken);
        if (kDebugMode) debugPrint('[outpace][push] device token registered');
      }
    } catch (error) {
      fcmError = error.toString();
      if (kDebugMode) {
        debugPrint('[outpace][push] getToken failed, will retry via '
            'onTokenRefresh: $error');
      }
    }

    // ── iOS push diagnostics: write to Supabase + keep in memory ──
    if (Platform.isIOS) {
      final settings = await _messaging.getNotificationSettings();
      final diag = <String, dynamic>{
        'authorization': settings.authorizationStatus.name,
        'apns_token': apnsStatus,
        'fcm_token': fcmToken != null
            ? '${fcmToken.substring(0, 12)}…(${fcmToken.length})'
            : null,
        'fcm_error': fcmError,
        'ts': DateTime.now().toUtc().toIso8601String(),
      };
      lastDiagnostics = diag;
      if (kDebugMode) debugPrint('[outpace][push] diag: $diag');
      _writeDiagnostics(diag);
    }
  }

  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  void routeInitialMessage(RemoteMessage? message) {
    if (message != null) _routeMessage(message);
  }

  void _routeMessage(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type == 'weekly_reminder') {
      final clubId = message.data['club_id'] as String?;
      if (clubId != null && clubId.isNotEmpty) {
        onWeeklyReminderTapped?.call(clubId);
      }
    } else {
      final activityId = message.data['activity_id'] as String?;
      if (activityId != null && activityId.isNotEmpty) {
        onActivityTapped?.call(activityId);
      }
    }
  }

  void _routePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    if (payload.startsWith('weekly:')) {
      onWeeklyReminderTapped?.call(payload.substring(7));
    } else {
      onActivityTapped?.call(payload);
    }
  }

  Future<void> clearToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('device_tokens')
          .delete()
          .eq('user_id', user.id)
          .eq('token', token);
    } catch (_) {}
    await _messaging.deleteToken();
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] as String?;
    final payload = type == 'weekly_reminder'
        ? 'weekly:${message.data['club_id']}'
        : message.data['activity_id'] as String?;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification_wrapper',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> _writeDiagnostics(Map<String, dynamic> payload) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('push_diagnostics').insert({
        'user_id': user.id,
        'platform': 'ios',
        'payload': payload,
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[outpace][push] diagnostics write failed: $error');
      }
    }
  }

  Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,token');
    } catch (error) {
      if (kDebugMode) debugPrint('[outpace][push] token save failed: $error');
    }
  }
}
