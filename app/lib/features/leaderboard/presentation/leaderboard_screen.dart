import 'dart:async';
import 'dart:io' show Platform;

import 'package:activefriends/core/presentation/connection_aware_builder.dart';
import 'package:activefriends/core/presentation/offline_error_view.dart';
import 'package:activefriends/core/theme/app_colors.dart';
import 'package:activefriends/features/clubs/data/club_repository.dart';
import 'package:activefriends/features/leaderboard/data/leaderboard_repository.dart';
import 'package:activefriends/features/leaderboard/presentation/share_card_preview_screen.dart';
import 'package:activefriends/features/profile/presentation/profile_avatar.dart';
import 'package:activefriends/core/presentation/animated_refresh_button.dart';
import 'package:flutter/material.dart';
import 'package:activefriends/core/presentation/app_mark.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Podium-specific medal colours — not global enough for AppColors.
const _kSilver = Color(0xFFC0C0C0);
const _kBronze = Color(0xFFB07640);

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.club});

  final ClubSummary club;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _entriesFuture;
  final _repository = LeaderboardRepository(Supabase.instance.client);
  List<LeaderboardEntry>? _latestEntries;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  @override
  void didUpdateWidget(covariant LeaderboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.club.id != widget.club.id) {
      _latestEntries = null;
      _entriesFuture = _loadEntries();
    }
  }

  Future<void> _refresh() async {
    final future = _loadEntries();
    setState(() {
      _entriesFuture = future;
    });
    await _entriesFuture;
  }

  Future<List<LeaderboardEntry>> _loadEntries() async {
    final entries = await _repository
        .currentWeek(widget.club.id)
        .timeout(const Duration(seconds: 15));
    if (mounted) setState(() => _latestEntries = entries);
    return entries;
  }

  void _share() {
    if (_latestEntries == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareCardPreviewScreen(
          club: widget.club,
          entries: _latestEntries!,
        ),
      ),
    );
  }

  static String _weekLabel() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final start = '${months[monday.month - 1]} ${monday.day}';
    final end = monday.month == sunday.month
        ? '${sunday.day}'
        : '${months[sunday.month - 1]} ${sunday.day}';
    return '$start – $end';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.club.name),
        actions: [
          const Padding(
            padding: EdgeInsets.only(left: 8, right: 8, top: 7),
            child: AppMark(size: 36, showName: true),
          ),
        ],
      ),
      body: ConnectionAwareBuilder(
        onReconnect: _refresh,
        child: FutureBuilder<List<LeaderboardEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return OfflineErrorView(
              message: 'Standings could not load.\nCheck your connection and try again.',
              onRetry: _refresh,
            );
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('No activities yet this week.'));
          }
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'WEEKLY LEADERBOARD',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _weekLabel(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    AnimatedRefreshButton(onRefresh: _refresh),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _latestEntries == null ? null : _share,
                      child: Icon(
                        Platform.isIOS ? Icons.ios_share : Icons.share,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: _latestEntries == null ? 0.45 : 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Asia/Kolkata',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                if (entries.length >= 2) ...[
                  _LeaderboardPodium(entries: entries.take(3).toList()),
                  const SizedBox(height: 20),
                ],
                for (final indexedEntry
                    in entries.skip(entries.length >= 2 ? 3 : 0).indexed)
                  _LeaderboardRow(
                    rank: indexedEntry.$1 + (entries.length >= 2 ? 4 : 1),
                    entry: indexedEntry.$2,
                    isCurrentUser: indexedEntry.$2.memberId == currentUserId,
                    alternateSurface: indexedEntry.$1.isOdd,
                  ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

class _LeaderboardPodium extends StatelessWidget {
  const _LeaderboardPodium({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final order = entries.length == 2
        ? [entries[1], entries[0]]
        : [entries[1], entries[0], entries[2]];
    final ranks = entries.length == 2 ? [2, 1] : [2, 1, 3];
    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final index in List<int>.generate(
            order.length,
            (index) => index,
          ))
            Expanded(
              child: _PodiumColumn(
                entry: order[index],
                rank: ranks[index],
                height: ranks[index] == 1
                    ? 132
                    : ranks[index] == 2
                    ? 110
                    : 94,
              ),
            ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.rank,
    required this.height,
  });

  final LeaderboardEntry entry;
  final int rank;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final isWinner = rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 26),
                child: ProfileAvatar(
                  displayName: entry.displayName,
                  avatarUrl: entry.avatarUrl,
                  radius: isWinner ? 27 : 22,
                  backgroundColor: _LeaderboardRow._avatarColor(entry.memberId),
                ),
              ),
              _PodiumRankBadge(rank: rank, gold: colors.gold),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: rank == 1
                    ? const [Color(0xFFEDD880), Color(0xFF9A7010)]
                    : rank == 2
                    ? const [Color(0xFFD8D8D8), Color(0xFF686868)]
                    : const [Color(0xFFD4924A), Color(0xFF7A3E10)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(
                color: rank == 1 ? colors.gold : rank == 2 ? _kSilver : _kBronze,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${entry.points.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'points',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.distanceM > 0
                      ? '${(entry.distanceM / 1000).toStringAsFixed(2)} km'
                      : '—',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFFFE082).withValues(alpha: 0.90),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumRankBadge extends StatelessWidget {
  const _PodiumRankBadge({required this.rank, required this.gold});

  final int rank;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final color = rank == 1 ? gold : rank == 2 ? _kSilver : _kBronze;
    return Text(
      '$rank',
      style: TextStyle(
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
    required this.alternateSurface,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  final bool alternateSurface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final highlight = isCurrentUser
        ? theme.colorScheme.primaryContainer
        : alternateSurface
        ? colors.surfaceAlt
        : theme.colorScheme.surface;
    final rankColor = rank == 1 ? colors.gold : colors.textMuted;
    final isInactive = entry.points == 0;
    return Opacity(
      opacity: isInactive ? 0.45 : 1.0,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser ? theme.colorScheme.primary : colors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: theme.textTheme.titleLarge?.copyWith(
                color: rankColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ProfileAvatar(
            displayName: entry.displayName,
            avatarUrl: entry.avatarUrl,
            radius: 20,
            backgroundColor: _avatarColor(entry.memberId),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _metricLabel(entry),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points.toStringAsFixed(0)} points',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: entry.points == 0 ? colors.danger : null,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 3,
                children: entry.activityTypes
                    .map(
                      (type) => Icon(
                        _activityIcon(type),
                        size: 15,
                        color: colors.textMuted,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  static String _metricLabel(LeaderboardEntry entry) {
    final parts = <String>[];
    if (entry.distanceM > 0) {
      parts.add('${(entry.distanceM / 1000).toStringAsFixed(2)} km');
    }
    if (entry.movingTimeS > 0) {
      parts.add(
        '${entry.movingTimeS ~/ 3600}h ${(entry.movingTimeS % 3600) ~/ 60}m',
      );
    }
    if (parts.isNotEmpty) return parts.join(' · ');
    const shameLines = [
      'Still on the couch 🛋️',
      'Sleeping in 😴',
      'Netflix marathon? 🎬',
      'MIA this week 👀',
      'Ghosting the group 👻',
      'Forgot their shoes 👟',
      'Lost in the snack aisle 🍕',
      'Charging their watch ⌚',
      'Waiting for motivation 🐌',
      'Hiding from the leaderboard 🫣',
      'Training their thumbs instead 📱',
      'Stuck in traffic 🚗',
      'Blaming the weather ☁️',
      'Stretching... since Monday 🧘',
      'Perfecting their excuse 📝',
      'In a food coma 🍔',
      'Snoozed the alarm 5 times ⏰',
      'Joined the wrong club? 🤔',
      'Still lacing up 👟',
      'Warming up the bench 🪑',
      'Checking the weather app... again 🌧️',
      'Resting for next week 😇',
      'Plotting a comeback 🦸',
      'Buffering... 🔄',
      'On airplane mode ✈️',
      'Napping like a pro 💤',
      'Vibing, not moving 🎧',
      'Leg day was yesterday 🦵',
      'Ordered Uber instead 🚕',
      'Zero steps, zero regrets 🤷',
    ];
    return shameLines[entry.memberId.codeUnits.fold<int>(0, (s, c) => s + c) % shameLines.length];
  }

  static IconData _activityIcon(String type) => switch (type) {
    'run' => Icons.directions_run,
    'walk' => Icons.directions_walk,
    'cycle' => Icons.directions_bike,
    'strength' => Icons.fitness_center,
    _ => Icons.sports,
  };

  static Color _avatarColor(String id) {
    const palette = [
      Color(0xFFC2554F),
      Color(0xFF7A6AA8),
      Color(0xFF4E7FA6),
      Color(0xFF8A7340),
      Color(0xFF6B8F71),
      Color(0xFFA15E7E),
      Color(0xFF5F7E9E),
      Color(0xFF14827B),
    ];
    return palette[id.codeUnits.fold<int>(
          0,
          (sum, codeUnit) => sum + codeUnit,
        ) %
        palette.length];
  }
}

