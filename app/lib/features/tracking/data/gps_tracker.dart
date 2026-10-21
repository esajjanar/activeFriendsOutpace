import 'dart:async';
import 'dart:io' show Platform;

import 'package:activefriends/data/local/app_database.dart' as local;
import 'package:activefriends/features/tracking/data/tracking_local_repository.dart';
import 'package:geolocator/geolocator.dart';

class TrackingSnapshot {
  const TrackingSnapshot({
    required this.startedAt,
    required this.elapsed,
    required this.movingTime,
    required this.isAutoPaused,
    required this.isManuallyPaused,
    required this.distanceM,
    required this.elevationGainM,
    required this.acceptedFixes,
    required this.receivedFixes,
    required this.rejectedAccuracyFixes,
    required this.rejectedSpeedFixes,
    required this.lastAccuracyM,
    required this.points,
  });

  final DateTime startedAt;
  final Duration elapsed;
  final Duration movingTime;
  final bool isAutoPaused;
  final bool isManuallyPaused;

  bool get isPaused => isAutoPaused || isManuallyPaused;
  final double distanceM;
  final double elevationGainM;
  final int acceptedFixes;
  final int receivedFixes;
  final int rejectedAccuracyFixes;
  final int rejectedSpeedFixes;
  final double? lastAccuracyM;
  final List<TrackingPoint> points;

  double get paceSecondsPerKm =>
      distanceM <= 0 ? 0 : movingTime.inSeconds / (distanceM / 1000);

  double get maxSpeedKmh {
    var maximum = 0.0;
    for (var index = 1; index < points.length; index++) {
      final seconds = points[index].timestamp
          .difference(points[index - 1].timestamp)
          .inSeconds;
      if (seconds <= 0) continue;
      final segmentM = Geolocator.distanceBetween(
        points[index - 1].latitude,
        points[index - 1].longitude,
        points[index].latitude,
        points[index].longitude,
      );
      final speedKmh = segmentM / seconds * 3.6;
      if (speedKmh > maximum && speedKmh <= 43.2) maximum = speedKmh;
    }
    return maximum;
  }

  double get maxElevationM => points.isEmpty
      ? 0
      : points.map((point) => point.elevation).reduce((a, b) => a > b ? a : b);
}

