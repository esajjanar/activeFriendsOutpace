import 'dart:async';

import 'package:activefriends/core/presentation/connection_aware_builder.dart';
import 'package:activefriends/core/presentation/offline_error_view.dart';
import 'package:activefriends/core/theme/app_colors.dart';
import 'package:activefriends/features/clubs/data/club_repository.dart';
import 'package:activefriends/features/feed/data/activity_detail_repository.dart';
import 'package:activefriends/features/feed/data/activity_feed_repository.dart';
import 'package:activefriends/core/presentation/date_time_format.dart';
import 'package:activefriends/features/feed/presentation/activity_detail_screen.dart';
import 'package:activefriends/features/feed/presentation/activity_route_thumbnail.dart';

import 'package:activefriends/features/profile/presentation/profile_avatar.dart';
import 'package:activefriends/core/presentation/animated_refresh_button.dart';
import 'package:activefriends/core/presentation/app_mark.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key, required this.club});

  final ClubSummary club;

  @override
  State<ActivityFeedScreen> createState() => ActivityFeedScreenState();
}

class ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final _repository = ActivityFeedRepository(Supabase.instance.client);
  final _searchController = TextEditingController();
  late Future<List<FeedActivity>> _activitiesFuture;
  var _mine = false;
  var _searchQuery = '';
  var _isLoadingMore = false;
  var _hasMore = true;
  Timer? _searchDebounce;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _load();
  }

  @override
  void didUpdateWidget(covariant ActivityFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.club.id != widget.club.id) {
      _resetPaging();
      _activitiesFuture = _load();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<FeedActivity>> _load({int pageOffset = 0}) async {
    Object? lastError;
    StackTrace? lastStackTrace;
    const maxAttempts = 5;
    const timeout = Duration(seconds: 15);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final activities = await _repository.load(
          clubId: widget.club.id,
          mine: _mine,
          searchQuery: _searchQuery,
          pageSize: _pageSize,
          pageOffset: pageOffset,
        ).timeout(timeout);
        if (pageOffset == 0) _hasMore = activities.length == _pageSize;
        return activities;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 500 * (1 << attempt)),
          );
        }
      }
    }
    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  Future<void> _refresh() async {
    _resetPaging();
    final future = _load();
    setState(() {
      _activitiesFuture = future;
    });
    await _activitiesFuture;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final currentActivities = await _activitiesFuture;
    if (!mounted) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = await _load(pageOffset: currentActivities.length);
      if (!mounted) return;
      setState(() {
        _activitiesFuture = Future.value([...currentActivities, ...nextPage]);
        _hasMore = nextPage.length == _pageSize;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load more activities: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _resetPaging() {
    _isLoadingMore = false;
    _hasMore = true;
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _searchDebounce?.cancel();
    setState(() {});
    if (value.trim().isEmpty) {
      _resetPaging();
      final future = _load();
      setState(() => _activitiesFuture = future);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _resetPaging();
      final future = _load();
      setState(() => _activitiesFuture = future);
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  Future<void> refresh() => _refresh();

  Future<void> refreshAfterActivitySave() => refreshWithRetries();

  Future<void> refreshWithRetries() async {
    await _refresh();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) await _refresh();
  }

  Future<void> refreshUntilContains(String activityId) async {
    const delays = [
      Duration.zero,
      Duration(milliseconds: 300),
      Duration(milliseconds: 700),
      Duration(milliseconds: 1200),
    ];
    for (final delay in delays) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      await _refresh();
      if (!mounted) return;
      final activities = await _activitiesFuture;
      if (activities.any((activity) => activity.id == activityId)) return;
    }
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
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: _buildSearchField(),
          ),
          Expanded(
            child: FutureBuilder<List<FeedActivity>>(
              future: _activitiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return OfflineErrorView(
                    message: 'Activities could not load.\nCheck your connection and try again.',
                    onRetry: _refresh,
                  );
                }
                final activities = snapshot.data ?? [];
                final hasFooter = activities.isNotEmpty && _hasMore;
                final itemCount = 1 +
                    (activities.isEmpty ? 1 : activities.length) +
                    (hasFooter ? 1 : 0);
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                    cacheExtent: 500,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      // — Header
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  'ACTIVITY FEED',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Recent activity',
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                AnimatedRefreshButton(onRefresh: _refresh),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(value: false, label: Text('All')),
                                  ButtonSegment(value: true, label: Text('Mine')),
                                ],
                                selected: {_mine},
                                onSelectionChanged: (selection) {
                                  setState(() {
                                    _mine = selection.first;
                                    _resetPaging();
                                    _activitiesFuture = _load();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }
                      // — Empty state
                      if (activities.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Center(
                            child: Text(
                              _searchQuery.trim().isEmpty
                                  ? 'No activities yet.'
                                  : 'No matching activities.',
                            ),
                          ),
                        );
                      }
                      // — Activity cards
                      final cardIndex = index - 1;
                      if (cardIndex < activities.length) {
                        final activity = activities[cardIndex];
                        return _FeedCard(
                          activity: activity,
                          alternateSurface: cardIndex.isOdd,
                          onTap: () async {
                            final result = await Navigator.of(context)
                                .push<ActivityDetailResult>(
                                  MaterialPageRoute(
                                    builder: (_) => ActivityDetailScreen(
                                      activity: activity,
                                      club: widget.club,
                                    ),
                                  ),
                                );
                            if (result != null && mounted) {
                              if (result.deleted) {
                                await refresh();
                                return;
                              }
                              _updateActivityCounts(result);
                              await refreshWithRetries();
                            }
                          },
                        );
                      }
                      // — Load more
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingMore ? null : _loadMore,
                          icon: _isLoadingMore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(
                            _isLoadingMore
                                ? 'Loading activities...'
                                : 'Load more',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search people, types, or notes',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: _clearSearch,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }

  void _updateActivityCounts(ActivityDetailResult result) {
    final current = _activitiesFuture;
    current.then((activities) {
      if (!mounted) return;
      setState(() {
        _activitiesFuture = Future.value(
          activities
              .map(
                (activity) => activity.id == result.activityId
                    ? activity.copyWith(
                        reactionCount: result.reactionCount,
                        commentCount: result.commentCount,
                      )
                    : activity,
              )
              .toList(),
        );
      });
    });
  }
}

class _FeedCard extends StatefulWidget {
  const _FeedCard({
    required this.activity,
    required this.alternateSurface,
    required this.onTap,
  });

  final FeedActivity activity;
  final bool alternateSurface;
  final VoidCallback onTap;

  @override
  State<_FeedCard> createState() => _FeedCardState();

  static String _timeLabel(DateTime dateTime) => formatShortDateTime(dateTime);

  static String _typeLabel(String type) => switch (type) {
    'run' => 'Run',
    'walk' => 'Walk',
    'cycle' => 'Cycle',
    'strength' => 'Strength',
    _ => 'Other',
  };

  static IconData _typeIcon(String type) => switch (type) {
    'run' => Icons.directions_run,
    'walk' => Icons.directions_walk,
    'cycle' => Icons.directions_bike,
    'strength' => Icons.fitness_center,
    _ => Icons.sports,
  };

  static Color _activityColor(String type) => switch (type) {
    'run' => const Color(0xFFE07A62),
    'walk' => const Color(0xFF14827B),
    'cycle' => const Color(0xFF4E7FA6),
    'strength' => const Color(0xFFB58A2D),
    _ => const Color(0xFF7A6AA8),
  };

  static String _sourceLabel(String source) => switch (source) {
    'health_connect' => 'Health Connect',
    'healthkit' => 'Apple Health',
    'phone_gps' => 'Phone GPS',
    _ => 'Manual',
  };

  static IconData _sourceIcon(String source) => switch (source) {
    'health_connect' => Icons.watch,
    'healthkit' => Icons.watch,
    'phone_gps' => Icons.gps_fixed,
    _ => Icons.edit_note,
  };

  static Color _sourceColor(String source) => switch (source) {
    'health_connect' => const Color(0xFF4CAF50),
    'healthkit' => const Color(0xFFFF6B35),
    'phone_gps' => const Color(0xFF2196F3),
    _ => const Color(0xFF9E9E9E),
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

class _FeedCardState extends State<_FeedCard> {
  final _detailRepo = ActivityDetailRepository(Supabase.instance.client);
  late int _reactionCount;
  // _isLiked starts false — feed RPC doesn't return has_reacted yet.
  // Within a session the optimistic toggle is accurate.
  bool _isLiked = false;
  bool _liking = false;

  @override
  void initState() {
    super.initState();
    _reactionCount = widget.activity.reactionCount;
    _isLiked = widget.activity.hasReacted;
  }

  bool get _isOwnActivity =>
      widget.activity.memberId ==
      Supabase.instance.client.auth.currentUser?.id;

  /// Reactors to display — filters out the current user optimistically
  /// when they just unliked, so the avatar disappears without a full refresh.
  List<ReactorInfo> get _displayReactors {
    if (!_isLiked && widget.activity.hasReacted) {
      final me = Supabase.instance.client.auth.currentUser?.id;
      if (me != null) {
        return widget.activity.topReactors
            .where((r) => r.userId != me)
            .toList();
      }
    }
    return widget.activity.topReactors;
  }

  Future<void> _toggleLike() async {
    if (_liking || _isOwnActivity) return;
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _reactionCount += _isLiked ? 1 : -1;
      _liking = true;
    });
    try {
      if (_isLiked) {
        await _detailRepo.setReaction(
          activityId: widget.activity.id,
          reaction: '❤️',
        );
      } else {
        await _detailRepo.removeReaction(widget.activity.id);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _reactionCount += wasLiked ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final activityColor = _FeedCard._activityColor(widget.activity.type);
    const heartRed = Color(0xFFE53935);

    return Card(
      color: widget.alternateSurface
          ? colors.surfaceAlt
          : theme.colorScheme.surface,
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: activityColor, width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar row ──────────────────────────────────────────────
              Row(
                children: [
                  ProfileAvatar(
                    displayName: widget.activity.displayName,
                    avatarUrl: widget.activity.avatarUrl,
                    radius: 27,
                    backgroundColor:
                        _FeedCard._avatarColor(widget.activity.memberId),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.activity.displayName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    _FeedCard._timeLabel(widget.activity.startedAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ── Activity type + heart + points ───────────────────────────
              Row(
                children: [
                  Icon(
                    _FeedCard._typeIcon(widget.activity.type),
                    color: activityColor,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _FeedCard._typeLabel(widget.activity.type),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        color: activityColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Heart — tappable for others, display-only for own
                  GestureDetector(
                    onTap: (_isOwnActivity || _liking) ? null : _toggleLike,
                    child: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 22,
                      color: _isOwnActivity ? colors.textMuted : heartRed,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_displayReactors.isNotEmpty) ...[
                    _StackedAvatars(
                      reactors: _displayReactors,
                      borderColor: widget.alternateSurface
                          ? colors.surfaceAlt
                          : theme.colorScheme.surface,
                    ),
                    const SizedBox(width: 5),
                  ],
                  if (_reactionCount > 4) ...[
                    Text(
                      '…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _isOwnActivity ? colors.textMuted : heartRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '$_reactionCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isOwnActivity ? colors.textMuted : heartRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.activity.excluded
                        ? 'NOT SCORED'
                        : '${widget.activity.points.toStringAsFixed(0)} points',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      color: widget.activity.excluded
                          ? colors.danger
                          : colors.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ── Metrics ─────────────────────────────────────────────────
              _MetricsRow(
                activity: widget.activity,
                activityColor: activityColor,
              ),
              if (widget.activity.notes != null &&
                  widget.activity.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(widget.activity.notes!,
                    style: theme.textTheme.bodyMedium),
              ],
              if (widget.activity.routeVisible)
                ActivityRouteThumbnail(
                  activityId: widget.activity.id,
                  lightweight: true,
                ),
              const Divider(height: 28),
              // ── Footer — comment count + source ──────────────────────────
              Row(
                children: [
                  Icon(
                    widget.activity.commentCount > 0
                        ? Icons.chat_bubble
                        : Icons.chat_bubble_outline,
                    size: 18,
                    color: _MetricsRow._distanceColor,
                  ),
                  const SizedBox(width: 5),
                  if (widget.activity.topCommenters.isNotEmpty) ...[
                    _StackedAvatars(
                      reactors: widget.activity.topCommenters,
                      borderColor: widget.alternateSurface
                          ? colors.surfaceAlt
                          : theme.colorScheme.surface,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (widget.activity.commentCount > 4) ...[
                    Text(
                      '…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${widget.activity.commentCount}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _FeedCard._sourceColor(widget.activity.source)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _FeedCard._sourceIcon(widget.activity.source),
                          size: 13,
                          color: _FeedCard._sourceColor(widget.activity.source),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _FeedCard._sourceLabel(widget.activity.source),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _FeedCard._sourceColor(widget.activity.source),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars({required this.reactors, required this.borderColor});

  final List<ReactorInfo> reactors;
  final Color borderColor;

  static const double _radius = 10;
  static const double _border = 1.5;
  static const double _step = 13; // centre-to-centre step between avatars

  @override
  Widget build(BuildContext context) {
    final count = reactors.length;
    // Each avatar's rendered diameter includes the border on both sides.
    final diameter = (_radius + _border) * 2;
    final totalWidth = diameter + (count - 1) * _step;
    return SizedBox(
      width: totalWidth,
      height: diameter,
      child: Stack(
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              left: i * _step,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: ProfileAvatar(
                  displayName: reactors[i].displayName,
                  avatarUrl: reactors[i].avatarUrl,
                  radius: _radius,
                  backgroundColor: _FeedCard._avatarColor(reactors[i].userId),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.activity, required this.activityColor});

  final FeedActivity activity;
  final Color activityColor; // unused for metric colours but kept for API compat

  // Each stat has its own fixed semantic colour.
  static const _distanceColor = Color(0xFF5BC9BC); // teal
  static const _timeColor     = Color(0xFFE2B93B); // gold
  static const _speedColor    = Color(0xFF6EA8D8); // steel blue

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );

    final items = <Widget>[];

    if (activity.distanceM != null) {
      items.add(_StatItem(
        icon: Icons.route,
        label: '${(activity.distanceM! / 1000).toStringAsFixed(2)} km',
        color: _distanceColor,
        style: valueStyle,
      ));
    }
    // Prefer moving time; fall back to elapsed time for health_connect imports
    // where moving time is unavailable (Health Connect doesn't expose it).
    final displayTimeS = activity.movingTimeS ?? activity.elapsedS;
    final timeLabel = activity.movingTimeS != null ? null : 'elapsed';
    if (displayTimeS != null) {
      items.add(_StatItem(
        icon: Icons.timer_outlined,
        label: formatDurationSeconds(displayTimeS),
        color: _timeColor,
        style: valueStyle,
      ));
    }
    if (activity.distanceM != null && displayTimeS != null && displayTimeS > 0) {
      final hours = displayTimeS / 3600;
      items.add(_StatItem(
        icon: Icons.speed,
        label: '${(activity.distanceM! / 1000 / hours).toStringAsFixed(1)} km/h',
        color: _speedColor,
        style: valueStyle,
      ));
    }

    if (items.isEmpty) {
      return Text('Activity logged', style: valueStyle);
    }

    // Each stat gets an equal slice of the full card width.
    return Row(
      children: items.map((item) => Expanded(child: Center(child: item))).toList(),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.color,
    this.style,
  });

  final IconData icon;
  final String label;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
