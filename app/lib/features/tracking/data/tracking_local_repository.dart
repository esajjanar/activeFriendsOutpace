import 'package:activefriends/data/local/app_database.dart';
import 'package:drift/drift.dart';

class TrackingLocalRepository {
  TrackingLocalRepository(this._database);

  final AppDatabase _database;

  Future<void> createSession({
    required String id,
    required String activityType,
    required DateTime startedAt,
    String? ownerUserId,
  }) async {
    await _database
        .into(_database.trackingSessions)
        .insert(
          TrackingSessionsCompanion.insert(
            id: id,
            ownerUserId: Value(ownerUserId),
            activityType: activityType,
            status: 'active',
            startedAt: startedAt,
            updatedAt: startedAt,
          ),
        );
  }

  Future<void> savePoint({
    required String sessionId,
    required int sequence,
    required TrackingPointData point,
    required double distanceM,
    required double elevationGainM,
    required int movingTimeS,
    required String status,
  }) async {
    await _database.transaction(() async {
      await _database
          .into(_database.trackingPoints)
          .insert(
            TrackingPointsCompanion.insert(
              sessionId: sessionId,
              sequence: sequence,
              latitude: point.latitude,
              longitude: point.longitude,
              timestamp: point.timestamp,
              elevation: point.elevation,
              accuracy: point.accuracy,
            ),
          );
      await (_database.update(
        _database.trackingSessions,
      )..where((session) => session.id.equals(sessionId))).write(
        TrackingSessionsCompanion(
          updatedAt: Value(DateTime.now()),
          distanceM: Value(distanceM),
          elevationGainM: Value(elevationGainM),
          movingTimeS: Value(movingTimeS),
          acceptedFixes: Value(sequence + 1),
          status: Value(status),
          lastLatitude: Value(point.latitude),
          lastLongitude: Value(point.longitude),
          lastPointAt: Value(point.timestamp),
        ),
      );
    });
  }

  /// Most recent unfinished session. When [ownerUserId] is given, only returns
  /// a session owned by that account (or a legacy session with no owner), so a
  /// user is never prompted to recover another account's activity.
  Future<TrackingSession?> findUnfinishedSession({String? ownerUserId}) {
    final query = _database.select(_database.trackingSessions)
      ..where((session) => session.status.isIn(const ['active', 'paused']));
    if (ownerUserId != null) {
      query.where(
        (session) =>
            session.ownerUserId.isNull() |
            session.ownerUserId.equals(ownerUserId),
      );
    }
    query
      ..orderBy([(session) => OrderingTerm.desc(session.updatedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<List<TrackingPoint>> loadPoints(String sessionId) =>
      (_database.select(_database.trackingPoints)
            ..where((point) => point.sessionId.equals(sessionId))
            ..orderBy([(point) => OrderingTerm.asc(point.sequence)]))
          .get();

  Future<void> updateStatus(String sessionId, String status) =>
      (_database.update(
        _database.trackingSessions,
      )..where((session) => session.id.equals(sessionId))).write(
        TrackingSessionsCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
          pausedAt: Value(status == 'paused' ? DateTime.now() : null),
        ),
      );

  Future<void> deleteSession(String sessionId) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.trackingPoints,
      )..where((point) => point.sessionId.equals(sessionId))).go();
      await (_database.delete(
        _database.trackingSessions,
      )..where((session) => session.id.equals(sessionId))).go();
    });
  }
}

class TrackingPointData {
  const TrackingPointData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.elevation,
    required this.accuracy,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double elevation;
  final double accuracy;
}