class TrackingPoint {
  const TrackingPoint({
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

class GpsTracker {
  GpsTracker(this._localRepository);

  final TrackingLocalRepository _localRepository;
  StreamSubscription<Position>? _positions;
  Position? _previous;
  DateTime? _startedAt;
  double _distanceM = 0;
  double _elevationGainM = 0;
  Duration _movingTime = Duration.zero;
  DateTime? _belowPauseThresholdSince;
  bool _autoPaused = false;
  double _pauseThresholdMs = 0.7;
  double _resumeThresholdMs = 1.4;
  bool _manuallyPaused = false;
  String? _activeSessionId;
  int _acceptedFixes = 0;
  int _receivedFixes = 0;
  int _rejectedAccuracyFixes = 0;
  int _rejectedSpeedFixes = 0;
  double? _lastAccuracyM;
  final List<TrackingPoint> _points = [];

  TrackingSnapshot? get snapshot {
    final startedAt = _startedAt;
    if (startedAt == null) return null;
    return TrackingSnapshot(
      startedAt: startedAt,
      elapsed: DateTime.now().difference(startedAt),
      movingTime: _movingTime,
      isAutoPaused: _autoPaused,
      isManuallyPaused: _manuallyPaused,
      distanceM: _distanceM,
      elevationGainM: _elevationGainM,
      acceptedFixes: _acceptedFixes,
      receivedFixes: _receivedFixes,
      rejectedAccuracyFixes: _rejectedAccuracyFixes,
      rejectedSpeedFixes: _rejectedSpeedFixes,
      lastAccuracyM: _lastAccuracyM,
      points: List.unmodifiable(_points),
    );
  }

  Future<void> start(
    void Function(TrackingSnapshot snapshot) onUpdate, {
    required String sessionId,
    required String activityType,
    local.TrackingSession? restoredSession,
    List<local.TrackingPoint> restoredPoints = const [],
    void Function(Object error)? onError,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const TrackingException('Location services are turned off.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const TrackingException('Location permission was not granted.');
    }

    _startedAt = restoredSession?.startedAt ?? DateTime.now();
    _activeSessionId = sessionId;
    _manuallyPaused = false;
    _pauseThresholdMs = activityType == 'walk' ? 0.5 : 0.7;
    _resumeThresholdMs = activityType == 'walk' ? 0.8 : 1.4;
    _distanceM = restoredSession?.distanceM ?? 0;
    _elevationGainM = restoredSession?.elevationGainM ?? 0;
    _movingTime = Duration(seconds: restoredSession?.movingTimeS ?? 0);
    _acceptedFixes = restoredSession?.acceptedFixes ?? 0;
    _receivedFixes = 0;
    _rejectedAccuracyFixes = 0;
    _rejectedSpeedFixes = 0;
    _lastAccuracyM = null;
    _points
      ..clear()
      ..addAll(
        restoredPoints.map(
          (point) => TrackingPoint(
            latitude: point.latitude,
            longitude: point.longitude,
            timestamp: point.timestamp,
            elevation: point.elevation,
            accuracy: point.accuracy,
          ),
        ),
      );
    _previous = null;
    _autoPaused = restoredSession?.status == 'paused';
    _belowPauseThresholdSince = null;
    final LocationSettings settings;
    if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        activityType: ActivityType.fitness,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'OUTPACE is tracking',
          notificationText: 'Your activity is being recorded.',
          notificationChannelName: 'Activity tracking',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    _positions = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) async {
          _receivedFixes++;
          _lastAccuracyM = position.accuracy;
          if (position.accuracy > 50) {
            _rejectedAccuracyFixes++;
            return;
          }
          final previous = _previous;
          final speed = position.speed.isFinite ? position.speed : 0;
          if (!_autoPaused && speed < _pauseThresholdMs) {
            _belowPauseThresholdSince ??= position.timestamp;
            if (position.timestamp.difference(_belowPauseThresholdSince!) >=
                const Duration(seconds: 20)) {
              _autoPaused = true;
              await _localRepository.updateStatus(sessionId, 'paused');
            }
          } else if (!_autoPaused && speed >= _pauseThresholdMs) {
            _belowPauseThresholdSince = null;
          } else if (_autoPaused && speed > _resumeThresholdMs) {
            _autoPaused = false;
            _belowPauseThresholdSince = null;
            await _localRepository.updateStatus(sessionId, 'active');
          }
          if (previous != null) {
            final segmentM = Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              position.latitude,
              position.longitude,
            );
            final durationS = position.timestamp
                .difference(previous.timestamp)
                .inSeconds;
            final segmentSpeed = durationS <= 0 ? 0 : segmentM / durationS;
            if (segmentSpeed > 12) {
              _rejectedSpeedFixes++;
              return;
            }
            if (!_autoPaused && durationS > 0 && !_manuallyPaused) {
              _movingTime += Duration(seconds: durationS);
            }
            // ── Distance accumulation with noise suppression ──────────
            // GPS jitter inflates distance by 10-20% when raw Haversine
            // segments are summed without filtering (random walk effect).
            //
            // Guards:
            // 1. Both fixes must have accuracy ≤ 30 m — loose fixes
            //    bounce too much. We still ACCEPT the fix for the track
            //    polyline and for _previous advancement, but we do NOT
            //    count it towards distance.
            // 2. Segment must be ≥ 3 m — sub-3 m movements at cycling/
            //    running speed are almost certainly noise (at 15 km/h
            //    with 2 s intervals, real segments are ~8 m).
            // 3. Speed > 12 m/s already caught above (teleport gate).
            final bothAccurate =
                previous.accuracy <= 30 && position.accuracy <= 30;
            if (!_autoPaused && !_manuallyPaused && bothAccurate && segmentM >= 3) {
              _distanceM += segmentM;
              final climb = position.altitude - previous.altitude;
              if (climb >= 3 && previous.accuracy <= 20 && position.accuracy <= 20) {
                _elevationGainM += climb;
              }
            }
          }
          _previous = position;
          _acceptedFixes++;
          _points.add(
            TrackingPoint(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: position.timestamp,
              elevation: position.altitude,
              accuracy: position.accuracy,
            ),
          );
          final current = snapshot;
          if (current != null) {
            await _localRepository.savePoint(
              sessionId: sessionId,
              sequence: _points.length - 1,
              point: TrackingPointData(
                latitude: position.latitude,
                longitude: position.longitude,
                timestamp: position.timestamp,
                elevation: position.altitude,
                accuracy: position.accuracy,
              ),
              distanceM: _distanceM,
              elevationGainM: _elevationGainM,
              movingTimeS: _movingTime.inSeconds,
              status: _autoPaused ? 'paused' : 'active',
            );
            onUpdate(current);
          }
        }, onError: (Object error, StackTrace _) => onError?.call(error));
  }

  Future<void> pause() async {
    if (_manuallyPaused || _activeSessionId == null) return;
    _manuallyPaused = true;
    await _localRepository.updateStatus(_activeSessionId!, 'paused');
  }

  Future<void> resume() async {
    if (_activeSessionId == null) return;
    _manuallyPaused = false;
    _autoPaused = false;
    _belowPauseThresholdSince = null;
    await _localRepository.updateStatus(_activeSessionId!, 'active');
  }

  Future<TrackingSnapshot?> stop() async {
    await _positions?.cancel();
    _positions = null;
    return snapshot;
  }

  Future<void> dispose() => _positions?.cancel() ?? Future.value();
}

class TrackingException implements Exception {
  const TrackingException(this.message);

  final String message;

  @override
  String toString() => message;
}
