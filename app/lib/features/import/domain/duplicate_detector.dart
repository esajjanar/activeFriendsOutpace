class ActivityFingerprint {
  const ActivityFingerprint({
    required this.externalId,
    required this.activityType,
    required this.startedAt,
    required this.endedAt,
  });

  final String externalId;
  final String activityType;
  final DateTime startedAt;
  final DateTime endedAt;
}

class DuplicateDetector {
  const DuplicateDetector._();

  static ActivityFingerprint? findCandidate({
    required ActivityFingerprint activity,
    required Iterable<ActivityFingerprint> candidates,
  }) {
    for (final candidate in candidates) {
      if (candidate.externalId == activity.externalId || !_typesMatch(activity.activityType, candidate.activityType)) continue;
      final shorterDuration = _duration(activity).compareTo(_duration(candidate)) <= 0 ? _duration(activity) : _duration(candidate);
      if (shorterDuration <= Duration.zero) continue;
      if (_overlap(activity, candidate) > shorterDuration * 0.8) return candidate;
    }
    return null;
  }

  static bool _typesMatch(String left, String right) => left == 'other' || right == 'other' || left == right;

  static Duration _duration(ActivityFingerprint activity) => activity.endedAt.difference(activity.startedAt);

  static Duration _overlap(ActivityFingerprint left, ActivityFingerprint right) {
    final start = left.startedAt.isAfter(right.startedAt) ? left.startedAt : right.startedAt;
    final end = left.endedAt.isBefore(right.endedAt) ? left.endedAt : right.endedAt;
    return end.isAfter(start) ? end.difference(start) : Duration.zero;
  }
}