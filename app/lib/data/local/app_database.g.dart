// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalActivitiesTable extends LocalActivities
    with TableInfo<$LocalActivitiesTable, LocalActivity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityTypeMeta = const VerificationMeta(
    'activityType',
  );
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
    'activity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<int> distanceM = GeneratedColumn<int>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _movingTimeSMeta = const VerificationMeta(
    'movingTimeS',
  );
  @override
  late final GeneratedColumn<int> movingTimeS = GeneratedColumn<int>(
    'moving_time_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elapsedSMeta = const VerificationMeta(
    'elapsedS',
  );
  @override
  late final GeneratedColumn<int> elapsedS = GeneratedColumn<int>(
    'elapsed_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgHrMeta = const VerificationMeta('avgHr');
  @override
  late final GeneratedColumn<int> avgHr = GeneratedColumn<int>(
    'avg_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxHrMeta = const VerificationMeta('maxHr');
  @override
  late final GeneratedColumn<int> maxHr = GeneratedColumn<int>(
    'max_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _reviewStateMeta = const VerificationMeta(
    'reviewState',
  );
  @override
  late final GeneratedColumn<String> reviewState = GeneratedColumn<String>(
    'review_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('clean'),
  );
  static const VerificationMeta _dupGroupIdMeta = const VerificationMeta(
    'dupGroupId',
  );
  @override
  late final GeneratedColumn<String> dupGroupId = GeneratedColumn<String>(
    'dup_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _excludedMeta = const VerificationMeta(
    'excluded',
  );
  @override
  late final GeneratedColumn<bool> excluded = GeneratedColumn<bool>(
    'excluded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("excluded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    source,
    externalId,
    activityType,
    startedAt,
    endedAt,
    distanceM,
    movingTimeS,
    elapsedS,
    avgHr,
    maxHr,
    calories,
    syncStatus,
    reviewState,
    dupGroupId,
    excluded,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalActivity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('activity_type')) {
      context.handle(
        _activityTypeMeta,
        activityType.isAcceptableOrUnknown(
          data['activity_type']!,
          _activityTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityTypeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('moving_time_s')) {
      context.handle(
        _movingTimeSMeta,
        movingTimeS.isAcceptableOrUnknown(
          data['moving_time_s']!,
          _movingTimeSMeta,
        ),
      );
    }
    if (data.containsKey('elapsed_s')) {
      context.handle(
        _elapsedSMeta,
        elapsedS.isAcceptableOrUnknown(data['elapsed_s']!, _elapsedSMeta),
      );
    }
    if (data.containsKey('avg_hr')) {
      context.handle(
        _avgHrMeta,
        avgHr.isAcceptableOrUnknown(data['avg_hr']!, _avgHrMeta),
      );
    }
    if (data.containsKey('max_hr')) {
      context.handle(
        _maxHrMeta,
        maxHr.isAcceptableOrUnknown(data['max_hr']!, _maxHrMeta),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('review_state')) {
      context.handle(
        _reviewStateMeta,
        reviewState.isAcceptableOrUnknown(
          data['review_state']!,
          _reviewStateMeta,
        ),
      );
    }
    if (data.containsKey('dup_group_id')) {
      context.handle(
        _dupGroupIdMeta,
        dupGroupId.isAcceptableOrUnknown(
          data['dup_group_id']!,
          _dupGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('excluded')) {
      context.handle(
        _excludedMeta,
        excluded.isAcceptableOrUnknown(data['excluded']!, _excludedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, source, externalId};
  @override
  LocalActivity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalActivity(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      activityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_type'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_m'],
      ),
      movingTimeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_time_s'],
      ),
      elapsedS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_s'],
      ),
      avgHr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_hr'],
      ),
      maxHr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_hr'],
      ),
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      reviewState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_state'],
      )!,
      dupGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dup_group_id'],
      ),
      excluded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}excluded'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalActivitiesTable createAlias(String alias) {
    return $LocalActivitiesTable(attachedDatabase, alias);
  }
}

