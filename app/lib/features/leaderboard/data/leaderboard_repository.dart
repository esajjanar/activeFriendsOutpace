import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.memberId,
    required this.displayName,
    required this.avatarUrl,
    required this.points,
    required this.distanceM,
    required this.movingTimeS,
    required this.activityTypes,
  });

  final String memberId;
  final String displayName;
  final String? avatarUrl;
  final double points;
  final int distanceM;
  final int movingTimeS;
  final List<String> activityTypes;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      memberId: json['member_id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      points: (json['points'] as num).toDouble(),
      distanceM: (json['distance_m'] as num).toInt(),
      movingTimeS: (json['moving_time_s'] as num).toInt(),
      activityTypes: List<String>.from(json['activity_types'] as List<dynamic>? ?? const []),
    );
  }
}

class LeaderboardRepository {
  LeaderboardRepository(this._client);

  final SupabaseClient _client;

  Future<List<LeaderboardEntry>> currentWeek(String clubId) async {
    final data = await _client.rpc('weekly_leaderboard', params: {'target_club_id': clubId});
    return (data as List<dynamic>)
        .map((row) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}