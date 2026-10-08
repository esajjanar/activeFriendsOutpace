import 'package:activefriends/features/feed/data/activity_feed_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses server-scored activity feed rows', () {
    final activity = FeedActivity.fromJson({
      'activity_id': 'activity-1',
      'member_id': 'member-1',
      'display_name': 'Mayya',
      'activity_type': 'cycle',
      'started_at': '2026-09-07T00:15:00Z',
      'distance_m': 62000,
      'moving_time_s': 9900,
      'points': 18.6,
      'source': 'health_connect',
      'notes': 'Sunday endurance ride.',
      'review_state': 'clean',
      'excluded': false,
      'route_visible': true,
      'reaction_count': 2,
      'comment_count': 1,
    });

    expect(activity.displayName, 'Mayya');
    expect(activity.points, 18.6);
    expect(activity.reactionCount, 2);
    expect(activity.routeVisible, isTrue);
  });
}