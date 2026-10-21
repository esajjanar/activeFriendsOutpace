import 'dart:io';

import 'package:activefriends/data/local/app_database.dart';
import 'package:activefriends/features/import/data/local_import_repository.dart';
import 'package:health/health.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HealthImportResult {
  const HealthImportResult({
    required this.importedCount,
    required this.queuedCount,
    required this.historyAuthorized,
    required this.diagnostics,
    required this.skippedDuplicates,
    required this.alreadySyncedCount,
  });

  final int importedCount;
  final int queuedCount;
  final bool historyAuthorized;

  /// Count of imported workouts skipped because they overlap an existing
  /// Outpace activity (already logged — e.g. a ride also tracked via GPS).
  final int skippedDuplicates;

  /// Count of activities that were already synced from a previous import
  /// (re-scanned but not new).
  final int alreadySyncedCount;

  /// Human-readable breakdown of the Health Connect / HealthKit read, shown
  /// only when nothing came through, so an empty result is explainable
  /// on-device (no ADB on the Pixel). Empty string otherwise.
  final String diagnostics;
}

class HealthImportService {
  HealthImportService({
    Health? health,
    SupabaseClient? client,
    LocalImportRepository? localRepository,
  }) : _health = health ?? Health(),
       _client = client ?? Supabase.instance.client,
       _localRepository =
           localRepository ?? LocalImportRepository(AppDatabase.shared);

  final Health _health;
  final SupabaseClient _client;
  final LocalImportRepository _localRepository;

