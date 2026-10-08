import 'package:supabase_flutter/supabase_flutter.dart';

class ReactorInfo {
  const ReactorInfo({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;

  factory ReactorInfo.fromJson(Map<String, dynamic> json) => ReactorInfo(
    userId: json['user_id'] as String,
    displayName: json['display_name'] as String,
    avatarUrl: json['avatar_url'] as String?,
  );
}

class FeedActivity {
  const FeedActivity({
    required this.id,
    required this.memberId,
    required this.displayName,
    required this.avatarUrl,
    required this.type,
    required this.startedAt,
    required this.distanceM,
    required this.movingTimeS,
    required this.points,
    required this.source,
    required this.notes,
    required this.excluded,
    required this.routeVisible,
    required this.reactionCount,
    required this.commentCount,
    required this.hasReacted,
    required this.topReactors,
    required this.topCommenters,
  });

  final String id;
  final String memberId;
  final String displayName;
  final String? avatarUrl;
  final String type;
  final DateTime startedAt;
  final int? distanceM;
  final int? movingTimeS;
  final double points;
  final String source;
  final String? notes;
  final bool excluded;
  final bool routeVisible;
  final int reactionCount;
  final int commentCount;
  final bool hasReacted;
  /// Up to 4 reactors returned by the RPC for the stacked avatar display.
  final List<ReactorInfo> topReactors;
  /// Up to 4 unique commenters returned by the RPC for the stacked avatar display.
  final List<ReactorInfo> topCommenters;

  FeedActivity copyWith({int? reactionCount, int? commentCount, bool? hasReacted}) =>
      FeedActivity(
        id: id,
        memberId: memberId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        type: type,
        startedAt: startedAt,
        distanceM: distanceM,
        movingTimeS: movingTimeS,
        points: points,
        source: source,
        notes: notes,
        excluded: excluded,
        routeVisible: routeVisible,
        reactionCount: reactionCount ?? this.reactionCount,
        commentCount: commentCount ?? this.commentCount,
        hasReacted: hasReacted ?? this.hasReacted,
        topReactors: topReactors,
        topCommenters: topCommenters,
      );

  factory FeedActivity.fromJson(Map<String, dynamic> json) => FeedActivity(
    id: json['activity_id'] as String,
    memberId: json['member_id'] as String,
    displayName: json['display_name'] as String,
    avatarUrl: json['avatar_url'] as String?,
    type: json['activity_type'] as String,
    startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
    distanceM: (json['distance_m'] as num?)?.toInt(),
    movingTimeS: (json['moving_time_s'] as num?)?.toInt(),
    points: (json['points'] as num).toDouble(),
    source: json['source'] as String,
    notes: json['notes'] as String?,
    excluded: json['excluded'] as bool,
    routeVisible: json['route_visible'] as bool? ?? false,
    reactionCount: (json['reaction_count'] as num).toInt(),
    commentCount: (json['comment_count'] as num).toInt(),
    hasReacted: json['has_reacted'] as bool? ?? false,
    topReactors: (json['top_reactors'] as List<dynamic>? ?? [])
        .map((e) => ReactorInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    topCommenters: (json['top_commenters'] as List<dynamic>? ?? [])
        .map((e) => ReactorInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class ActivityFeedRepository {
  ActivityFeedRepository(this._client);

  final SupabaseClient _client;

  Future<List<FeedActivity>> load({
    required String clubId,
    required bool mine,
    String searchQuery = '',
    int pageSize = 20,
    int pageOffset = 0,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (mine && currentUserId == null) return const [];
    final data = await _client.rpc(
      'club_activity_feed',
      params: {
        'target_club_id': clubId,
        'page_size': pageSize,
        'page_offset': pageOffset,
        'target_user_id': mine ? currentUserId : null,
        'search_query': searchQuery.trim().isEmpty ? null : searchQuery.trim(),
      },
    );
    final activities = (data as List<dynamic>)
        .map(
          (row) => FeedActivity.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    return activities;
  }
}