class LocalActivity extends DataClass implements Insertable<LocalActivity> {
  final String userId;
  final String source;
  final String externalId;
  final String activityType;
  final DateTime startedAt;
  final DateTime endedAt;
  final int? distanceM;
  final int? movingTimeS;
  final int? elapsedS;
  final int? avgHr;
  final int? maxHr;
  final int? calories;
  final String syncStatus;
  final String reviewState;
  final String? dupGroupId;
  final bool excluded;
  final DateTime createdAt;
  const LocalActivity({
    required this.userId,
    required this.source,
    required this.externalId,
    required this.activityType,
    required this.startedAt,
    required this.endedAt,
    this.distanceM,
    this.movingTimeS,
    this.elapsedS,
    this.avgHr,
    this.maxHr,
    this.calories,
    required this.syncStatus,
    required this.reviewState,
    this.dupGroupId,
    required this.excluded,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['source'] = Variable<String>(source);
    map['external_id'] = Variable<String>(externalId);
    map['activity_type'] = Variable<String>(activityType);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<int>(distanceM);
    }
    if (!nullToAbsent || movingTimeS != null) {
      map['moving_time_s'] = Variable<int>(movingTimeS);
    }
    if (!nullToAbsent || elapsedS != null) {
      map['elapsed_s'] = Variable<int>(elapsedS);
    }
    if (!nullToAbsent || avgHr != null) {
      map['avg_hr'] = Variable<int>(avgHr);
    }
    if (!nullToAbsent || maxHr != null) {
      map['max_hr'] = Variable<int>(maxHr);
    }
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<int>(calories);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['review_state'] = Variable<String>(reviewState);
    if (!nullToAbsent || dupGroupId != null) {
      map['dup_group_id'] = Variable<String>(dupGroupId);
    }
    map['excluded'] = Variable<bool>(excluded);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalActivitiesCompanion toCompanion(bool nullToAbsent) {
    return LocalActivitiesCompanion(
      userId: Value(userId),
      source: Value(source),
      externalId: Value(externalId),
      activityType: Value(activityType),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      movingTimeS: movingTimeS == null && nullToAbsent
          ? const Value.absent()
          : Value(movingTimeS),
      elapsedS: elapsedS == null && nullToAbsent
          ? const Value.absent()
          : Value(elapsedS),
      avgHr: avgHr == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHr),
      maxHr: maxHr == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHr),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      syncStatus: Value(syncStatus),
      reviewState: Value(reviewState),
      dupGroupId: dupGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(dupGroupId),
      excluded: Value(excluded),
      createdAt: Value(createdAt),
    );
  }

  factory LocalActivity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalActivity(
      userId: serializer.fromJson<String>(json['userId']),
      source: serializer.fromJson<String>(json['source']),
      externalId: serializer.fromJson<String>(json['externalId']),
      activityType: serializer.fromJson<String>(json['activityType']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      distanceM: serializer.fromJson<int?>(json['distanceM']),
      movingTimeS: serializer.fromJson<int?>(json['movingTimeS']),
      elapsedS: serializer.fromJson<int?>(json['elapsedS']),
      avgHr: serializer.fromJson<int?>(json['avgHr']),
      maxHr: serializer.fromJson<int?>(json['maxHr']),
      calories: serializer.fromJson<int?>(json['calories']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      reviewState: serializer.fromJson<String>(json['reviewState']),
      dupGroupId: serializer.fromJson<String?>(json['dupGroupId']),
      excluded: serializer.fromJson<bool>(json['excluded']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'source': serializer.toJson<String>(source),
      'externalId': serializer.toJson<String>(externalId),
      'activityType': serializer.toJson<String>(activityType),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'distanceM': serializer.toJson<int?>(distanceM),
      'movingTimeS': serializer.toJson<int?>(movingTimeS),
      'elapsedS': serializer.toJson<int?>(elapsedS),
      'avgHr': serializer.toJson<int?>(avgHr),
      'maxHr': serializer.toJson<int?>(maxHr),
      'calories': serializer.toJson<int?>(calories),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'reviewState': serializer.toJson<String>(reviewState),
      'dupGroupId': serializer.toJson<String?>(dupGroupId),
      'excluded': serializer.toJson<bool>(excluded),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalActivity copyWith({
    String? userId,
    String? source,
    String? externalId,
    String? activityType,
    DateTime? startedAt,
    DateTime? endedAt,
    Value<int?> distanceM = const Value.absent(),
    Value<int?> movingTimeS = const Value.absent(),
    Value<int?> elapsedS = const Value.absent(),
    Value<int?> avgHr = const Value.absent(),
    Value<int?> maxHr = const Value.absent(),
    Value<int?> calories = const Value.absent(),
    String? syncStatus,
    String? reviewState,
    Value<String?> dupGroupId = const Value.absent(),
    bool? excluded,
    DateTime? createdAt,
  }) => LocalActivity(
    userId: userId ?? this.userId,
    source: source ?? this.source,
    externalId: externalId ?? this.externalId,
    activityType: activityType ?? this.activityType,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
    movingTimeS: movingTimeS.present ? movingTimeS.value : this.movingTimeS,
    elapsedS: elapsedS.present ? elapsedS.value : this.elapsedS,
    avgHr: avgHr.present ? avgHr.value : this.avgHr,
    maxHr: maxHr.present ? maxHr.value : this.maxHr,
    calories: calories.present ? calories.value : this.calories,
    syncStatus: syncStatus ?? this.syncStatus,
    reviewState: reviewState ?? this.reviewState,
    dupGroupId: dupGroupId.present ? dupGroupId.value : this.dupGroupId,
    excluded: excluded ?? this.excluded,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalActivity copyWithCompanion(LocalActivitiesCompanion data) {
    return LocalActivity(
      userId: data.userId.present ? data.userId.value : this.userId,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      movingTimeS: data.movingTimeS.present
          ? data.movingTimeS.value
          : this.movingTimeS,
      elapsedS: data.elapsedS.present ? data.elapsedS.value : this.elapsedS,
      avgHr: data.avgHr.present ? data.avgHr.value : this.avgHr,
      maxHr: data.maxHr.present ? data.maxHr.value : this.maxHr,
      calories: data.calories.present ? data.calories.value : this.calories,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      reviewState: data.reviewState.present
          ? data.reviewState.value
          : this.reviewState,
      dupGroupId: data.dupGroupId.present
          ? data.dupGroupId.value
          : this.dupGroupId,
      excluded: data.excluded.present ? data.excluded.value : this.excluded,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalActivity(')
          ..write('userId: $userId, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('activityType: $activityType, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('movingTimeS: $movingTimeS, ')
          ..write('elapsedS: $elapsedS, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('calories: $calories, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('reviewState: $reviewState, ')
          ..write('dupGroupId: $dupGroupId, ')
          ..write('excluded: $excluded, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    source,
    externalId,
    activityType,
    startedAt,
    endedAt,
    distanceM,
    movingTimeS,
    elapsedS,
    avgHr,
    maxHr,
    calories,
    syncStatus,
    reviewState,
    dupGroupId,
    excluded,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalActivity &&
          other.userId == this.userId &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.activityType == this.activityType &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.distanceM == this.distanceM &&
          other.movingTimeS == this.movingTimeS &&
          other.elapsedS == this.elapsedS &&
          other.avgHr == this.avgHr &&
          other.maxHr == this.maxHr &&
          other.calories == this.calories &&
          other.syncStatus == this.syncStatus &&
          other.reviewState == this.reviewState &&
          other.dupGroupId == this.dupGroupId &&
          other.excluded == this.excluded &&
          other.createdAt == this.createdAt);
}

class LocalActivitiesCompanion extends UpdateCompanion<LocalActivity> {
  final Value<String> userId;
  final Value<String> source;
  final Value<String> externalId;
  final Value<String> activityType;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int?> distanceM;
  final Value<int?> movingTimeS;
  final Value<int?> elapsedS;
  final Value<int?> avgHr;
  final Value<int?> maxHr;
  final Value<int?> calories;
  final Value<String> syncStatus;
  final Value<String> reviewState;
  final Value<String?> dupGroupId;
  final Value<bool> excluded;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalActivitiesCompanion({
    this.userId = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.activityType = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.movingTimeS = const Value.absent(),
    this.elapsedS = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.calories = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.dupGroupId = const Value.absent(),
    this.excluded = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalActivitiesCompanion.insert({
    required String userId,
    required String source,
    required String externalId,
    required String activityType,
    required DateTime startedAt,
    required DateTime endedAt,
    this.distanceM = const Value.absent(),
    this.movingTimeS = const Value.absent(),
    this.elapsedS = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.calories = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.dupGroupId = const Value.absent(),
    this.excluded = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       source = Value(source),
       externalId = Value(externalId),
       activityType = Value(activityType),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt);
  static Insertable<LocalActivity> custom({
    Expression<String>? userId,
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<String>? activityType,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? distanceM,
    Expression<int>? movingTimeS,
    Expression<int>? elapsedS,
    Expression<int>? avgHr,
    Expression<int>? maxHr,
    Expression<int>? calories,
    Expression<String>? syncStatus,
    Expression<String>? reviewState,
    Expression<String>? dupGroupId,
    Expression<bool>? excluded,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (activityType != null) 'activity_type': activityType,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (distanceM != null) 'distance_m': distanceM,
      if (movingTimeS != null) 'moving_time_s': movingTimeS,
      if (elapsedS != null) 'elapsed_s': elapsedS,
      if (avgHr != null) 'avg_hr': avgHr,
      if (maxHr != null) 'max_hr': maxHr,
      if (calories != null) 'calories': calories,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (reviewState != null) 'review_state': reviewState,
      if (dupGroupId != null) 'dup_group_id': dupGroupId,
      if (excluded != null) 'excluded': excluded,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalActivitiesCompanion copyWith({
    Value<String>? userId,
    Value<String>? source,
    Value<String>? externalId,
    Value<String>? activityType,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int?>? distanceM,
    Value<int?>? movingTimeS,
    Value<int?>? elapsedS,
    Value<int?>? avgHr,
    Value<int?>? maxHr,
    Value<int?>? calories,
    Value<String>? syncStatus,
    Value<String>? reviewState,
    Value<String?>? dupGroupId,
    Value<bool>? excluded,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalActivitiesCompanion(
      userId: userId ?? this.userId,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      activityType: activityType ?? this.activityType,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceM: distanceM ?? this.distanceM,
      movingTimeS: movingTimeS ?? this.movingTimeS,
      elapsedS: elapsedS ?? this.elapsedS,
      avgHr: avgHr ?? this.avgHr,
      maxHr: maxHr ?? this.maxHr,
      calories: calories ?? this.calories,
      syncStatus: syncStatus ?? this.syncStatus,
      reviewState: reviewState ?? this.reviewState,
      dupGroupId: dupGroupId ?? this.dupGroupId,
      excluded: excluded ?? this.excluded,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<int>(distanceM.value);
    }
    if (movingTimeS.present) {
      map['moving_time_s'] = Variable<int>(movingTimeS.value);
    }
    if (elapsedS.present) {
      map['elapsed_s'] = Variable<int>(elapsedS.value);
    }
    if (avgHr.present) {
      map['avg_hr'] = Variable<int>(avgHr.value);
    }
    if (maxHr.present) {
      map['max_hr'] = Variable<int>(maxHr.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (reviewState.present) {
      map['review_state'] = Variable<String>(reviewState.value);
    }
    if (dupGroupId.present) {
      map['dup_group_id'] = Variable<String>(dupGroupId.value);
    }
    if (excluded.present) {
      map['excluded'] = Variable<bool>(excluded.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalActivitiesCompanion(')
          ..write('userId: $userId, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('activityType: $activityType, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('movingTimeS: $movingTimeS, ')
          ..write('elapsedS: $elapsedS, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('calories: $calories, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('reviewState: $reviewState, ')
          ..write('dupGroupId: $dupGroupId, ')
          ..write('excluded: $excluded, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportWatermarksTable extends ImportWatermarks
    with TableInfo<$ImportWatermarksTable, ImportWatermark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportWatermarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedThroughMeta = const VerificationMeta(
    'importedThrough',
  );
  @override
  late final GeneratedColumn<DateTime> importedThrough =
      GeneratedColumn<DateTime>(
        'imported_through',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    source,
    importedThrough,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_watermarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportWatermark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('imported_through')) {
      context.handle(
        _importedThroughMeta,
        importedThrough.isAcceptableOrUnknown(
          data['imported_through']!,
          _importedThroughMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importedThroughMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, source};
  @override
  ImportWatermark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportWatermark(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      importedThrough: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_through'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ImportWatermarksTable createAlias(String alias) {
    return $ImportWatermarksTable(attachedDatabase, alias);
  }
}

class ImportWatermark extends DataClass implements Insertable<ImportWatermark> {
  final String userId;
  final String source;
  final DateTime importedThrough;
  final DateTime updatedAt;
  const ImportWatermark({
    required this.userId,
    required this.source,
    required this.importedThrough,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['source'] = Variable<String>(source);
    map['imported_through'] = Variable<DateTime>(importedThrough);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ImportWatermarksCompanion toCompanion(bool nullToAbsent) {
    return ImportWatermarksCompanion(
      userId: Value(userId),
      source: Value(source),
      importedThrough: Value(importedThrough),
      updatedAt: Value(updatedAt),
    );
  }

  factory ImportWatermark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportWatermark(
      userId: serializer.fromJson<String>(json['userId']),
      source: serializer.fromJson<String>(json['source']),
      importedThrough: serializer.fromJson<DateTime>(json['importedThrough']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'source': serializer.toJson<String>(source),
      'importedThrough': serializer.toJson<DateTime>(importedThrough),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ImportWatermark copyWith({
    String? userId,
    String? source,
    DateTime? importedThrough,
    DateTime? updatedAt,
  }) => ImportWatermark(
    userId: userId ?? this.userId,
    source: source ?? this.source,
    importedThrough: importedThrough ?? this.importedThrough,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ImportWatermark copyWithCompanion(ImportWatermarksCompanion data) {
    return ImportWatermark(
      userId: data.userId.present ? data.userId.value : this.userId,
      source: data.source.present ? data.source.value : this.source,
      importedThrough: data.importedThrough.present
          ? data.importedThrough.value
          : this.importedThrough,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportWatermark(')
          ..write('userId: $userId, ')
          ..write('source: $source, ')
          ..write('importedThrough: $importedThrough, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, source, importedThrough, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportWatermark &&
          other.userId == this.userId &&
          other.source == this.source &&
          other.importedThrough == this.importedThrough &&
          other.updatedAt == this.updatedAt);
}

class ImportWatermarksCompanion extends UpdateCompanion<ImportWatermark> {
  final Value<String> userId;
  final Value<String> source;
  final Value<DateTime> importedThrough;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ImportWatermarksCompanion({
    this.userId = const Value.absent(),
    this.source = const Value.absent(),
    this.importedThrough = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportWatermarksCompanion.insert({
    required String userId,
    required String source,
    required DateTime importedThrough,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       source = Value(source),
       importedThrough = Value(importedThrough);
  static Insertable<ImportWatermark> custom({
    Expression<String>? userId,
    Expression<String>? source,
    Expression<DateTime>? importedThrough,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (source != null) 'source': source,
      if (importedThrough != null) 'imported_through': importedThrough,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportWatermarksCompanion copyWith({
    Value<String>? userId,
    Value<String>? source,
    Value<DateTime>? importedThrough,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ImportWatermarksCompanion(
      userId: userId ?? this.userId,
      source: source ?? this.source,
      importedThrough: importedThrough ?? this.importedThrough,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (importedThrough.present) {
      map['imported_through'] = Variable<DateTime>(importedThrough.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportWatermarksCompanion(')
          ..write('userId: $userId, ')
          ..write('source: $source, ')
          ..write('importedThrough: $importedThrough, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingActivitySyncsTable extends PendingActivitySyncs
    with TableInfo<$PendingActivitySyncsTable, PendingActivitySync> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingActivitySyncsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    source,
    externalId,
    payload,
    queuedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_activity_syncs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingActivitySync> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingActivitySync map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingActivitySync(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
    );
  }

  @override
  $PendingActivitySyncsTable createAlias(String alias) {
    return $PendingActivitySyncsTable(attachedDatabase, alias);
  }
}

class PendingActivitySync extends DataClass
    implements Insertable<PendingActivitySync> {
  final int id;
  final String userId;
  final String source;
  final String externalId;
  final String payload;
  final DateTime queuedAt;
  const PendingActivitySync({
    required this.id,
    required this.userId,
    required this.source,
    required this.externalId,
    required this.payload,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['source'] = Variable<String>(source);
    map['external_id'] = Variable<String>(externalId);
    map['payload'] = Variable<String>(payload);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  PendingActivitySyncsCompanion toCompanion(bool nullToAbsent) {
    return PendingActivitySyncsCompanion(
      id: Value(id),
      userId: Value(userId),
      source: Value(source),
      externalId: Value(externalId),
      payload: Value(payload),
      queuedAt: Value(queuedAt),
    );
  }

  factory PendingActivitySync.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingActivitySync(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      source: serializer.fromJson<String>(json['source']),
      externalId: serializer.fromJson<String>(json['externalId']),
      payload: serializer.fromJson<String>(json['payload']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'source': serializer.toJson<String>(source),
      'externalId': serializer.toJson<String>(externalId),
      'payload': serializer.toJson<String>(payload),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
    };
  }

  PendingActivitySync copyWith({
    int? id,
    String? userId,
    String? source,
    String? externalId,
    String? payload,
    DateTime? queuedAt,
  }) => PendingActivitySync(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    source: source ?? this.source,
    externalId: externalId ?? this.externalId,
    payload: payload ?? this.payload,
    queuedAt: queuedAt ?? this.queuedAt,
  );
  PendingActivitySync copyWithCompanion(PendingActivitySyncsCompanion data) {
    return PendingActivitySync(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      payload: data.payload.present ? data.payload.value : this.payload,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingActivitySync(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, source, externalId, payload, queuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingActivitySync &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.payload == this.payload &&
          other.queuedAt == this.queuedAt);
}

class PendingActivitySyncsCompanion
    extends UpdateCompanion<PendingActivitySync> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> source;
  final Value<String> externalId;
  final Value<String> payload;
  final Value<DateTime> queuedAt;
  const PendingActivitySyncsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.payload = const Value.absent(),
    this.queuedAt = const Value.absent(),
  });
  PendingActivitySyncsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String source,
    required String externalId,
    required String payload,
    this.queuedAt = const Value.absent(),
  }) : userId = Value(userId),
       source = Value(source),
       externalId = Value(externalId),
       payload = Value(payload);
  static Insertable<PendingActivitySync> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<String>? payload,
    Expression<DateTime>? queuedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (payload != null) 'payload': payload,
      if (queuedAt != null) 'queued_at': queuedAt,
    });
  }

  PendingActivitySyncsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? source,
    Value<String>? externalId,
    Value<String>? payload,
    Value<DateTime>? queuedAt,
  }) {
    return PendingActivitySyncsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      payload: payload ?? this.payload,
      queuedAt: queuedAt ?? this.queuedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingActivitySyncsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackingSessionsTable extends TrackingSessions
    with TableInfo<$TrackingSessionsTable, TrackingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activityTypeMeta = const VerificationMeta(
    'activityType',
  );
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
    'activity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _elevationGainMMeta = const VerificationMeta(
    'elevationGainM',
  );
  @override
  late final GeneratedColumn<double> elevationGainM = GeneratedColumn<double>(
    'elevation_gain_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _movingTimeSMeta = const VerificationMeta(
    'movingTimeS',
  );
  @override
  late final GeneratedColumn<int> movingTimeS = GeneratedColumn<int>(
    'moving_time_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _acceptedFixesMeta = const VerificationMeta(
    'acceptedFixes',
  );
  @override
  late final GeneratedColumn<int> acceptedFixes = GeneratedColumn<int>(
    'accepted_fixes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastLatitudeMeta = const VerificationMeta(
    'lastLatitude',
  );
  @override
  late final GeneratedColumn<double> lastLatitude = GeneratedColumn<double>(
    'last_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastLongitudeMeta = const VerificationMeta(
    'lastLongitude',
  );
  @override
  late final GeneratedColumn<double> lastLongitude = GeneratedColumn<double>(
    'last_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPointAtMeta = const VerificationMeta(
    'lastPointAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPointAt = GeneratedColumn<DateTime>(
    'last_point_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedAtMeta = const VerificationMeta(
    'pausedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pausedAt = GeneratedColumn<DateTime>(
    'paused_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerUserId,
    activityType,
    status,
    startedAt,
    updatedAt,
    distanceM,
    elevationGainM,
    movingTimeS,
    acceptedFixes,
    lastLatitude,
    lastLongitude,
    lastPointAt,
    pausedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('activity_type')) {
      context.handle(
        _activityTypeMeta,
        activityType.isAcceptableOrUnknown(
          data['activity_type']!,
          _activityTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('elevation_gain_m')) {
      context.handle(
        _elevationGainMMeta,
        elevationGainM.isAcceptableOrUnknown(
          data['elevation_gain_m']!,
          _elevationGainMMeta,
        ),
      );
    }
    if (data.containsKey('moving_time_s')) {
      context.handle(
        _movingTimeSMeta,
        movingTimeS.isAcceptableOrUnknown(
          data['moving_time_s']!,
          _movingTimeSMeta,
        ),
      );
    }
    if (data.containsKey('accepted_fixes')) {
      context.handle(
        _acceptedFixesMeta,
        acceptedFixes.isAcceptableOrUnknown(
          data['accepted_fixes']!,
          _acceptedFixesMeta,
        ),
      );
    }
    if (data.containsKey('last_latitude')) {
      context.handle(
        _lastLatitudeMeta,
        lastLatitude.isAcceptableOrUnknown(
          data['last_latitude']!,
          _lastLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('last_longitude')) {
      context.handle(
        _lastLongitudeMeta,
        lastLongitude.isAcceptableOrUnknown(
          data['last_longitude']!,
          _lastLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('last_point_at')) {
      context.handle(
        _lastPointAtMeta,
        lastPointAt.isAcceptableOrUnknown(
          data['last_point_at']!,
          _lastPointAtMeta,
        ),
      );
    }
    if (data.containsKey('paused_at')) {
      context.handle(
        _pausedAtMeta,
        pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      ),
      activityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      )!,
      elevationGainM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_gain_m'],
      )!,
      movingTimeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_time_s'],
      )!,
      acceptedFixes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accepted_fixes'],
      )!,
      lastLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_latitude'],
      ),
      lastLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_longitude'],
      ),
      lastPointAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_point_at'],
      ),
      pausedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paused_at'],
      ),
    );
  }

  @override
  $TrackingSessionsTable createAlias(String alias) {
    return $TrackingSessionsTable(attachedDatabase, alias);
  }
}

class TrackingSession extends DataClass implements Insertable<TrackingSession> {
  final String id;
  final String? ownerUserId;
  final String activityType;
  final String status;
  final DateTime startedAt;
  final DateTime updatedAt;
  final double distanceM;
  final double elevationGainM;
  final int movingTimeS;
  final int acceptedFixes;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastPointAt;
  final DateTime? pausedAt;
  const TrackingSession({
    required this.id,
    this.ownerUserId,
    required this.activityType,
    required this.status,
    required this.startedAt,
    required this.updatedAt,
    required this.distanceM,
    required this.elevationGainM,
    required this.movingTimeS,
    required this.acceptedFixes,
    this.lastLatitude,
    this.lastLongitude,
    this.lastPointAt,
    this.pausedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || ownerUserId != null) {
      map['owner_user_id'] = Variable<String>(ownerUserId);
    }
    map['activity_type'] = Variable<String>(activityType);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['distance_m'] = Variable<double>(distanceM);
    map['elevation_gain_m'] = Variable<double>(elevationGainM);
    map['moving_time_s'] = Variable<int>(movingTimeS);
    map['accepted_fixes'] = Variable<int>(acceptedFixes);
    if (!nullToAbsent || lastLatitude != null) {
      map['last_latitude'] = Variable<double>(lastLatitude);
    }
    if (!nullToAbsent || lastLongitude != null) {
      map['last_longitude'] = Variable<double>(lastLongitude);
    }
    if (!nullToAbsent || lastPointAt != null) {
      map['last_point_at'] = Variable<DateTime>(lastPointAt);
    }
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<DateTime>(pausedAt);
    }
    return map;
  }

  TrackingSessionsCompanion toCompanion(bool nullToAbsent) {
    return TrackingSessionsCompanion(
      id: Value(id),
      ownerUserId: ownerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUserId),
      activityType: Value(activityType),
      status: Value(status),
      startedAt: Value(startedAt),
      updatedAt: Value(updatedAt),
      distanceM: Value(distanceM),
      elevationGainM: Value(elevationGainM),
      movingTimeS: Value(movingTimeS),
      acceptedFixes: Value(acceptedFixes),
      lastLatitude: lastLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLatitude),
      lastLongitude: lastLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLongitude),
      lastPointAt: lastPointAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPointAt),
      pausedAt: pausedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAt),
    );
  }

  factory TrackingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingSession(
      id: serializer.fromJson<String>(json['id']),
      ownerUserId: serializer.fromJson<String?>(json['ownerUserId']),
      activityType: serializer.fromJson<String>(json['activityType']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      distanceM: serializer.fromJson<double>(json['distanceM']),
      elevationGainM: serializer.fromJson<double>(json['elevationGainM']),
      movingTimeS: serializer.fromJson<int>(json['movingTimeS']),
      acceptedFixes: serializer.fromJson<int>(json['acceptedFixes']),
      lastLatitude: serializer.fromJson<double?>(json['lastLatitude']),
      lastLongitude: serializer.fromJson<double?>(json['lastLongitude']),
      lastPointAt: serializer.fromJson<DateTime?>(json['lastPointAt']),
      pausedAt: serializer.fromJson<DateTime?>(json['pausedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerUserId': serializer.toJson<String?>(ownerUserId),
      'activityType': serializer.toJson<String>(activityType),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'distanceM': serializer.toJson<double>(distanceM),
      'elevationGainM': serializer.toJson<double>(elevationGainM),
      'movingTimeS': serializer.toJson<int>(movingTimeS),
      'acceptedFixes': serializer.toJson<int>(acceptedFixes),
      'lastLatitude': serializer.toJson<double?>(lastLatitude),
      'lastLongitude': serializer.toJson<double?>(lastLongitude),
      'lastPointAt': serializer.toJson<DateTime?>(lastPointAt),
      'pausedAt': serializer.toJson<DateTime?>(pausedAt),
    };
  }

  TrackingSession copyWith({
    String? id,
    Value<String?> ownerUserId = const Value.absent(),
    String? activityType,
    String? status,
    DateTime? startedAt,
    DateTime? updatedAt,
    double? distanceM,
    double? elevationGainM,
    int? movingTimeS,
    int? acceptedFixes,
    Value<double?> lastLatitude = const Value.absent(),
    Value<double?> lastLongitude = const Value.absent(),
    Value<DateTime?> lastPointAt = const Value.absent(),
    Value<DateTime?> pausedAt = const Value.absent(),
  }) => TrackingSession(
    id: id ?? this.id,
    ownerUserId: ownerUserId.present ? ownerUserId.value : this.ownerUserId,
    activityType: activityType ?? this.activityType,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    distanceM: distanceM ?? this.distanceM,
    elevationGainM: elevationGainM ?? this.elevationGainM,
    movingTimeS: movingTimeS ?? this.movingTimeS,
    acceptedFixes: acceptedFixes ?? this.acceptedFixes,
    lastLatitude: lastLatitude.present ? lastLatitude.value : this.lastLatitude,
    lastLongitude: lastLongitude.present
        ? lastLongitude.value
        : this.lastLongitude,
    lastPointAt: lastPointAt.present ? lastPointAt.value : this.lastPointAt,
    pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
  );
  TrackingSession copyWithCompanion(TrackingSessionsCompanion data) {
    return TrackingSession(
      id: data.id.present ? data.id.value : this.id,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      elevationGainM: data.elevationGainM.present
          ? data.elevationGainM.value
          : this.elevationGainM,
      movingTimeS: data.movingTimeS.present
          ? data.movingTimeS.value
          : this.movingTimeS,
      acceptedFixes: data.acceptedFixes.present
          ? data.acceptedFixes.value
          : this.acceptedFixes,
      lastLatitude: data.lastLatitude.present
          ? data.lastLatitude.value
          : this.lastLatitude,
      lastLongitude: data.lastLongitude.present
          ? data.lastLongitude.value
          : this.lastLongitude,
      lastPointAt: data.lastPointAt.present
          ? data.lastPointAt.value
          : this.lastPointAt,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingSession(')
          ..write('id: $id, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('activityType: $activityType, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('elevationGainM: $elevationGainM, ')
          ..write('movingTimeS: $movingTimeS, ')
          ..write('acceptedFixes: $acceptedFixes, ')
          ..write('lastLatitude: $lastLatitude, ')
          ..write('lastLongitude: $lastLongitude, ')
          ..write('lastPointAt: $lastPointAt, ')
          ..write('pausedAt: $pausedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerUserId,
    activityType,
    status,
    startedAt,
    updatedAt,
    distanceM,
    elevationGainM,
    movingTimeS,
    acceptedFixes,
    lastLatitude,
    lastLongitude,
    lastPointAt,
    pausedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingSession &&
          other.id == this.id &&
          other.ownerUserId == this.ownerUserId &&
          other.activityType == this.activityType &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt &&
          other.distanceM == this.distanceM &&
          other.elevationGainM == this.elevationGainM &&
          other.movingTimeS == this.movingTimeS &&
          other.acceptedFixes == this.acceptedFixes &&
          other.lastLatitude == this.lastLatitude &&
          other.lastLongitude == this.lastLongitude &&
          other.lastPointAt == this.lastPointAt &&
          other.pausedAt == this.pausedAt);
}

class TrackingSessionsCompanion extends UpdateCompanion<TrackingSession> {
  final Value<String> id;
  final Value<String?> ownerUserId;
  final Value<String> activityType;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<DateTime> updatedAt;
  final Value<double> distanceM;
  final Value<double> elevationGainM;
  final Value<int> movingTimeS;
  final Value<int> acceptedFixes;
  final Value<double?> lastLatitude;
  final Value<double?> lastLongitude;
  final Value<DateTime?> lastPointAt;
  final Value<DateTime?> pausedAt;
  final Value<int> rowid;
  const TrackingSessionsCompanion({
    this.id = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.activityType = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.elevationGainM = const Value.absent(),
    this.movingTimeS = const Value.absent(),
    this.acceptedFixes = const Value.absent(),
    this.lastLatitude = const Value.absent(),
    this.lastLongitude = const Value.absent(),
    this.lastPointAt = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackingSessionsCompanion.insert({
    required String id,
    this.ownerUserId = const Value.absent(),
    required String activityType,
    required String status,
    required DateTime startedAt,
    required DateTime updatedAt,
    this.distanceM = const Value.absent(),
    this.elevationGainM = const Value.absent(),
    this.movingTimeS = const Value.absent(),
    this.acceptedFixes = const Value.absent(),
    this.lastLatitude = const Value.absent(),
    this.lastLongitude = const Value.absent(),
    this.lastPointAt = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       activityType = Value(activityType),
       status = Value(status),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<TrackingSession> custom({
    Expression<String>? id,
    Expression<String>? ownerUserId,
    Expression<String>? activityType,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? updatedAt,
    Expression<double>? distanceM,
    Expression<double>? elevationGainM,
    Expression<int>? movingTimeS,
    Expression<int>? acceptedFixes,
    Expression<double>? lastLatitude,
    Expression<double>? lastLongitude,
    Expression<DateTime>? lastPointAt,
    Expression<DateTime>? pausedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (activityType != null) 'activity_type': activityType,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (distanceM != null) 'distance_m': distanceM,
      if (elevationGainM != null) 'elevation_gain_m': elevationGainM,
      if (movingTimeS != null) 'moving_time_s': movingTimeS,
      if (acceptedFixes != null) 'accepted_fixes': acceptedFixes,
      if (lastLatitude != null) 'last_latitude': lastLatitude,
      if (lastLongitude != null) 'last_longitude': lastLongitude,
      if (lastPointAt != null) 'last_point_at': lastPointAt,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? ownerUserId,
    Value<String>? activityType,
    Value<String>? status,
    Value<DateTime>? startedAt,
    Value<DateTime>? updatedAt,
    Value<double>? distanceM,
    Value<double>? elevationGainM,
    Value<int>? movingTimeS,
    Value<int>? acceptedFixes,
    Value<double?>? lastLatitude,
    Value<double?>? lastLongitude,
    Value<DateTime?>? lastPointAt,
    Value<DateTime?>? pausedAt,
    Value<int>? rowid,
  }) {
    return TrackingSessionsCompanion(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      activityType: activityType ?? this.activityType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distanceM: distanceM ?? this.distanceM,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      movingTimeS: movingTimeS ?? this.movingTimeS,
      acceptedFixes: acceptedFixes ?? this.acceptedFixes,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastPointAt: lastPointAt ?? this.lastPointAt,
      pausedAt: pausedAt ?? this.pausedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (elevationGainM.present) {
      map['elevation_gain_m'] = Variable<double>(elevationGainM.value);
    }
    if (movingTimeS.present) {
      map['moving_time_s'] = Variable<int>(movingTimeS.value);
    }
    if (acceptedFixes.present) {
      map['accepted_fixes'] = Variable<int>(acceptedFixes.value);
    }
    if (lastLatitude.present) {
      map['last_latitude'] = Variable<double>(lastLatitude.value);
    }
    if (lastLongitude.present) {
      map['last_longitude'] = Variable<double>(lastLongitude.value);
    }
    if (lastPointAt.present) {
      map['last_point_at'] = Variable<DateTime>(lastPointAt.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<DateTime>(pausedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('activityType: $activityType, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('elevationGainM: $elevationGainM, ')
          ..write('movingTimeS: $movingTimeS, ')
          ..write('acceptedFixes: $acceptedFixes, ')
          ..write('lastLatitude: $lastLatitude, ')
          ..write('lastLongitude: $lastLongitude, ')
          ..write('lastPointAt: $lastPointAt, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackingPointsTable extends TrackingPoints
    with TableInfo<$TrackingPointsTable, TrackingPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationMeta = const VerificationMeta(
    'elevation',
  );
  @override
  late final GeneratedColumn<double> elevation = GeneratedColumn<double>(
    'elevation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    sequence,
    latitude,
    longitude,
    timestamp,
    elevation,
    accuracy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackingPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('elevation')) {
      context.handle(
        _elevationMeta,
        elevation.isAcceptableOrUnknown(data['elevation']!, _elevationMeta),
      );
    } else if (isInserting) {
      context.missing(_elevationMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, sequence};
  @override
  TrackingPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingPoint(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      elevation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      )!,
    );
  }

  @override
  $TrackingPointsTable createAlias(String alias) {
    return $TrackingPointsTable(attachedDatabase, alias);
  }
}

class TrackingPoint extends DataClass implements Insertable<TrackingPoint> {
  final String sessionId;
  final int sequence;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double elevation;
  final double accuracy;
  const TrackingPoint({
    required this.sessionId,
    required this.sequence,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.elevation,
    required this.accuracy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['sequence'] = Variable<int>(sequence);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['elevation'] = Variable<double>(elevation);
    map['accuracy'] = Variable<double>(accuracy);
    return map;
  }

  TrackingPointsCompanion toCompanion(bool nullToAbsent) {
    return TrackingPointsCompanion(
      sessionId: Value(sessionId),
      sequence: Value(sequence),
      latitude: Value(latitude),
      longitude: Value(longitude),
      timestamp: Value(timestamp),
      elevation: Value(elevation),
      accuracy: Value(accuracy),
    );
  }

  factory TrackingPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingPoint(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      elevation: serializer.fromJson<double>(json['elevation']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'sequence': serializer.toJson<int>(sequence),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'elevation': serializer.toJson<double>(elevation),
      'accuracy': serializer.toJson<double>(accuracy),
    };
  }

  TrackingPoint copyWith({
    String? sessionId,
    int? sequence,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? elevation,
    double? accuracy,
  }) => TrackingPoint(
    sessionId: sessionId ?? this.sessionId,
    sequence: sequence ?? this.sequence,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    timestamp: timestamp ?? this.timestamp,
    elevation: elevation ?? this.elevation,
    accuracy: accuracy ?? this.accuracy,
  );
  TrackingPoint copyWithCompanion(TrackingPointsCompanion data) {
    return TrackingPoint(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      elevation: data.elevation.present ? data.elevation.value : this.elevation,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingPoint(')
          ..write('sessionId: $sessionId, ')
          ..write('sequence: $sequence, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('timestamp: $timestamp, ')
          ..write('elevation: $elevation, ')
          ..write('accuracy: $accuracy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    sequence,
    latitude,
    longitude,
    timestamp,
    elevation,
    accuracy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingPoint &&
          other.sessionId == this.sessionId &&
          other.sequence == this.sequence &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.timestamp == this.timestamp &&
          other.elevation == this.elevation &&
          other.accuracy == this.accuracy);
}

class TrackingPointsCompanion extends UpdateCompanion<TrackingPoint> {
  final Value<String> sessionId;
  final Value<int> sequence;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<DateTime> timestamp;
  final Value<double> elevation;
  final Value<double> accuracy;
  final Value<int> rowid;
  const TrackingPointsCompanion({
    this.sessionId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.elevation = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackingPointsCompanion.insert({
    required String sessionId,
    required int sequence,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    required double elevation,
    required double accuracy,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       sequence = Value(sequence),
       latitude = Value(latitude),
       longitude = Value(longitude),
       timestamp = Value(timestamp),
       elevation = Value(elevation),
       accuracy = Value(accuracy);
  static Insertable<TrackingPoint> custom({
    Expression<String>? sessionId,
    Expression<int>? sequence,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? timestamp,
    Expression<double>? elevation,
    Expression<double>? accuracy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (sequence != null) 'sequence': sequence,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (timestamp != null) 'timestamp': timestamp,
      if (elevation != null) 'elevation': elevation,
      if (accuracy != null) 'accuracy': accuracy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackingPointsCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? sequence,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<DateTime>? timestamp,
    Value<double>? elevation,
    Value<double>? accuracy,
    Value<int>? rowid,
  }) {
    return TrackingPointsCompanion(
      sessionId: sessionId ?? this.sessionId,
      sequence: sequence ?? this.sequence,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      elevation: elevation ?? this.elevation,
      accuracy: accuracy ?? this.accuracy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (elevation.present) {
      map['elevation'] = Variable<double>(elevation.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingPointsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('sequence: $sequence, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('timestamp: $timestamp, ')
          ..write('elevation: $elevation, ')
          ..write('accuracy: $accuracy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalActivitiesTable localActivities = $LocalActivitiesTable(
    this,
  );
  late final $ImportWatermarksTable importWatermarks = $ImportWatermarksTable(
    this,
  );
  late final $PendingActivitySyncsTable pendingActivitySyncs =
      $PendingActivitySyncsTable(this);
  late final $TrackingSessionsTable trackingSessions = $TrackingSessionsTable(
    this,
  );
  late final $TrackingPointsTable trackingPoints = $TrackingPointsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localActivities,
    importWatermarks,
    pendingActivitySyncs,
    trackingSessions,
    trackingPoints,
  ];
}

typedef $$LocalActivitiesTableCreateCompanionBuilder =
    LocalActivitiesCompanion Function({
      required String userId,
      required String source,
      required String externalId,
      required String activityType,
      required DateTime startedAt,
      required DateTime endedAt,
      Value<int?> distanceM,
      Value<int?> movingTimeS,
      Value<int?> elapsedS,
      Value<int?> avgHr,
      Value<int?> maxHr,
      Value<int?> calories,
      Value<String> syncStatus,
      Value<String> reviewState,
      Value<String?> dupGroupId,
      Value<bool> excluded,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$LocalActivitiesTableUpdateCompanionBuilder =
    LocalActivitiesCompanion Function({
      Value<String> userId,
      Value<String> source,
      Value<String> externalId,
      Value<String> activityType,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<int?> distanceM,
      Value<int?> movingTimeS,
      Value<int?> elapsedS,
      Value<int?> avgHr,
      Value<int?> maxHr,
      Value<int?> calories,
      Value<String> syncStatus,
      Value<String> reviewState,
      Value<String?> dupGroupId,
      Value<bool> excluded,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalActivitiesTable> {
  $$LocalActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingTimeS => $composableBuilder(
    column: $table.movingTimeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedS => $composableBuilder(
    column: $table.elapsedS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgHr => $composableBuilder(
    column: $table.avgHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxHr => $composableBuilder(
    column: $table.maxHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dupGroupId => $composableBuilder(
    column: $table.dupGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excluded => $composableBuilder(
    column: $table.excluded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalActivitiesTable> {
  $$LocalActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingTimeS => $composableBuilder(
    column: $table.movingTimeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedS => $composableBuilder(
    column: $table.elapsedS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgHr => $composableBuilder(
    column: $table.avgHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxHr => $composableBuilder(
    column: $table.maxHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dupGroupId => $composableBuilder(
    column: $table.dupGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excluded => $composableBuilder(
    column: $table.excluded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalActivitiesTable> {
  $$LocalActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<int> get movingTimeS => $composableBuilder(
    column: $table.movingTimeS,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedS =>
      $composableBuilder(column: $table.elapsedS, builder: (column) => column);

  GeneratedColumn<int> get avgHr =>
      $composableBuilder(column: $table.avgHr, builder: (column) => column);

  GeneratedColumn<int> get maxHr =>
      $composableBuilder(column: $table.maxHr, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dupGroupId => $composableBuilder(
    column: $table.dupGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get excluded =>
      $composableBuilder(column: $table.excluded, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalActivitiesTable,
          LocalActivity,
          $$LocalActivitiesTableFilterComposer,
          $$LocalActivitiesTableOrderingComposer,
          $$LocalActivitiesTableAnnotationComposer,
          $$LocalActivitiesTableCreateCompanionBuilder,
          $$LocalActivitiesTableUpdateCompanionBuilder,
          (
            LocalActivity,
            BaseReferences<_$AppDatabase, $LocalActivitiesTable, LocalActivity>,
          ),
          LocalActivity,
          PrefetchHooks Function()
        > {
  $$LocalActivitiesTableTableManager(
    _$AppDatabase db,
    $LocalActivitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String> activityType = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int?> distanceM = const Value.absent(),
                Value<int?> movingTimeS = const Value.absent(),
                Value<int?> elapsedS = const Value.absent(),
                Value<int?> avgHr = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<int?> calories = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String> reviewState = const Value.absent(),
                Value<String?> dupGroupId = const Value.absent(),
                Value<bool> excluded = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalActivitiesCompanion(
                userId: userId,
                source: source,
                externalId: externalId,
                activityType: activityType,
                startedAt: startedAt,
                endedAt: endedAt,
                distanceM: distanceM,
                movingTimeS: movingTimeS,
                elapsedS: elapsedS,
                avgHr: avgHr,
                maxHr: maxHr,
                calories: calories,
                syncStatus: syncStatus,
                reviewState: reviewState,
                dupGroupId: dupGroupId,
                excluded: excluded,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String source,
                required String externalId,
                required String activityType,
                required DateTime startedAt,
                required DateTime endedAt,
                Value<int?> distanceM = const Value.absent(),
                Value<int?> movingTimeS = const Value.absent(),
                Value<int?> elapsedS = const Value.absent(),
                Value<int?> avgHr = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<int?> calories = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String> reviewState = const Value.absent(),
                Value<String?> dupGroupId = const Value.absent(),
                Value<bool> excluded = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalActivitiesCompanion.insert(
                userId: userId,
                source: source,
                externalId: externalId,
                activityType: activityType,
                startedAt: startedAt,
                endedAt: endedAt,
                distanceM: distanceM,
                movingTimeS: movingTimeS,
                elapsedS: elapsedS,
                avgHr: avgHr,
                maxHr: maxHr,
                calories: calories,
                syncStatus: syncStatus,
                reviewState: reviewState,
                dupGroupId: dupGroupId,
                excluded: excluded,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalActivitiesTable, LocalActivity>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalActivitiesTable,
                    LocalActivity
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalActivitiesTable,
      LocalActivity,
      $$LocalActivitiesTableFilterComposer,
      $$LocalActivitiesTableOrderingComposer,
      $$LocalActivitiesTableAnnotationComposer,
      $$LocalActivitiesTableCreateCompanionBuilder,
      $$LocalActivitiesTableUpdateCompanionBuilder,
      (
        LocalActivity,
        BaseReferences<_$AppDatabase, $LocalActivitiesTable, LocalActivity>,
      ),
      LocalActivity,
      PrefetchHooks Function()
    >;
typedef $$ImportWatermarksTableCreateCompanionBuilder =
    ImportWatermarksCompanion Function({
      required String userId,
      required String source,
      required DateTime importedThrough,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ImportWatermarksTableUpdateCompanionBuilder =
    ImportWatermarksCompanion Function({
      Value<String> userId,
      Value<String> source,
      Value<DateTime> importedThrough,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ImportWatermarksTableFilterComposer
    extends Composer<_$AppDatabase, $ImportWatermarksTable> {
  $$ImportWatermarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedThrough => $composableBuilder(
    column: $table.importedThrough,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportWatermarksTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportWatermarksTable> {
  $$ImportWatermarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedThrough => $composableBuilder(
    column: $table.importedThrough,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportWatermarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportWatermarksTable> {
  $$ImportWatermarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get importedThrough => $composableBuilder(
    column: $table.importedThrough,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ImportWatermarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportWatermarksTable,
          ImportWatermark,
          $$ImportWatermarksTableFilterComposer,
          $$ImportWatermarksTableOrderingComposer,
          $$ImportWatermarksTableAnnotationComposer,
          $$ImportWatermarksTableCreateCompanionBuilder,
          $$ImportWatermarksTableUpdateCompanionBuilder,
          (
            ImportWatermark,
            BaseReferences<
              _$AppDatabase,
              $ImportWatermarksTable,
              ImportWatermark
            >,
          ),
          ImportWatermark,
          PrefetchHooks Function()
        > {
  $$ImportWatermarksTableTableManager(
    _$AppDatabase db,
    $ImportWatermarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportWatermarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportWatermarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportWatermarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> importedThrough = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportWatermarksCompanion(
                userId: userId,
                source: source,
                importedThrough: importedThrough,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String source,
                required DateTime importedThrough,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportWatermarksCompanion.insert(
                userId: userId,
                source: source,
                importedThrough: importedThrough,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportWatermarksTable, ImportWatermark>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ImportWatermarksTable,
                    ImportWatermark
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportWatermarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportWatermarksTable,
      ImportWatermark,
      $$ImportWatermarksTableFilterComposer,
      $$ImportWatermarksTableOrderingComposer,
      $$ImportWatermarksTableAnnotationComposer,
      $$ImportWatermarksTableCreateCompanionBuilder,
      $$ImportWatermarksTableUpdateCompanionBuilder,
      (
        ImportWatermark,
        BaseReferences<_$AppDatabase, $ImportWatermarksTable, ImportWatermark>,
      ),
      ImportWatermark,
      PrefetchHooks Function()
    >;
typedef $$PendingActivitySyncsTableCreateCompanionBuilder =
    PendingActivitySyncsCompanion Function({
      Value<int> id,
      required String userId,
      required String source,
      required String externalId,
      required String payload,
      Value<DateTime> queuedAt,
    });
typedef $$PendingActivitySyncsTableUpdateCompanionBuilder =
    PendingActivitySyncsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> source,
      Value<String> externalId,
      Value<String> payload,
      Value<DateTime> queuedAt,
    });

class $$PendingActivitySyncsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingActivitySyncsTable> {
  $$PendingActivitySyncsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingActivitySyncsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingActivitySyncsTable> {
  $$PendingActivitySyncsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingActivitySyncsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingActivitySyncsTable> {
  $$PendingActivitySyncsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);
}

class $$PendingActivitySyncsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingActivitySyncsTable,
          PendingActivitySync,
          $$PendingActivitySyncsTableFilterComposer,
          $$PendingActivitySyncsTableOrderingComposer,
          $$PendingActivitySyncsTableAnnotationComposer,
          $$PendingActivitySyncsTableCreateCompanionBuilder,
          $$PendingActivitySyncsTableUpdateCompanionBuilder,
          (
            PendingActivitySync,
            BaseReferences<
              _$AppDatabase,
              $PendingActivitySyncsTable,
              PendingActivitySync
            >,
          ),
          PendingActivitySync,
          PrefetchHooks Function()
        > {
  $$PendingActivitySyncsTableTableManager(
    _$AppDatabase db,
    $PendingActivitySyncsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingActivitySyncsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingActivitySyncsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingActivitySyncsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
              }) => PendingActivitySyncsCompanion(
                id: id,
                userId: userId,
                source: source,
                externalId: externalId,
                payload: payload,
                queuedAt: queuedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String source,
                required String externalId,
                required String payload,
                Value<DateTime> queuedAt = const Value.absent(),
              }) => PendingActivitySyncsCompanion.insert(
                id: id,
                userId: userId,
                source: source,
                externalId: externalId,
                payload: payload,
                queuedAt: queuedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingActivitySyncsTable, PendingActivitySync>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingActivitySyncsTable,
                    PendingActivitySync
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingActivitySyncsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingActivitySyncsTable,
      PendingActivitySync,
      $$PendingActivitySyncsTableFilterComposer,
      $$PendingActivitySyncsTableOrderingComposer,
      $$PendingActivitySyncsTableAnnotationComposer,
      $$PendingActivitySyncsTableCreateCompanionBuilder,
      $$PendingActivitySyncsTableUpdateCompanionBuilder,
      (
        PendingActivitySync,
        BaseReferences<
          _$AppDatabase,
          $PendingActivitySyncsTable,
          PendingActivitySync
        >,
      ),
      PendingActivitySync,
      PrefetchHooks Function()
    >;
typedef $$TrackingSessionsTableCreateCompanionBuilder =
    TrackingSessionsCompanion Function({
      required String id,
      Value<String?> ownerUserId,
      required String activityType,
      required String status,
      required DateTime startedAt,
      required DateTime updatedAt,
      Value<double> distanceM,
      Value<double> elevationGainM,
      Value<int> movingTimeS,
      Value<int> acceptedFixes,
      Value<double?> lastLatitude,
      Value<double?> lastLongitude,
      Value<DateTime?> lastPointAt,
      Value<DateTime?> pausedAt,
      Value<int> rowid,
    });
typedef $$TrackingSessionsTableUpdateCompanionBuilder =
    TrackingSessionsCompanion Function({
      Value<String> id,
      Value<String?> ownerUserId,
      Value<String> activityType,
      Value<String> status,
      Value<DateTime> startedAt,
      Value<DateTime> updatedAt,
      Value<double> distanceM,
      Value<double> elevationGainM,
      Value<int> movingTimeS,
      Value<int> acceptedFixes,
      Value<double?> lastLatitude,
      Value<double?> lastLongitude,
      Value<DateTime?> lastPointAt,
      Value<DateTime?> pausedAt,
      Value<int> rowid,
    });

class $$TrackingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackingSessionsTable> {
  $$TrackingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingTimeS => $composableBuilder(
    column: $table.movingTimeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get acceptedFixes => $composableBuilder(
    column: $table.acceptedFixes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastLatitude => $composableBuilder(
    column: $table.lastLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastLongitude => $composableBuilder(
    column: $table.lastLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPointAt => $composableBuilder(
    column: $table.lastPointAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrackingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackingSessionsTable> {
  $$TrackingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingTimeS => $composableBuilder(
    column: $table.movingTimeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get acceptedFixes => $composableBuilder(
    column: $table.acceptedFixes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastLatitude => $composableBuilder(
    column: $table.lastLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastLongitude => $composableBuilder(
    column: $table.lastLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPointAt => $composableBuilder(
    column: $table.lastPointAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrackingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackingSessionsTable> {
  $$TrackingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get movingTimeS => $composableBuilder(
    column: $table.movingTimeS,
    builder: (column) => column,
  );

  GeneratedColumn<int> get acceptedFixes => $composableBuilder(
    column: $table.acceptedFixes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lastLatitude => $composableBuilder(
    column: $table.lastLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lastLongitude => $composableBuilder(
    column: $table.lastLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPointAt => $composableBuilder(
    column: $table.lastPointAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => column);
}

class $$TrackingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackingSessionsTable,
          TrackingSession,
          $$TrackingSessionsTableFilterComposer,
          $$TrackingSessionsTableOrderingComposer,
          $$TrackingSessionsTableAnnotationComposer,
          $$TrackingSessionsTableCreateCompanionBuilder,
          $$TrackingSessionsTableUpdateCompanionBuilder,
          (
            TrackingSession,
            BaseReferences<
              _$AppDatabase,
              $TrackingSessionsTable,
              TrackingSession
            >,
          ),
          TrackingSession,
          PrefetchHooks Function()
        > {
  $$TrackingSessionsTableTableManager(
    _$AppDatabase db,
    $TrackingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<String> activityType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<double> elevationGainM = const Value.absent(),
                Value<int> movingTimeS = const Value.absent(),
                Value<int> acceptedFixes = const Value.absent(),
                Value<double?> lastLatitude = const Value.absent(),
                Value<double?> lastLongitude = const Value.absent(),
                Value<DateTime?> lastPointAt = const Value.absent(),
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackingSessionsCompanion(
                id: id,
                ownerUserId: ownerUserId,
                activityType: activityType,
                status: status,
                startedAt: startedAt,
                updatedAt: updatedAt,
                distanceM: distanceM,
                elevationGainM: elevationGainM,
                movingTimeS: movingTimeS,
                acceptedFixes: acceptedFixes,
                lastLatitude: lastLatitude,
                lastLongitude: lastLongitude,
                lastPointAt: lastPointAt,
                pausedAt: pausedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> ownerUserId = const Value.absent(),
                required String activityType,
                required String status,
                required DateTime startedAt,
                required DateTime updatedAt,
                Value<double> distanceM = const Value.absent(),
                Value<double> elevationGainM = const Value.absent(),
                Value<int> movingTimeS = const Value.absent(),
                Value<int> acceptedFixes = const Value.absent(),
                Value<double?> lastLatitude = const Value.absent(),
                Value<double?> lastLongitude = const Value.absent(),
                Value<DateTime?> lastPointAt = const Value.absent(),
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackingSessionsCompanion.insert(
                id: id,
                ownerUserId: ownerUserId,
                activityType: activityType,
                status: status,
                startedAt: startedAt,
                updatedAt: updatedAt,
                distanceM: distanceM,
                elevationGainM: elevationGainM,
                movingTimeS: movingTimeS,
                acceptedFixes: acceptedFixes,
                lastLatitude: lastLatitude,
                lastLongitude: lastLongitude,
                lastPointAt: lastPointAt,
                pausedAt: pausedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackingSessionsTable, TrackingSession>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TrackingSessionsTable,
                    TrackingSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrackingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackingSessionsTable,
      TrackingSession,
      $$TrackingSessionsTableFilterComposer,
      $$TrackingSessionsTableOrderingComposer,
      $$TrackingSessionsTableAnnotationComposer,
      $$TrackingSessionsTableCreateCompanionBuilder,
      $$TrackingSessionsTableUpdateCompanionBuilder,
      (
        TrackingSession,
        BaseReferences<_$AppDatabase, $TrackingSessionsTable, TrackingSession>,
      ),
      TrackingSession,
      PrefetchHooks Function()
    >;
typedef $$TrackingPointsTableCreateCompanionBuilder =
    TrackingPointsCompanion Function({
      required String sessionId,
      required int sequence,
      required double latitude,
      required double longitude,
      required DateTime timestamp,
      required double elevation,
      required double accuracy,
      Value<int> rowid,
    });
typedef $$TrackingPointsTableUpdateCompanionBuilder =
    TrackingPointsCompanion Function({
      Value<String> sessionId,
      Value<int> sequence,
      Value<double> latitude,
      Value<double> longitude,
      Value<DateTime> timestamp,
      Value<double> elevation,
      Value<double> accuracy,
      Value<int> rowid,
    });

class $$TrackingPointsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackingPointsTable> {
  $$TrackingPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevation => $composableBuilder(
    column: $table.elevation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrackingPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackingPointsTable> {
  $$TrackingPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevation => $composableBuilder(
    column: $table.elevation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrackingPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackingPointsTable> {
  $$TrackingPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get elevation =>
      $composableBuilder(column: $table.elevation, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);
}

class $$TrackingPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackingPointsTable,
          TrackingPoint,
          $$TrackingPointsTableFilterComposer,
          $$TrackingPointsTableOrderingComposer,
          $$TrackingPointsTableAnnotationComposer,
          $$TrackingPointsTableCreateCompanionBuilder,
          $$TrackingPointsTableUpdateCompanionBuilder,
          (
            TrackingPoint,
            BaseReferences<_$AppDatabase, $TrackingPointsTable, TrackingPoint>,
          ),
          TrackingPoint,
          PrefetchHooks Function()
        > {
  $$TrackingPointsTableTableManager(
    _$AppDatabase db,
    $TrackingPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackingPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackingPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackingPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> elevation = const Value.absent(),
                Value<double> accuracy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackingPointsCompanion(
                sessionId: sessionId,
                sequence: sequence,
                latitude: latitude,
                longitude: longitude,
                timestamp: timestamp,
                elevation: elevation,
                accuracy: accuracy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int sequence,
                required double latitude,
                required double longitude,
                required DateTime timestamp,
                required double elevation,
                required double accuracy,
                Value<int> rowid = const Value.absent(),
              }) => TrackingPointsCompanion.insert(
                sessionId: sessionId,
                sequence: sequence,
                latitude: latitude,
                longitude: longitude,
                timestamp: timestamp,
                elevation: elevation,
                accuracy: accuracy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackingPointsTable, TrackingPoint>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TrackingPointsTable,
                    TrackingPoint
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrackingPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackingPointsTable,
      TrackingPoint,
      $$TrackingPointsTableFilterComposer,
      $$TrackingPointsTableOrderingComposer,
      $$TrackingPointsTableAnnotationComposer,
      $$TrackingPointsTableCreateCompanionBuilder,
      $$TrackingPointsTableUpdateCompanionBuilder,
      (
        TrackingPoint,
        BaseReferences<_$AppDatabase, $TrackingPointsTable, TrackingPoint>,
      ),
      TrackingPoint,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalActivitiesTableTableManager get localActivities =>
      $$LocalActivitiesTableTableManager(_db, _db.localActivities);
  $$ImportWatermarksTableTableManager get importWatermarks =>
      $$ImportWatermarksTableTableManager(_db, _db.importWatermarks);
  $$PendingActivitySyncsTableTableManager get pendingActivitySyncs =>
      $$PendingActivitySyncsTableTableManager(_db, _db.pendingActivitySyncs);
  $$TrackingSessionsTableTableManager get trackingSessions =>
      $$TrackingSessionsTableTableManager(_db, _db.trackingSessions);
  $$TrackingPointsTableTableManager get trackingPoints =>
      $$TrackingPointsTableTableManager(_db, _db.trackingPoints);
}
