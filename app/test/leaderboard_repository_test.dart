import 'package:activefriends/features/leaderboard/data/leaderboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses server-calculated leaderboard rows', () {
    final entry = LeaderboardEntry.fromJson({
      'member_id': 'user-1',
      'display_name': 'Mayya',
      'points': 13.5,
      'distance_m': 10500,
      'moving_time_s': 1920,
      'activity_types': ['run', 'strength'],
    });

    expect(entry.displayName, 'Mayya');
    expect(entry.points, 13.5);
    expect(entry.activityTypes, ['run', 'strength']);
  });
}