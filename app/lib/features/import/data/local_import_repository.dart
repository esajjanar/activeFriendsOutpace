import 'dart:convert';

import 'package:activefriends/data/local/app_database.dart';
import 'package:activefriends/features/import/domain/duplicate_detector.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class DuplicateMatch {
  const DuplicateMatch({required this.groupId, required this.candidatePayload});

  final String groupId;
  final Map<String, dynamic> candidatePayload;
}

class LocalImportRepository {
  LocalImportRepository(this._database);

  final AppDatabase _database;

  Future<DateTime?> watermarkFor({required String userId, required String source}) async {
    final query = _database.select(_database.importWatermarks)
      ..where((row) => row.userId.equals(userId) & row.source.equals(source));
    return (await query.getSingleOrNull())?.importedThrough;
  }

  Future<void> cacheActivity(Map<String, dynamic> activity, {required String syncStatus}) async {
    await _database.into(_database.localActivities).insertOnConflictUpdate(
          LocalActivitiesCompanion.insert(
            userId: activity['user_id'] as String,
            source: activity['source'] as String,
            externalId: activity['external_id'] as String,
            activityType: activity['type'] as String,
            startedAt: DateTime.parse(activity['started_at'] as String),
            endedAt: DateTime.parse(activity['ended_at'] as String),
            distanceM: Value(activity['distance_m'] as int?),
            movingTimeS: Value(activity['moving_time_s'] as int?),
            elapsedS: Value(activity['elapsed_s'] as int?),
            avgHr: Value(activity['avg_hr'] as int?),
            maxHr: Value(activity['max_hr'] as int?),
            calories: Value(activity['calories'] as int?),
            syncStatus: Value(syncStatus),
            reviewState: Value(activity['review_state'] as String? ?? 'clean'),
            dupGroupId: Value(activity['dup_group_id'] as String?),
            excluded: Value(activity['excluded'] as bool? ?? false),
          ),
        );
  }

  Future<void> markSynced(Map<String, dynamic> activity) {
    return cacheActivity(activity, syncStatus: 'synced');
  }

  Future<void> queueActivity(Map<String, dynamic> activity) async {
    await cacheActivity(activity, syncStatus: 'pending');
    await (_database.delete(_database.pendingActivitySyncs)
          ..where((row) =>
              row.userId.equals(activity['user_id'] as String) &
              row.source.equals(activity['source'] as String) &
              row.externalId.equals(activity['external_id'] as String)))
        .go();
    await _database.into(_database.pendingActivitySyncs).insert(
          PendingActivitySyncsCompanion.insert(
            userId: activity['user_id'] as String,
            source: activity['source'] as String,
            externalId: activity['external_id'] as String,
            payload: jsonEncode(activity),
          ),
        );
  }

  Future<DuplicateMatch?> flagDuplicateIfNeeded(Map<String, dynamic> activity) async {
    final existingActivities = await (_database.select(_database.localActivities)
          ..where((row) => row.userId.equals(activity['user_id'] as String)))
        .get();
    final current = ActivityFingerprint(
      externalId: activity['external_id'] as String,
      activityType: activity['type'] as String,
      startedAt: DateTime.parse(activity['started_at'] as String),
      endedAt: DateTime.parse(activity['ended_at'] as String),
    );
    final fingerprints = {
      for (final existing in existingActivities)
        existing.externalId: ActivityFingerprint(
          externalId: existing.externalId,
          activityType: existing.activityType,
          startedAt: existing.startedAt,
          endedAt: existing.endedAt,
        ),
    };
    final candidate = DuplicateDetector.findCandidate(activity: current, candidates: fingerprints.values);
    if (candidate == null) return null;

    final groupId = const Uuid().v4();
    await (_database.update(_database.localActivities)
          ..where((row) =>
              row.userId.equals(activity['user_id'] as String) &
              row.source.equals(activity['source'] as String) &
              row.externalId.equals(activity['external_id'] as String)))
        .write(LocalActivitiesCompanion(reviewState: const Value('needs_review'), dupGroupId: Value(groupId)));
    final candidateActivity = existingActivities.firstWhere((item) => item.externalId == candidate.externalId);
    await (_database.update(_database.localActivities)
          ..where((row) =>
              row.userId.equals(candidateActivity.userId) &
              row.source.equals(candidateActivity.source) &
              row.externalId.equals(candidateActivity.externalId)))
        .write(LocalActivitiesCompanion(reviewState: const Value('needs_review'), dupGroupId: Value(groupId)));

    return DuplicateMatch(groupId: groupId, candidatePayload: _remotePayload(candidateActivity));
  }

  Future<List<PendingActivitySync>> pendingSyncs() => _database.select(_database.pendingActivitySyncs).get();

  Future<void> removePendingSync(int id) => (_database.delete(_database.pendingActivitySyncs)..where((row) => row.id.equals(id))).go();

  Future<void> saveWatermark({required String userId, required String source, required DateTime importedThrough}) {
    return _database.into(_database.importWatermarks).insertOnConflictUpdate(
          ImportWatermarksCompanion.insert(
            userId: userId,
            source: source,
            importedThrough: importedThrough,
          ),
        );
  }

  Map<String, dynamic> decodePayload(PendingActivitySync sync) {
    return Map<String, dynamic>.from(jsonDecode(sync.payload) as Map);
  }

  Map<String, dynamic> _remotePayload(LocalActivity activity) => {
        'user_id': activity.userId,
        'type': activity.activityType,
        'started_at': activity.startedAt.toUtc().toIso8601String(),
        'ended_at': activity.endedAt.toUtc().toIso8601String(),
        'distance_m': activity.distanceM,
        'moving_time_s': activity.movingTimeS,
        'elapsed_s': activity.elapsedS,
        'avg_hr': activity.avgHr,
        'max_hr': activity.maxHr,
        'calories': activity.calories,
        'source': activity.source,
        'external_id': activity.externalId,
        'review_state': activity.reviewState,
        'dup_group_id': activity.dupGroupId,
        'excluded': activity.excluded,
        'status': activity.syncStatus,
      };
}