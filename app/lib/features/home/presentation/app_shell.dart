import 'package:activefriends/core/presentation/connection_aware_builder.dart';
import 'package:activefriends/core/presentation/offline_error_view.dart';
import 'package:activefriends/data/services/active_club_store.dart';
import 'package:activefriends/data/local/app_database.dart';
import 'package:activefriends/core/theme/app_colors.dart';
import 'package:activefriends/features/clubs/data/club_repository.dart';
import 'package:activefriends/features/clubs/presentation/clubs_screen.dart';
import 'package:activefriends/features/feed/data/activity_feed_repository.dart';
import 'package:activefriends/features/feed/presentation/activity_detail_screen.dart';
import 'package:activefriends/features/feed/presentation/activity_feed_screen.dart';
import 'package:activefriends/features/leaderboard/data/leaderboard_repository.dart';
import 'package:activefriends/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:activefriends/features/leaderboard/presentation/share_card_preview_screen.dart';
import 'package:activefriends/features/notifications/data/notification_repository.dart';
import 'package:activefriends/features/notifications/data/push_notification_service.dart';
import 'dart:convert';
import 'package:activefriends/features/tracking/presentation/manual_activity_screen.dart';
import 'package:activefriends/features/tracking/presentation/tracking_screen.dart';
import 'package:activefriends/core/presentation/date_time_format.dart';
import 'package:activefriends/features/tracking/data/tracking_local_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  final _database = AppDatabase.shared;
  late final _trackingLocalRepository = TrackingLocalRepository(_database);
  final _clubs = ClubRepository(Supabase.instance.client);
  final _notifications = NotificationRepository(Supabase.instance.client);
  late Future<ClubSummary?> _activeClubFuture;
  final _feedKey = GlobalKey<ActivityFeedScreenState>();
  var _index = 0;
  var _isForeground = true;
  var _recoveryChecked = false;
  var _profileName = 'Me';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeClubFuture = _loadActiveClub();
    _loadProfileName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForRecovery();
      _initPush();
    });
  }

  Future<void> _loadProfileName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle();
    final displayName = profile?['display_name'] as String?;
    final fallback = user.email?.split('@').first.replaceAll('.', ' ');
    final name = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : fallback?.trim();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _profileName = _compactProfileName(name));
    }
  }

  static String _compactProfileName(String name) =>
      name.length <= 12 ? name : '${name.substring(0, 11)}…';

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkForRecovery() async {
    if (_recoveryChecked) return;
    _recoveryChecked = true;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final session = await _trackingLocalRepository.findUnfinishedSession(
      ownerUserId: currentUserId,
    );
    if (!mounted || session == null) return;
    final recoveryAction = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Unfinished activity found'),
        content: Text(
          '${_typeLabel(session.activityType)} from ${_dateLabel(session.startedAt)} is saved on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(0),
            child: const Text('Discard'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(2),
            child: const Text('Save'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(1),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (recoveryAction == 1 || recoveryAction == 2) {
      final navigator = Navigator.of(context);
      final savedActivityId = await navigator.push<String>(
        MaterialPageRoute(
          builder: (_) => TrackingScreen(recoverySession: session),
        ),
      );
      if (!mounted || savedActivityId == null) return;
      await _feedKey.currentState?.refreshUntilContains(savedActivityId);
      if (!mounted) return;
      setState(() => _index = 1);
    } else if (recoveryAction == 0) {
      await _trackingLocalRepository.deleteSession(session.id);
    }
  }

  Future<void> _initPush() async {
    final push = PushNotificationService.instance;
    push.onActivityTapped = _handleNotificationTap;
    push.onWeeklyReminderTapped = _handleWeeklyReminderTap;
    await push.initialize();
    final initial = await push.getInitialMessage();
    push.routeInitialMessage(initial);
  }

  Future<void> _handleNotificationTap(String activityId) async {
    final clubFuture = _activeClubFuture;
    final club = await clubFuture;
    if (!mounted || club == null) return;
    setState(() => _index = 1);
    final repository = ActivityFeedRepository(Supabase.instance.client);
    final activities = await repository.load(clubId: club.id, mine: false);
    final activity = activities.where((a) => a.id == activityId).firstOrNull;
    if (!mounted || activity == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activity: activity, club: club),
      ),
    );
  }

  Future<void> _handleWeeklyReminderTap(String clubId) async {
    final repository = LeaderboardRepository(Supabase.instance.client);
    final clubs = await _clubs.listMine();
    final club = clubs.where((c) => c.id == clubId).firstOrNull;
    if (club == null || !mounted) return;
    final entries = await repository.currentWeek(clubId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareCardPreviewScreen(club: club, entries: entries),
      ),
    );
  }

  static String _typeLabel(String type) => switch (type) {
    'run' => 'Run',
    'walk' => 'Walk',
    'cycle' => 'Cycle',
    _ => 'Activity',
  };

  static String _dateLabel(DateTime dateTime) => formatShortDateTime(dateTime);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (_isForeground != isForeground && mounted) {
      setState(() => _isForeground = isForeground);
    }
  }

  Future<ClubSummary?> _loadActiveClub() async {
    final clubs = await _clubs.listMine().timeout(const Duration(seconds: 15));
    if (clubs.isEmpty) {
      return null;
    }
    final storedClubId = await ActiveClubStore.read();
    final activeClub =
        clubs.where((club) => club.id == storedClubId).firstOrNull ??
        clubs.first;
    if (activeClub.id != storedClubId) {
      await ActiveClubStore.write(activeClub.id);
    }
    return activeClub;
  }

  Future<void> _reloadActiveClub() async {
    final future = _loadActiveClub();
    setState(() {
      _activeClubFuture = future;
    });
    await _activeClubFuture;
  }

  void _showAccountActions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dlg) => AlertDialog(
                    title: const Text('Sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dlg).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dlg).pop(true),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await Supabase.instance.client.auth.signOut();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Push debug info'),
              subtitle: const Text('Tap to view iOS push diagnostics'),
              onTap: () {
                Navigator.of(ctx).pop();
                final diag = PushNotificationService.instance.lastDiagnostics;
                final text = diag != null
                    ? const JsonEncoder.withIndent('  ').convert(diag)
                    : 'No diagnostics yet — relaunch the app on iOS.';
                showDialog<void>(
                  context: context,
                  builder: (dlg) => AlertDialog(
                    title: const Text('Push diagnostics'),
                    content: SingleChildScrollView(
                      child: SelectableText(
                        text,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dlg).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Delete account',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text(
                'Permanently deletes your account and all data',
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dlg) => AlertDialog(
                    title: const Text('Delete account?'),
                    content: const Text(
                      'This will permanently delete your account, all your activities, and remove you from all clubs. This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dlg).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.of(dlg).pop(true),
                        child: const Text('Delete permanently'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  try {
                    await Supabase.instance.client.functions.invoke(
                      'delete-account',
                    );
                    await Supabase.instance.client.auth.signOut(
                      scope: SignOutScope.local,
                    );
                  } on FunctionException catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Account deletion failed. Please try again.',
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    // ignore unexpected errors
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionAwareBuilder(
      onReconnect: _reloadActiveClub,
      child: FutureBuilder<ClubSummary?>(
      future: _activeClubFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: OfflineErrorView(
              message: 'Could not load your profile.',
              onRetry: _reloadActiveClub,
            ),
          );
        }
        final activeClub = snapshot.data;
        if (activeClub == null) {
          return Scaffold(
            body: ClubsScreen(onActiveClubChanged: (_) => _reloadActiveClub()),
            bottomNavigationBar: _AppNavigation(
              selectedIndex: 2,
              unreadCount: 0,
              profileName: _profileName,
              onDestinationSelected: (_) {},
              onSignOut: () => _showAccountActions(),
            ),
          );
        }
        final pages = [
          LeaderboardScreen(club: activeClub),
          ActivityFeedScreen(key: _feedKey, club: activeClub),
          ClubsScreen(onActiveClubChanged: (_) => _reloadActiveClub()),
        ];
        return StreamBuilder<int>(
          stream: _isForeground ? _notifications.watchUnreadCount() : null,
          initialData: 0,
          builder: (context, notifications) => Scaffold(
            body: IndexedStack(index: _index, children: pages),
            floatingActionButton: _SplitChevronTrackButton(
              onTap: () async {
                final choice = await showModalBottomSheet<String>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.gps_fixed),
                          title: const Text('Track with GPS'),
                          subtitle: const Text(
                            'Live tracking for run, walk or cycle',
                          ),
                          onTap: () => Navigator.of(ctx).pop('gps'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: const Text('Log manually'),
                          subtitle: const Text(
                            'Strength, past activities, no GPS needed',
                          ),
                          onTap: () => Navigator.of(ctx).pop('manual'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
                if (!mounted) return;
                String? savedActivityId;
                if (choice == 'gps') {
                  savedActivityId = await Navigator.of(context).push<String>(
                    MaterialPageRoute(builder: (_) => const TrackingScreen()),
                  );
                } else if (choice == 'manual') {
                  savedActivityId = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const ManualActivityScreen(),
                    ),
                  );
                }
                if (savedActivityId != null && mounted) {
                  await _feedKey.currentState?.refreshUntilContains(
                    savedActivityId,
                  );
                  if (mounted) setState(() => _index = 1);
                }
              },
            ),
            floatingActionButtonLocation: const _TrackButtonLocation(),
            bottomNavigationBar: _AppNavigation(
              selectedIndex: _index,
              unreadCount: notifications.data ?? 0,
              profileName: _profileName,
              onDestinationSelected: (index) => setState(() => _index = index),
              onSignOut: () => _showAccountActions(),
            ),
          ),
        );
      },
    ),
    );
  }
}

class _AppNavigation extends StatelessWidget {
  const _AppNavigation({
    required this.selectedIndex,
    required this.unreadCount,
    required this.profileName,
    required this.onDestinationSelected,
    required this.onSignOut,
  });

  final int selectedIndex;
  final int unreadCount;
  final String profileName;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: 84 + bottomInset,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  label: 'Leaderboard',
                  icon: Icons.leaderboard_outlined,
                  selectedIcon: Icons.leaderboard,
                  selected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Feed',
                  icon: Icons.dynamic_feed_outlined,
                  selectedIcon: Icons.dynamic_feed,
                  selected: selectedIndex == 1,
                  badge: unreadCount,
                  onTap: () => onDestinationSelected(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: profileName,
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  selected: selectedIndex == 2,
                  onTap: () => onDestinationSelected(2),
                ),
              ),
              SizedBox(
                width: 48,
                child: Semantics(
                  button: true,
                  label: 'Sign out',
                  child: InkWell(
                    onTap: onSignOut,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 22, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.extension<AppColors>()!.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '$label, $badge unread' : label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: Icon(selected ? selectedIcon : icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitChevronTrackButton extends StatelessWidget {
  const _SplitChevronTrackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Semantics(
      button: true,
      label: 'Track activity',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.26),
                width: 1.5,
              ),
            ),
            child: CustomPaint(
              painter: _SplitChevronPainter(
                coral: colors.accent,
                teal: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackButtonLocation extends FloatingActionButtonLocation {
  const _TrackButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    const size = 62.0;
    return Offset(
      (scaffoldGeometry.scaffoldSize.width - size) / 2,
      scaffoldGeometry.contentBottom - size,
    );
  }
}

class _SplitChevronPainter extends CustomPainter {
  const _SplitChevronPainter({required this.coral, required this.teal});

  final Color coral;
  final Color teal;

  @override
  void paint(Canvas canvas, Size size) {
    _drawChevron(canvas, Offset(size.width * 0.38, size.height * 0.5), coral);
    _drawChevron(canvas, Offset(size.width * 0.62, size.height * 0.5), teal);
  }

  void _drawChevron(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(center.dx - 7, center.dy - 11)
      ..lineTo(center.dx + 5, center.dy)
      ..lineTo(center.dx - 7, center.dy + 11);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SplitChevronPainter oldDelegate) =>
      oldDelegate.coral != coral || oldDelegate.teal != teal;
}
