import 'dart:async';

import 'package:activefriends/core/presentation/connection_aware_builder.dart';
import 'package:activefriends/core/presentation/offline_error_view.dart';
import 'package:activefriends/core/theme/app_colors.dart';
import 'package:activefriends/features/clubs/data/club_repository.dart';
import 'package:activefriends/features/feed/data/activity_detail_repository.dart';
import 'package:activefriends/features/feed/data/activity_feed_repository.dart';
import 'package:activefriends/core/presentation/date_time_format.dart';
import 'package:activefriends/features/feed/presentation/activity_route_thumbnail.dart';
import 'package:activefriends/features/profile/presentation/profile_avatar.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({
    super.key,
    required this.activity,
    required this.club,
  });

  final FeedActivity activity;
  final ClubSummary club;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class ActivityDetailResult {
  const ActivityDetailResult({
    required this.activityId,
    required this.reactionCount,
    required this.commentCount,
    this.deleted = false,
  });

  final String activityId;
  final int reactionCount;
  final int commentCount;
  final bool deleted;
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final _repository = ActivityDetailRepository(Supabase.instance.client);
  final _commentController = TextEditingController();
  late Future<ActivityDetail> _detailFuture;
  var _isSaving = false;
  var _hasChanged = false;
  var _reactionCount = 0;
  var _commentCount = 0;
  var _countsLoaded = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _load();
    _repository.markNotificationsSeen(widget.activity.id).ignore();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<ActivityDetail> _load() async {
    Object? lastError;
    const maxAttempts = 5;
    const timeout = Duration(seconds: 15);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await _repository
            .load(
              activityId: widget.activity.id,
              clubId: widget.club.id,
            )
            .timeout(timeout);
      } catch (error) {
        lastError = error;
        if (attempt < maxAttempts - 1) {
          // Exponential backoff: 500ms, 1s, 2s, 4s
          await Future<void>.delayed(
            Duration(milliseconds: 500 * (1 << attempt)),
          );
        }
      }
    }
    throw lastError!;
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() {
      _detailFuture = future;
    });
    final detail = await future;
    if (!mounted) return;
    setState(() {
      _reactionCount = detail.reactions.length;
      _commentCount = detail.comments.length;
      _countsLoaded = true;
    });
  }

  ActivityDetailResult _result() => ActivityDetailResult(
    activityId: widget.activity.id,
    reactionCount: _countsLoaded
        ? _reactionCount
        : widget.activity.reactionCount,
    commentCount: _countsLoaded ? _commentCount : widget.activity.commentCount,
  );

  Future<void> _react(String reaction, String? currentReaction) async {
    if (widget.activity.memberId ==
        Supabase.instance.client.auth.currentUser?.id) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (reaction == currentReaction) {
        await _repository.removeReaction(widget.activity.id);
      } else {
        await _repository.setReaction(
          activityId: widget.activity.id,
          reaction: reaction,
        );
      }
      await _reload();
      _hasChanged = true;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _comment() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _repository.addComment(
        activityId: widget.activity.id,
        body: _commentController.text,
      );
      _commentController.clear();
      await _reload();
      _hasChanged = true;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteActivity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete activity?'),
        content: const Text(
          'This will permanently remove the activity, route, reactions, and comments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await _repository.deleteActivity(widget.activity.id);
      if (!mounted) return;
      Navigator.of(context).pop(
        ActivityDetailResult(
          activityId: widget.activity.id,
          reactionCount: 0,
          commentCount: 0,
          deleted: true,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Could not delete activity'),
          content: Text(_deleteErrorMessage(error)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  static String _deleteErrorMessage(Object error) {
    if (error is ActivityDeleteException) return error.message;
    return 'The activity was not deleted. Check your connection and try again.';
  }

  Widget _buildReactorAvatars(
    List<Map<String, dynamic>> reactions,
    BuildContext context,
  ) {
    final top4 = reactions.take(4).toList();
    const radius = 12.0;
    const border = 1.5;
    const step = 14.0;
    final diameter = (radius + border) * 2;
    final width = diameter + (top4.length - 1) * step;
    final ringColor = Theme.of(context).colorScheme.surface;
    return SizedBox(
      width: width,
      height: diameter,
      child: Stack(
        children: [
          for (int i = 0; i < top4.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: border),
                ),
                child: ProfileAvatar(
                  displayName:
                      top4[i]['display_name'] as String? ?? '?',
                  avatarUrl: top4[i]['avatar_url'] as String?,
                  radius: radius,
                  backgroundColor:
                      _avatarColor(top4[i]['user_id'] as String),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Color _avatarColor(String id) {
    const palette = [
      Color(0xFFC2554F), Color(0xFF7A6AA8), Color(0xFF4E7FA6),
      Color(0xFF8A7340), Color(0xFF6B8F71), Color(0xFFA15E7E),
      Color(0xFF5F7E9E), Color(0xFF14827B),
    ];
    return palette[
        id.codeUnits.fold<int>(0, (s, c) => s + c) % palette.length];
  }

  static String _loadErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('activity not found')) {
      return 'This activity is no longer available.';
    }
    if (message.contains('cannot view this activity')) {
      return 'You no longer have access to this activity.';
    }
    return 'Activity could not load. Check your connection and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final canDelete =
        widget.activity.memberId == currentUserId ||
        widget.club.role == 'admin';
    return PopScope<ActivityDetailResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_hasChanged ? _result() : null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () =>
                Navigator.of(context).pop(_hasChanged ? _result() : null),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            if (canDelete)
              IconButton(
                tooltip: 'Delete activity',
                onPressed: _isSaving ? null : _deleteActivity,
                color: colors.danger,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: ConnectionAwareBuilder(
          onReconnect: _reload,
          child: FutureBuilder<ActivityDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return OfflineErrorView(
                message: _loadErrorMessage(snapshot.error!),
                onRetry: _isSaving ? null : _reload,
              );
            }
            final detail = snapshot.data!;
            final activity = detail.activity;
            final isOwner = activity['member_id'] == currentUserId;
            final currentReaction = detail.reactions
                .where((reaction) => reaction['user_id'] == currentUserId)
                .map((reaction) => reaction['reaction'] as String)
                .firstOrNull;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                28 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                Text(
                  activity['display_name'] as String,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _typeLabel(activity['type'] as String),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (!isOwner) ...[
                      GestureDetector(
                        onTap: _isSaving
                            ? null
                            : () => _react('heart', currentReaction),
                        child: Icon(
                          currentReaction == 'heart'
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: const Color(0xFFE53935),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (detail.reactions.isNotEmpty) ...[
                      _buildReactorAvatars(detail.reactions, context),
                      const SizedBox(width: 4),
                    ],
                    if (detail.reactions.length > 4) ...[
                      Text(
                        '…',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (detail.reactions.isNotEmpty)
                      Text(
                        '${detail.reactions.length}',
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _dateLabel(
                    DateTime.parse(activity['started_at'] as String).toLocal(),
                  ),
                  style: TextStyle(color: colors.textMuted),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.7,
                      children: [
                        _Metric(
                          label: 'Points',
                          value: activity['excluded'] as bool
                              ? 'Not scored'
                              : '${(activity['points'] as num).toStringAsFixed(0)} points',
                          tone: _MetricTone.primary,
                        ),
                        if (activity['distance_m'] != null)
                          _Metric(
                            label: 'Distance',
                            value:
                                '${((activity['distance_m'] as num) / 1000).toStringAsFixed(1)} km',
                            tone: _MetricTone.neutral,
                          ),
                        if (activity['moving_time_s'] != null)
                          _Metric(
                            label: 'Moving time',
                            value: formatDurationSeconds(
                                (activity['moving_time_s'] as num).toInt()),
                            tone: _MetricTone.neutral,
                          ),
                        if (activity['elapsed_s'] != null)
                          _Metric(
                            label: 'Elapsed time',
                            value: formatDurationSeconds(
                                (activity['elapsed_s'] as num).toInt()),
                            tone: _MetricTone.neutral,
                          ),
                        if (_hasDistanceAndTime(activity))
                          _Metric(
                            label: 'Pace',
                            value: _paceLabel(activity),
                            tone: _MetricTone.performance,
                          ),
                        if (_trackSummary(activity)['volume_kg'] != null)
                          _Metric(
                            label: 'Volume',
                            value:
                                '${((_trackSummary(activity)['volume_kg'] as num).toDouble()).round()} kg',
                            tone: _MetricTone.performance,
                          ),
                        if (_trackSummary(activity)['sets'] != null)
                          _Metric(
                            label: 'Sets',
                            value:
                                '${(_trackSummary(activity)['sets'] as num).toInt()}',
                            tone: _MetricTone.performance,
                          ),
                        if (_trackSummary(activity)['max_speed_kmh'] != null)
                          _Metric(
                            label: 'Max speed',
                            value:
                                '${((_trackSummary(activity)['max_speed_kmh'] as num).toDouble()).toStringAsFixed(1)} km/h',
                            tone: _MetricTone.performance,
                          ),
                        if (_trackSummary(activity)['elevation_gain_m'] != null)
                          _Metric(
                            label: 'Elevation gain',
                            value:
                                '${((_trackSummary(activity)['elevation_gain_m'] as num).toDouble()).round()} m',
                            tone: _MetricTone.neutral,
                          ),
                        if (_trackSummary(activity)['max_elevation_m'] != null)
                          _Metric(
                            label: 'Max elevation',
                            value:
                                '${((_trackSummary(activity)['max_elevation_m'] as num).toDouble()).round()} m',
                            tone: _MetricTone.neutral,
                          ),
                        if (_hasDistanceAndTime(activity))
                          _Metric(
                            label: 'Avg speed',
                            value: _speedLabel(activity),
                            tone: _MetricTone.performance,
                          ),
                        if (activity['avg_hr'] != null)
                          _Metric(
                            label: 'Avg heart rate',
                            value: '${activity['avg_hr']} bpm',
                            tone: _MetricTone.health,
                          ),
                        if (activity['calories'] != null)
                          _Metric(
                            label: 'Calories',
                            value: '${activity['calories']} kcal',
                            tone: _MetricTone.health,
                          ),
                      ],
                    ),
                  ),
                ),
                if (activity['source'] == 'phone_gps')
                  ActivityRouteThumbnail(
                    activityId: activity['id'] as String,
                    interactive: true,
                    height: 260,
                  ),
                if (activity['notes'] != null) ...[
                  const SizedBox(height: 14),
                  Text(activity['notes'] as String),
                ],
                const SizedBox(height: 24),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                for (final comment in detail.comments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileAvatar(
                          displayName:
                              comment['display_name'] as String? ?? '?',
                          avatarUrl: comment['avatar_url'] as String?,
                          radius: 16,
                          backgroundColor: _avatarColor(
                              comment['user_id'] as String),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['display_name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(comment['body'] as String),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Post comment',
                      onPressed: _isSaving ? null : _comment,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            );
          },
          ),
          ),
      ),
    );
  }

  static String _typeLabel(String type) => switch (type) {
    'run' => 'Run',
    'walk' => 'Walk',
    'cycle' => 'Cycle',
    'strength' => 'Strength',
    _ => 'Other activity',
  };

  static String _dateLabel(DateTime dateTime) =>
      formatShortLocalDateTime(dateTime);

  static Map<String, dynamic> _trackSummary(Map<String, dynamic> activity) =>
      Map<String, dynamic>.from(
        (activity['track_summary'] as Map?) ?? const {},
      );

  static bool _hasDistanceAndTime(Map<String, dynamic> activity) =>
      (activity['distance_m'] as num? ?? 0) > 0 &&
      (activity['moving_time_s'] as num? ?? 0) > 0;

  static String _paceLabel(Map<String, dynamic> activity) {
    final secondsPerKilometer =
        (activity['moving_time_s'] as num).toDouble() /
        ((activity['distance_m'] as num).toDouble() / 1000);
    final minutes = secondsPerKilometer ~/ 60;
    final seconds = (secondsPerKilometer % 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  static String _speedLabel(Map<String, dynamic> activity) {
    final kilometers = (activity['distance_m'] as num).toDouble() / 1000;
    final hours = (activity['moving_time_s'] as num).toDouble() / 3600;
    return '${(kilometers / hours).toStringAsFixed(1)} km/h';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.tone});

  final String label;
  final String value;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final accent = switch (tone) {
      _MetricTone.primary => theme.colorScheme.primary,
      _MetricTone.performance => const Color(0xFF4E7FA6),
      _MetricTone.health => colors.accent,
      _MetricTone.neutral => colors.border,
    };
    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MetricTone { primary, performance, health, neutral }
