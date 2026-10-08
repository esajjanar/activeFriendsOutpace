import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:activefriends/core/presentation/offline_error_view.dart';
import 'package:activefriends/core/theme/app_colors.dart';
import 'package:activefriends/features/auth/presentation/auth_screen.dart';
import 'package:activefriends/features/auth/presentation/reset_password_screen.dart';
import 'package:activefriends/features/home/presentation/app_shell.dart';
import 'package:activefriends/features/onboarding/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key, required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) {
    if (configured) {
      return const _AuthenticatedBootstrap();
    }

    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'OUTPACE',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Our club. Our activity. Our pace.',
                style: textTheme.bodyLarge?.copyWith(color: colors.textMuted),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthenticatedBootstrap extends StatefulWidget {
  const _AuthenticatedBootstrap();

  @override
  State<_AuthenticatedBootstrap> createState() =>
      _AuthenticatedBootstrapState();
}

class _AuthenticatedBootstrapState extends State<_AuthenticatedBootstrap>
    with WidgetsBindingObserver {
  late final StreamSubscription<AuthState> _authSubscription;
  var _isRecoveringPassword = false;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    // Supabase/app_links owns auth callback deep links. Return true here so that
    // MaterialApp's state never tries to push /callback?... as a named route.
    if (routeInformation.uri.path == '/callback') return true;
    return super.didPushRouteInformation(routeInformation);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (!mounted) return;
      setState(() {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _isRecoveringPassword = true;
        } else if (state.event == AuthChangeEvent.signedOut) {
          _isRecoveringPassword = false;
        }
      });
    });
    unawaited(_handleInitialAuthLink());
  }

  Future<void> _handleInitialAuthLink() async {
    final uri = await AppLinks().getInitialLink();
    if (!mounted || uri == null) return;
    final hasAuthParameters =
        uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('access_token') ||
        (uri.queryParameters['type'] == 'recovery' &&
            uri.queryParameters.containsKey('token')) ||
        uri.fragment.contains('access_token=');
    if (!hasAuthParameters) return;
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      if (mounted) setState(() => _isRecoveringPassword = true);
    } on AuthException {
      // Errors are surfaced through the auth state stream.
    } catch (_) {
      // Ignore unexpected errors from stale or malformed links.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecoveringPassword) return const ResetPasswordScreen();
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const AuthScreen();
    return _ProfileBootstrap(userId: session.user.id);
  }
}

class _ProfileBootstrap extends StatefulWidget {
  const _ProfileBootstrap({required this.userId});

  final String userId;

  @override
  State<_ProfileBootstrap> createState() => _ProfileBootstrapState();
}

class _ProfileBootstrapState extends State<_ProfileBootstrap> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() => Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', widget.userId)
      .maybeSingle()
      .timeout(const Duration(seconds: 15));

  void _retry() {
    final future = _loadProfile();
    setState(() { _profileFuture = future; });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: OfflineErrorView(
              message: 'Could not load your profile.\nCheck your connection and try again.',
              onRetry: _retry,
            ),
          );
        }
        if (snapshot.data == null) {
          return ProfileScreen(onComplete: _retry);
        }
        return const AppShell();
      },
    );
  }
}
