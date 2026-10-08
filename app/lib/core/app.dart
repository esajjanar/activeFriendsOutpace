import 'package:activefriends/core/config/supabase_config.dart';
import 'package:activefriends/core/theme/app_theme.dart';
import 'package:activefriends/features/bootstrap/presentation/bootstrap_screen.dart';
import 'package:flutter/material.dart';

class ActiveFriendsApp extends StatelessWidget {
  const ActiveFriendsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OUTPACE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      scrollBehavior: const _ActiveFriendsScrollBehavior(),
      home: BootstrapScreen(configured: SupabaseConfig.isConfigured),
    );
  }
}

class _ActiveFriendsScrollBehavior extends MaterialScrollBehavior {
  const _ActiveFriendsScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
