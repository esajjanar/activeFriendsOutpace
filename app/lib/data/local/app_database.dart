import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class LocalActivities extends Table {
  TextColumn get userId => text()();
  TextColumn get source => text()();
  TextColumn get externalId => text()();
  TextColumn get activityType => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get distanceM => integer().nullable()();
  IntColumn get movingTimeS => integer().nullable()();
  IntColumn get elapsedS => integer().nullable()();
  IntColumn get avgHr => integer().nullable()();
  IntColumn get maxHr => integer().nullable()();
  IntColumn get calories => integer().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get reviewState => text().withDefault(const Constant('clean'))();
  TextColumn get dupGroupId => text().nullable()();
  BoolColumn get excluded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {userId, source, externalId};
}

class ImportWatermarks extends Table {
  TextColumn get userId => text()();
  TextColumn get source => text()();
  DateTimeColumn get importedThrough => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {userId, source};
}

class PendingActivitySyncs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get source => text()();
  TextColumn get externalId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();
}

class TrackingSessions extends Table {
  TextColumn get id => text()();
  // Supabase user id of the account signed in when recording started. Used to
  // block saving an activity under a different account (RLS would reject it).
  // Nullable for sessions created before this column existed.
  TextColumn get ownerUserId => text().nullable()();
  TextColumn get activityType => text()();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  RealColumn get distanceM => real().withDefault(const Constant(0))();
  RealColumn get elevationGainM => real().withDefault(const Constant(0))();
  IntColumn get movingTimeS => integer().withDefault(const Constant(0))();
  IntColumn get acceptedFixes => integer().withDefault(const Constant(0))();
  RealColumn get lastLatitude => real().nullable()();
  RealColumn get lastLongitude => real().nullable()();
  DateTimeColumn get lastPointAt => dateTime().nullable()();
  DateTimeColumn get pausedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TrackingPoints extends Table {
  TextColumn get sessionId => text()();
  IntColumn get sequence => integer()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get elevation => real()();
  RealColumn get accuracy => real()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId, sequence};
}

@DriftDatabase(
  tables: [
    LocalActivities,
    ImportWatermarks,
    PendingActivitySyncs,
    TrackingSessions,
    TrackingPoints,
  ],
)
class AppDatabase extends _$AppDatabase {
  static final shared = AppDatabase();

  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(localActivities, localActivities.reviewState);
        await migrator.addColumn(localActivities, localActivities.dupGroupId);
        await migrator.addColumn(localActivities, localActivities.excluded);
      }
      if (from < 3) {
        await migrator.createTable(trackingSessions);
        await migrator.createTable(trackingPoints);
      }
      if (from < 4) {
        await migrator.addColumn(
          trackingSessions,
          trackingSessions.movingTimeS,
        );
        await migrator.addColumn(trackingSessions, trackingSessions.pausedAt);
      }
      if (from < 5) {
        await migrator.addColumn(
          trackingSessions,
          trackingSessions.ownerUserId,
        );
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'activefriends',
      native: DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
