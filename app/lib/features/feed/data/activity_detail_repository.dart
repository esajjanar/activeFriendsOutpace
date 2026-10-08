import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityDetail {
  const ActivityDetail({
    required this.activity,
    required this.reactions,
    required this.comments,
  });

  final Map<String, dynamic> activity;
  final List<Map<String, dynamic>> reactions;
  final List<Map<String, dynamic>> comments;

  factory ActivityDetail.fromJson(Map<String, dynamic> json) => ActivityDetail(
    activity: Map<String, dynamic>.from(json['activity'] as Map),
    reactions: (json['reactions'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    comments: (json['comments'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
  );
}

class ActivityDetailRepository {
  ActivityDetailRepository(this._client);

  final SupabaseClient _client;

  Future<ActivityDetail> load({
    required String activityId,
    required String clubId,
  }) async {
    final data = await _client.rpc(
      'activity_detail',
      params: {'target_activity_id': activityId, 'target_club_id': clubId},
    );
    return ActivityDetail.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> setReaction({
    required String activityId,
    required String reaction,
  }) async {
    final user = _client.auth.currentUser!;
    await _client.from('activity_reactions').upsert({
      'activity_id': activityId,
      'user_id': user.id,
      'reaction': reaction,
    });
  }

  Future<void> removeReaction(String activityId) async {
    final user = _client.auth.currentUser!;
    await _client
        .from('activity_reactions')
        .delete()
        .eq('activity_id', activityId)
        .eq('user_id', user.id);
  }

  Future<void> addComment({
    required String activityId,
    required String body,
  }) async {
    final user = _client.auth.currentUser!;
    await _client.from('activity_comments').insert({
      'activity_id': activityId,
      'user_id': user.id,
      'body': body.trim(),
    });
  }

  Future<void> deleteActivity(String activityId) async {
    final deleted = await _client
        .from('activities')
        .delete()
        .eq('id', activityId)
        .select('id');
    if (deleted.isEmpty) {
      throw const ActivityDeleteException(
        'This activity could not be deleted. You may no longer have permission to delete it.',
      );
    }
  }

  Future<void> markNotificationsSeen(String activityId) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _client
          .from('notifications')
          .update({'seen': true})
          .eq('user_id', user.id)
          .eq('activity_id', activityId)
          .eq('seen', false);
    }
  }
}

class ActivityDeleteException implements Exception {
  const ActivityDeleteException(this.message);

  final String message;

  @override
  String toString() => message;
}
