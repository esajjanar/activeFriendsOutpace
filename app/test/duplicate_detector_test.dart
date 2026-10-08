import 'package:activefriends/features/import/domain/duplicate_detector.dart';
import 'package:flutter_test/flutter_test.dart';

ActivityFingerprint activity({
  required String id,
  required String type,
  required DateTime start,
  required DateTime end,
}) =>
    ActivityFingerprint(externalId: id, activityType: type, startedAt: start, endedAt: end);

void main() {
  final start = DateTime.utc(2026, 9, 10, 1);

  test('flags equal-type sessions overlapping more than 80 percent of the shorter duration', () {
    final current = activity(id: 'phone', type: 'run', start: start, end: start.add(const Duration(minutes: 30)));
    final candidate = activity(id: 'watch', type: 'run', start: start.add(const Duration(minutes: 2)), end: start.add(const Duration(minutes: 32)));

    expect(DuplicateDetector.findCandidate(activity: current, candidates: [candidate]), candidate);
  });

  test('does not flag sessions at exactly 80 percent overlap or differing canonical types', () {
    final current = activity(id: 'phone', type: 'run', start: start, end: start.add(const Duration(minutes: 30)));
    final exactThreshold = activity(id: 'watch', type: 'run', start: start.add(const Duration(minutes: 6)), end: start.add(const Duration(minutes: 36)));
    final differentType = activity(id: 'bike', type: 'cycle', start: start, end: start.add(const Duration(minutes: 30)));

    expect(DuplicateDetector.findCandidate(activity: current, candidates: [exactThreshold, differentType]), isNull);
  });

  test('treats other as an unspecified type that can match any session', () {
    final current = activity(id: 'unknown', type: 'other', start: start, end: start.add(const Duration(minutes: 20)));
    final candidate = activity(id: 'watch', type: 'walk', start: start, end: start.add(const Duration(minutes: 20)));

    expect(DuplicateDetector.findCandidate(activity: current, candidates: [candidate]), candidate);
  });
}