  // Types we actually READ and surface in the import.
  // DISTANCE_DELTA is read so we can compute per-source distance and avoid
  // double-counting when multiple apps (Garmin + phone pedometer) write
  // DistanceRecords for the same time window.
  static const _readTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.HEART_RATE,
    HealthDataType.DISTANCE_DELTA,
  ];

  // Types we must hold READ permission for. When the health package reads a
  // WORKOUT (ExerciseSessionRecord) on Android it internally reads
  // DistanceRecord, TotalCaloriesBurnedRecord and StepsRecord for the session
  // window to compute totals (HealthDataReader.handleWorkoutData). Health
  // Connect throws a SecurityException if we lack permission for ANY of them,
  // and the package swallows it and returns an EMPTY list — which looked like
  // "0 workouts". health 13.0.0 stopped auto-requesting DISTANCE_DELTA /
  // TOTAL_CALORIES_BURNED alongside WORKOUT, so they must be requested here.
  static const _authTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.HEART_RATE,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.STEPS,
  ];

  Future<HealthImportResult> importRecentWorkouts() async {
    await _health.configure();

    // Diagnostic (Android, no-ADB): capture the exact Health Connect SDK status
    // up front. The corporate Pixel 9 can't be inspected via logcat, so we fold
    // this status into any failure below — whatever UI surfaces
    // HealthImportException becomes our on-device readout of what HC thinks.
    HealthConnectSdkStatus? hcStatus;
    if (Platform.isAndroid) {
      hcStatus = await _health.getHealthConnectSdkStatus();
    }

    // Explicitly request READ-only access. The health package defaults to
    // READ_WRITE when permissions is omitted, but the Android manifest only
    // declares READ_* permissions — Health Connect denies the request.
    final authorized = await _health.requestAuthorization(
      _authTypes,
      permissions: _authTypes.map((_) => HealthDataAccess.READ).toList(),
    );
    if (!authorized) {
      throw HealthImportException(
        'Health permission was not granted.${_hcStatusSuffix(hcStatus)}',
      );
    }

    // Health data history authorization is an Android Health Connect concept.
    // On iOS/HealthKit all history is available once read access is granted.
    // The health package no-ops on iOS, but guard explicitly to be safe.
    var historyAuthorized = true;
    if (Platform.isAndroid) {
      historyAuthorized = await _health.isHealthDataHistoryAuthorized();
      if (!historyAuthorized) {
        historyAuthorized = await _health.requestHealthDataHistoryAuthorization();
      }
    }

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const HealthImportException('Sign in before importing activities.');
    }

    final source = Platform.isIOS ? 'healthkit' : 'health_connect';
    await _syncPendingActivities();
    // Always rescan the full lookback window. A forward-only watermark
    // permanently skips activities that a watch syncs into Health Connect
    // LATE with their original (earlier) timestamps — the #1 cause of
    // "0 imported" when the sessions are clearly present in Health Connect.
    // The upsert on (user_id, source, external_id) dedups the rescan, so
    // re-reading already-imported sessions is harmless.
    final importStart = start;
    final incrementalData = await _health.getHealthDataFromTypes(
      startTime: importStart,
      endTime: now,
      types: _readTypes,
    );
    final incrementalHeartRates = incrementalData
        .where((point) => point.type == HealthDataType.HEART_RATE)
        .toList();
    final incrementalWorkouts = incrementalData
        .where((point) => point.type == HealthDataType.WORKOUT)
        .toList();
    final incrementalDistances = incrementalData
        .where((point) => point.type == HealthDataType.DISTANCE_DELTA)
        .toList();

    // Fetch external_ids already in Supabase so we can distinguish truly new
    // imports from re-syncs of the same activity (the full-window rescan
    // intentionally re-reads everything to catch late-syncing watches).
    // If this lookup fails (offline / Supabase down), fall back to an empty
    // set — every activity counts as "new", which matches the old behaviour
    // and avoids blocking the import entirely.
    var existingIds = <String>{};
    try {
      final existingRows = await _client
          .from('activities')
          .select('external_id')
          .eq('user_id', user.id)
          .eq('source', source)
          .gte('started_at', importStart.toUtc().toIso8601String())
          .lte('started_at', now.toUtc().toIso8601String());
      existingIds = <String>{
        for (final row in existingRows as List<dynamic>)
          if (row['external_id'] != null) row['external_id'] as String,
      };
    } catch (_) {
      // Network failure — proceed with empty set (old behaviour).
    }

    var importedCount = 0;
    var queuedCount = 0;
    var skippedCount = 0;
    var alreadySyncedCount = 0;
    var nonWorkoutValues = 0;
    for (final workout in incrementalWorkouts) {
      final value = workout.value;
      if (value is! WorkoutHealthValue) {
        nonWorkoutValues++;
        continue;
      }

      // ── Cross-source dedup: skip imports that overlap with Outpace GPS ──
      // If the user tracked from Outpace AND their watch simultaneously,
      // the Outpace GPS activity is the primary record (has map route).
      // The import is redundant — skip it entirely so it never appears
      // in the feed and doesn't double-count points.
      final workoutType = _mapActivityType(value.workoutActivityType);
      if (await _overlapsOutpaceActivity(
        userId: user.id,
        start: workout.dateFrom.toUtc(),
        end: workout.dateTo.toUtc(),
      )) {
        skippedCount++;
        continue;
      }

      final heartRates = incrementalHeartRates
          .where(
            (sample) =>
                !sample.dateFrom.isBefore(workout.dateFrom) &&
                !sample.dateFrom.isAfter(workout.dateTo),
          )
          .map((sample) => sample.value)
          .whereType<NumericHealthValue>()
          .map((sample) => sample.numericValue.toInt())
          .toList();
      // ── Source-aware distance ─────────────────────────────────────
      // Health Connect's totalDistance sums ALL DistanceRecord entries
      // in the workout window regardless of source. If Garmin AND the
      // phone pedometer both write distance records, the result is
      // inflated by 10-20%. Fix: sum only the DISTANCE_DELTA records
      // from the same sourceId as the workout itself. Fall back to
      // totalDistance when no per-source records are available (iOS /
      // older data).
      final sourceAwareDistance = _computeSourceAwareDistance(
        workout: workout,
        distanceRecords: incrementalDistances,
        fallback: value.totalDistance?.toDouble(),
      );

      final activity = <String, dynamic>{
        'user_id': user.id,
        'type': workoutType,
        'started_at': workout.dateFrom.toUtc().toIso8601String(),
        'ended_at': workout.dateTo.toUtc().toIso8601String(),
        'distance_m': sourceAwareDistance?.round(),
        // NOTE: The health Flutter package does not expose moving time
        // separately from elapsed time for workouts — only dateFrom/dateTo.
        // Both fields get the wall-clock duration. This means pace is
        // calculated from elapsed (includes pauses) rather than true moving
        // time. Acceptable for now; a future improvement could estimate
        // moving time from route data or HR zones.
        'moving_time_s': workout.dateTo.difference(workout.dateFrom).inSeconds,
        'elapsed_s': workout.dateTo.difference(workout.dateFrom).inSeconds,
        'avg_hr': heartRates.isEmpty
            ? null
            : (heartRates.reduce((sum, rate) => sum + rate) / heartRates.length)
                  .round(),
        'max_hr': heartRates.isEmpty
            ? null
            : heartRates.reduce(
                (current, rate) => current > rate ? current : rate,
              ),
        'calories': value.totalEnergyBurned?.round(),
        'source': source,
        'external_id': workout.uuid,
        'status': 'pending',
      };
      await _localRepository.cacheActivity(activity, syncStatus: 'pending');
      // Local same-source dedup (belt-and-suspenders): checks against the
      // on-device cache for overlapping activities from the same source.
      // If the cache is stale (app reinstalled / cleared), this may miss a
      // duplicate — but the Supabase upsert on (user_id, source, external_id)
      // is the authoritative safety net and prevents actual data corruption.
      final duplicate = await _localRepository.flagDuplicateIfNeeded(activity);
      if (duplicate != null) {
        activity['review_state'] = 'needs_review';
        activity['dup_group_id'] = duplicate.groupId;
        await _localRepository.cacheActivity(activity, syncStatus: 'pending');
        await _syncActivity(duplicate.candidatePayload);
      }
      final isNew = !existingIds.contains(workout.uuid);
      try {
        if (await _syncActivity(activity)) {
          await _localRepository.markSynced(activity);
        } else {
          if (isNew) queuedCount++;
        }
        if (isNew) {
          importedCount++;
        } else {
          alreadySyncedCount++;
        }
      } catch (_) {
        rethrow;
      }
    }

    await _localRepository.saveWatermark(
      userId: user.id,
      source: source,
      importedThrough: now,
    );

    // ── Diagnostics (only when NOTHING came through) ────────────────────
    // Gather + persist the full read breakdown only in the problem case:
    // no imports AND no duplicates skipped. Successful imports and
    // "all duplicates" outcomes stay clean — no probe, no DB row, no
    // on-screen dump. (No ADB on the corporate Pixel, so when it IS empty we
    // surface this on-screen AND persist to import_diagnostics.)
    var diagnostics = '';
    if (importedCount == 0 && skippedCount == 0 && alreadySyncedCount == 0) {
      final perms = <String, String>{};
      for (final t in _authTypes) {
        try {
          final has = await _health.hasPermissions(
            [t],
            permissions: [HealthDataAccess.READ],
          );
          perms[t.name] = '${has ?? 'null'}';
        } catch (e) {
          perms[t.name] = 'err:$e';
        }
      }

      var probeWorkouts365 = -1; // -1 = probe not run
      String? probeError;
      try {
        final probe = await _health.getHealthDataFromTypes(
          startTime: now.subtract(const Duration(days: 365)),
          endTime: now,
          types: [HealthDataType.WORKOUT],
        );
        probeWorkouts365 =
            probe.where((p) => p.type == HealthDataType.WORKOUT).length;
      } catch (e) {
        probeError = e.toString();
      }

      final sample = incrementalWorkouts.isEmpty
          ? 'none'
          : '${incrementalWorkouts.first.value.runtimeType} '
                'uuid=${incrementalWorkouts.first.uuid}';

      final diag = <String, dynamic>{
        'platform': Platform.isIOS ? 'ios' : 'android',
        'hc_status': hcStatus?.name,
        'authorized': authorized,
        'history_authorized': historyAuthorized,
        'permissions': perms,
        'window_start': importStart.toIso8601String(),
        'window_end': now.toIso8601String(),
        'raw_total': incrementalData.length,
        'raw_workouts': incrementalWorkouts.length,
        'raw_heart_rates': incrementalHeartRates.length,
        'non_workout_values': nonWorkoutValues,
        'skipped_duplicates': skippedCount,
        'imported': importedCount,
        'queued': queuedCount,
        'probe_workouts_365d': probeWorkouts365,
        'probe_error': probeError,
        'first_workout_sample': sample,
      };
      await _recordDiagnostics(user.id, diag);
      diagnostics = _formatDiagnostics(diag);
    }

    return HealthImportResult(
      importedCount: importedCount,
      queuedCount: queuedCount,
      skippedDuplicates: skippedCount,
      alreadySyncedCount: alreadySyncedCount,
      historyAuthorized: historyAuthorized,
      diagnostics: diagnostics,
    );
  }

  Future<void> _syncPendingActivities() async {
    for (final pending in await _localRepository.pendingSyncs()) {
      final activity = _localRepository.decodePayload(pending);
      try {
        await _client
            .from('activities')
            .upsert(activity, onConflict: 'user_id,source,external_id');
        await _localRepository.markSynced(activity);
        await _localRepository.removePendingSync(pending.id);
      } catch (_) {
        continue;
      }
    }
  }

  Future<bool> _syncActivity(Map<String, dynamic> activity) async {
    try {
      await _client
          .from('activities')
          .upsert(activity, onConflict: 'user_id,source,external_id');
      return true;
    } catch (_) {
      await _localRepository.queueActivity(activity);
      return false;
    }
  }

  /// Returns true if [start]–[end] overlaps an existing Outpace GPS activity
  /// for the same user by more than 70% of the shorter activity's duration.
  /// This prevents imports from HealthKit / Health Connect from creating
  /// duplicates when the user tracked from both Outpace and their watch
  /// simultaneously.
  ///
  /// The check is **type-agnostic**: a walk in Outpace and a "mixed cardio"
  /// import from the watch ARE the same activity if the time windows overlap.
  /// Earlier versions required an exact type match, which caused duplicates
  /// when the watch auto-classified the activity differently.
  Future<bool> _overlapsOutpaceActivity({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    // Widen the query window by ±2 minutes to catch activities where the
    // watch and phone were started/stopped a few seconds apart.
    final windowStart = start.subtract(const Duration(minutes: 2));
    final windowEnd = end.add(const Duration(minutes: 2));

    // Query ALL Outpace GPS activities (any type) that overlap the window.
    final response = await _client
        .from('activities')
        .select('started_at, ended_at')
        .eq('user_id', userId)
        .eq('source', 'phone_gps')
        .lte('started_at', windowEnd.toIso8601String())
        .gte('ended_at', windowStart.toIso8601String());

    final candidates = response as List<dynamic>;
    if (candidates.isEmpty) return false;

    final importDuration = end.difference(start).inSeconds;
    if (importDuration <= 0) return false;

    for (final row in candidates) {
      final gpsStart = DateTime.parse(row['started_at'] as String);
      final gpsEnd = DateTime.parse(row['ended_at'] as String);
      final gpsDuration = gpsEnd.difference(gpsStart).inSeconds;
      if (gpsDuration <= 0) continue;

      // Calculate overlap using the ORIGINAL (non-widened) timestamps.
      final overlapStart = start.isAfter(gpsStart) ? start : gpsStart;
      final overlapEnd = end.isBefore(gpsEnd) ? end : gpsEnd;
      final overlapSecs = overlapEnd.difference(overlapStart).inSeconds;
      if (overlapSecs <= 0) continue;

      // 70% threshold (was 80%) — more forgiving when the watch and phone
      // disagree on exact start/stop times.
      final shorterDuration =
          importDuration < gpsDuration ? importDuration : gpsDuration;
      if (overlapSecs / shorterDuration > 0.7) {
        return true;
      }
    }
    return false;
  }

  /// Compute distance for a workout using only DistanceRecord entries from
  /// the same source app (sourceId) as the workout session itself.
  ///
  /// Health Connect stores DistanceRecords from ALL contributing apps (Garmin,
  /// Google Fit, Samsung Health, phone pedometer, etc.). The `health` package's
  /// `totalDistance` sums them all, which inflates the figure when multiple
  /// apps track simultaneously (e.g. Garmin watch + phone step counter).
  ///
  /// Strategy:
  /// 1. Filter DISTANCE_DELTA records to the workout's time window.
  /// 2. Group by sourceId.
  /// 3. Pick the group from the workout's own sourceId.
  /// 4. If no matching source records found, fall back to the LARGEST
  ///    single-source total (heuristic: the device that measured the full
  ///    session typically has the most distance).
  /// 5. If no distance records at all, fall back to `totalDistance`.
  double? _computeSourceAwareDistance({
    required HealthDataPoint workout,
    required List<HealthDataPoint> distanceRecords,
    required double? fallback,
  }) {
    // Filter to records within the workout window.
    final windowRecords = distanceRecords.where((d) {
      return !d.dateFrom.isBefore(workout.dateFrom) &&
          !d.dateTo.isAfter(
            workout.dateTo.add(const Duration(seconds: 30)),
          );
    }).toList();

    if (windowRecords.isEmpty) return fallback;

    // Group by sourceId and sum distance per source.
    final distanceBySource = <String, double>{};
    for (final record in windowRecords) {
      final value = record.value;
      if (value is NumericHealthValue) {
        distanceBySource[record.sourceId] =
            (distanceBySource[record.sourceId] ?? 0) +
                value.numericValue.toDouble();
      }
    }

    if (distanceBySource.isEmpty) return fallback;

    // Prefer the workout's own source.
    final workoutSource = workout.sourceId;
    if (distanceBySource.containsKey(workoutSource)) {
      return distanceBySource[workoutSource];
    }

    // Fallback: use the largest single-source distance (the recording
    // device that tracked the full session has the highest total).
    return distanceBySource.values.reduce((a, b) => a > b ? a : b);
  }

  /// Human-readable Health Connect status, appended to error messages so the
  /// device's actual state is visible on-screen (no ADB on the corporate
  /// Pixel 9). Uses only the documented enum constants so it compiles
  /// regardless of the enum's internal representation.
  String _hcStatusSuffix(HealthConnectSdkStatus? status) {
    if (!Platform.isAndroid) return '';
    final label = switch (status) {
      HealthConnectSdkStatus.sdkAvailable =>
        'sdkAvailable (Health Connect reachable — issue is elsewhere)',
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        'sdkUnavailableProviderUpdateRequired (device Health Connect is older '
            'than the app expects — update Health Connect on the device)',
      HealthConnectSdkStatus.sdkUnavailable =>
        'sdkUnavailable (Health Connect not installed/enabled)',
      _ => 'unknown',
    };
    return ' [HC status: $label]';
  }

  Future<void> _recordDiagnostics(String userId, Map<String, dynamic> diag) async {
    try {
      await _client.from('import_diagnostics').insert({
        'user_id': userId,
        'platform': diag['platform'],
        'payload': diag,
      });
    } catch (_) {
      // Best-effort: diagnostics must never break the import itself.
    }
  }

  String _formatDiagnostics(Map<String, dynamic> d) {
    final probeErr = d['probe_error'];
    return 'Diagnostics\n'
        'HC status: ${d['hc_status']}\n'
        'authorized: ${d['authorized']} | history: ${d['history_authorized']}\n'
        'perms: ${d['permissions']}\n'
        'window: ${d['window_start']} → ${d['window_end']}\n'
        'read: total=${d['raw_total']} workouts=${d['raw_workouts']} '
        'hr=${d['raw_heart_rates']} nonWorkoutVal=${d['non_workout_values']}\n'
        'skippedDup=${d['skipped_duplicates']} imported=${d['imported']} '
        'queued=${d['queued']}\n'
        'probe(365d workouts)=${d['probe_workouts_365d']}'
        '${probeErr != null ? ' probeErr=$probeErr' : ''}\n'
        'sample: ${d['first_workout_sample']}';
  }

  String _mapActivityType(HealthWorkoutActivityType type) {    return switch (type) {
      HealthWorkoutActivityType.RUNNING ||
      HealthWorkoutActivityType.RUNNING_TREADMILL => 'run',
      HealthWorkoutActivityType.WALKING => 'walk',
      HealthWorkoutActivityType.BIKING => 'cycle',
      HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING ||
      HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING ||
      HealthWorkoutActivityType.STRENGTH_TRAINING => 'strength',
      _ => 'other',
    };
  }
}

class HealthImportException implements Exception {
  const HealthImportException(this.message);

  final String message;
}
