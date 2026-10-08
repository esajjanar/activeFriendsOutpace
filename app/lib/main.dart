import 'package:activefriends/core/app.dart';
import 'package:activefriends/core/data/connectivity_service.dart';
import 'package:activefriends/core/config/supabase_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: FlutterAuthClientOptions(
        detectSessionInUriPredicate: (uri) =>
            uri.queryParameters.containsKey('code') ||
            uri.queryParameters.containsKey('access_token') ||
            (uri.queryParameters['type'] == 'recovery' &&
                uri.queryParameters.containsKey('token')) ||
            uri.fragment.contains('access_token='),
      ),
    );
  }
  await ConnectivityService.instance.initialize();
  runApp(const ActiveFriendsApp());
}
