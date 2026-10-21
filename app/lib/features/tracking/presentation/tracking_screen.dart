import 'dart:async';

import 'package:activefriends/data/local/app_database.dart' as local;
import 'package:activefriends/data/services/last_activity_type_store.dart';
import 'package:activefriends/features/tracking/data/gps_tracker.dart';
import 'package:activefriends/features/tracking/data/tracking_local_repository.dart';
import 'package:activefriends/features/tracking/presentation/finished_activity_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Dark palette used throughout this screen.
const _bg = Color(0xFF111111);
const _tileBg = Color(0xFF252525);
const _tileBgDim = Color(0xFF1A1A1A);
const _labelColor = Color(0xFF888888);
const _labelDimColor = Color(0xFF555555);
const _valueColor = Colors.white;
const _valueDimColor = Color(0xFF555555);
const _bannerBg = Color(0xFF2D1A0A);
const _bannerColor = Color(0xFFE8924A);
const _recColor = Color(0xFFE05252);
const _selectorTeal = Color(0xFF006E69);

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, this.recoverySession});

  final local.TrackingSession? recoverySession;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _database = local.AppDatabase.shared;
  late final _localRepository = TrackingLocalRepository(_database);
  late final _tracker = GpsTracker(_localRepository);
  String _type = 'run';
  String? _sessionId;
  String? _ownerUserId;
  List<local.TrackingPoint> _recoveryRows = const [];
  TrackingSnapshot? _snapshot;
  Timer? _ticker;
  var _isRecording = false;
  var _isSaving = false;
  String? _message;
  bool _didSave = false;
  String? _activityId;
  bool _recVisible = true;
  Timer? _recBlinker;
  var _isExiting = false;
  var _isFinishing = false;
  Timer? _gpsErrorDismissTimer;

  void _startRecBlink() {
    _recBlinker?.cancel();
    _recBlinker = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) setState(() => _recVisible = !_recVisible);
    });
  }

  void _stopRecBlink() {
    _recBlinker?.cancel();
    _recBlinker = null;
    if (mounted) setState(() => _recVisible = true);
  }

  @override
  void initState() {
    super.initState();
    final recoverySession = widget.recoverySession;
    if (recoverySession != null) {
      _sessionId = recoverySession.id;
      _ownerUserId = recoverySession.ownerUserId;
      _type = recoverySession.activityType;
      _loadRecoveryPoints(recoverySession);
    } else {
      _loadLastActivityType();
    }
  }

  Future<void> _loadLastActivityType() async {
    final lastType = await LastActivityTypeStore.read();
    if (!mounted ||
        lastType == null ||
        !{'run', 'walk', 'cycle'}.contains(lastType)) {
      return;
    }
    setState(() => _type = lastType);
  }

  Future<void> _loadRecoveryPoints(local.TrackingSession session) async {
    final rows = await _localRepository.loadPoints(session.id);
    if (!mounted) return;
    final points = rows
        .map(
          (point) => TrackingPoint(
            latitude: point.latitude,
            longitude: point.longitude,
            timestamp: point.timestamp,
            elevation: point.elevation,
            accuracy: point.accuracy,
          ),
        )
        .toList();
    setState(() {
      _recoveryRows = rows;
      _snapshot = TrackingSnapshot(
        startedAt: session.startedAt,
        elapsed: DateTime.now().difference(session.startedAt),
        movingTime: Duration(seconds: session.movingTimeS),
        isAutoPaused: session.status == 'paused',
        isManuallyPaused: false,
        distanceM: session.distanceM,
        elevationGainM: session.elevationGainM,
        acceptedFixes: session.acceptedFixes,
        receivedFixes: session.acceptedFixes,
        rejectedAccuracyFixes: 0,
        rejectedSpeedFixes: 0,
        lastAccuracyM: points.lastOrNull?.accuracy,
        points: points,
      );
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recBlinker?.cancel();
    _gpsErrorDismissTimer?.cancel();
    _tracker.dispose();
    super.dispose();
  }

  void _selectActivityType(String type) {
    setState(() => _type = type);
    LastActivityTypeStore.write(type);
  }

  Future<void> _start() async {
    setState(() => _message = null);
    final recoverySession = widget.recoverySession;
    final isNewSession = recoverySession == null;
    try {
      if (isNewSession) {
        final sessionId = const Uuid().v4();
        _ownerUserId = Supabase.instance.client.auth.currentUser?.id;
        await _localRepository.createSession(
          id: sessionId,
          activityType: _type,
          startedAt: DateTime.now(),
          ownerUserId: _ownerUserId,
        );
        _sessionId = sessionId;
      }
      await _tracker.start(
        (snapshot) {
          if (mounted) setState(() => _snapshot = snapshot);
        },
        sessionId: _sessionId!,
        activityType: _type,
        restoredSession: recoverySession,
        restoredPoints: _recoveryRows,
        onError: (error) {
          if (!mounted) return;
          final msg = _friendlyGpsError(error);
          setState(() => _message = msg);
          // Auto-dismiss after 6 s — the position stream stays alive for
          // transient errors, so tracking resumes on its own.
          _gpsErrorDismissTimer?.cancel();
          _gpsErrorDismissTimer = Timer(const Duration(seconds: 6), () {
            if (mounted && _message == msg) {
              setState(() => _message = null);
            }
          });
        },
      );
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final snapshot = _tracker.snapshot;
        if (mounted && snapshot != null) setState(() => _snapshot = snapshot);
      });
      setState(() => _isRecording = true);
      _startRecBlink();
    } on TrackingException catch (error) {
      await _cleanupFailedStart(isNewSession);
      if (mounted) setState(() => _message = error.message);
    } catch (error) {
      // Any non-TrackingException (e.g. a platform/foreground-service error)
      // was previously swallowed, leaving an orphaned "active" session that
      // resurfaced as the recovery dialog on next launch. Surface it on screen.
      await _cleanupFailedStart(isNewSession);
      if (mounted) {
        final errorStr = error.toString().toLowerCase();
        final String userMessage;
        if (errorStr.contains('foreground') || errorStr.contains('notification')) {
          userMessage = 'Tracking requires notification permission to run in the background. '
              'Please enable notifications for Outpace in Settings.';
        } else if (errorStr.contains('permission') || errorStr.contains('denied')) {
          userMessage = 'Location permission is needed for GPS tracking. '
              'Please grant location access in Settings → Apps → Outpace.';
        } else if (errorStr.contains('location') || errorStr.contains('gps')) {
          userMessage = 'Could not access GPS. Make sure location services are enabled in Settings.';
        } else {
          userMessage = 'Could not start tracking. Check that location and notification '
              'permissions are enabled in Settings → Apps → Outpace.\n\nDetails: $error';
        }
        setState(() => _message = userMessage);
      }
    }
  }

  Future<void> _cleanupFailedStart(bool isNewSession) async {
    // Only delete a session we created in this call. A recovery session holds
    // the user's in-progress data and must never be destroyed on a failed start.
    if (!isNewSession) return;
    final sessionId = _sessionId;
    if (sessionId != null) await _localRepository.deleteSession(sessionId);
    _sessionId = null;
  }

  /// Translate raw platform GPS errors into short, actionable messages.
  /// The position stream stays alive for transient errors, so tracking
  /// resumes automatically — we just need to reassure the user.
  String _friendlyGpsError(Object error) {
    final s = error.toString();
    // iOS Core Location transient errors
    if (s.contains('kCLErrorDomain error 0') ||
        s.contains('kCLErrorDomain error 1')) {
      return 'GPS signal briefly lost — tracking will resume automatically.';
    }
    if (s.contains('kCLErrorDomain error 2')) {
      return 'Network issue affecting GPS — tracking continues.';
    }
    if (s.contains('kCLErrorDomain')) {
      return 'Temporary GPS issue — tracking continues.';
    }
    // Generic fallback
    return 'GPS hiccup — tracking continues. '
        'If this persists, check location permissions in Settings.';
  }

  Future<void> _pauseActivity() async {
    _stopRecBlink();
    await _tracker.pause();
    if (mounted) setState(() => _snapshot = _tracker.snapshot ?? _snapshot);
  }

  Future<void> _resumeActivity() async {
    await _tracker.resume();
    if (mounted) setState(() => _snapshot = _tracker.snapshot ?? _snapshot);
    _startRecBlink();
  }

  Future<void> _handleBack() async {
    if (_isExiting) return;
    if (!_isRecording) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity in progress'),
        content: const Text(
          'Do you want to keep tracking or discard this activity?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep tracking'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _recColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard activity'),
          ),
        ],
      ),
    );
    if (shouldDiscard != true || !mounted) return;
    setState(() => _isExiting = true);
    _stopRecBlink();
    _ticker?.cancel();
    await _tracker.stop();
    final sessionId = _sessionId;
    if (sessionId != null) {
      await _localRepository.deleteSession(sessionId);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    _isFinishing = true;
    _stopRecBlink();
    _ticker?.cancel();
    final snapshot = await _tracker.stop();
    if (!mounted) return;

    if (snapshot == null) {
      _isFinishing = false;
      setState(
        () => _message =
            'Activity is still being prepared. Please try Finish again.',
      );
      return;
    }

    setState(() {
      _snapshot = snapshot;
      _isRecording = false;
    });

    final shouldSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            FinishedActivitySummaryScreen(type: _type, snapshot: snapshot),
      ),
    );
    if (!mounted) return;

    if (shouldSave == true) {
      await _save();
    } else {
      // Covers both explicit discard (false) and back-navigation (null).
      final sessionId = _sessionId;
      if (sessionId != null) {
        _localRepository.deleteSession(sessionId).ignore();
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    }
    _isFinishing = false;
  }

  Future<void> _save() async {
    if (_didSave) return;
    final snapshot = _snapshot;
    if (snapshot == null) return;

    final current = Supabase.instance.client.auth.currentUser;
    if (current == null) {
      setState(
        () => _message =
            'You are signed out. Sign in to save this activity — it stays '
            'on this device until then.',
      );
      return;
    }

    // Account guard: an activity is stamped with the account that recorded it.
    // Saving under a different account is rejected by row-level security and
    // would mis-attribute the run, so require a deliberate choice instead of
    // failing silently. Legacy sessions (no owner) fall through and save.
    final owner = _ownerUserId;
    if (owner != null && owner != current.id) {
      final reassign = await _promptAccountMismatch();
      if (!mounted) return;
      if (reassign != true) {
        setState(
          () => _message =
              'This activity was recorded under a different account. Sign in '
              'as that account to save it — it stays on this device until then.',
        );
        return;
      }
      // Reassign to the current account with a fresh id, so the insert never
      // collides with a row owned by the original account.
      _ownerUserId = current.id;
      _activityId = const Uuid().v4();
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });
    final activityId = _activityId ??= _sessionId ?? const Uuid().v4();
    // Stable external_id: generated once per activity, reused across retries.
    // Previously a new UUID was created on every save attempt, which could
    // cause a second row if a stale queued sync replayed with the old id
    // while a retry succeeded with a new one.
    final externalId = _sessionId ?? activityId;
    const saveTimeout = Duration(seconds: 20);
    const maxRetries = 3;
    const retryDelays = [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)];

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0 && mounted) {
          setState(() => _message = 'Retrying… (attempt ${attempt + 1}/${maxRetries + 1})');
        }
        final endedAt = snapshot.startedAt.add(snapshot.elapsed);
        await Supabase.instance.client
            .from('activities')
            .upsert({
              'id': activityId,
              'user_id': current.id,
              'type': _type,
              'started_at': snapshot.startedAt.toUtc().toIso8601String(),
              'ended_at': endedAt.toUtc().toIso8601String(),
              'distance_m': snapshot.distanceM.round(),
              'moving_time_s': snapshot.movingTime.inSeconds,
              'elapsed_s': snapshot.elapsed.inSeconds,
              'source': 'phone_gps',
              'external_id': externalId,
              'track_summary': {
                'elevation_gain_m': snapshot.elevationGainM.round(),
                'max_speed_kmh': snapshot.maxSpeedKmh,
                'max_elevation_m': snapshot.maxElevationM,
              },
              'status': 'synced',
            }, onConflict: 'id')
            .timeout(saveTimeout);
        if (snapshot.points.isNotEmpty) {
          await Supabase.instance.client
              .from('track_points')
              .upsert([
                for (final indexedPoint in snapshot.points.indexed)
                  {
                    'activity_id': activityId,
                    'seq': indexedPoint.$1,
                    'lat': indexedPoint.$2.latitude,
                    'lon': indexedPoint.$2.longitude,
                    'ts': indexedPoint.$2.timestamp.toUtc().toIso8601String(),
                    'ele': indexedPoint.$2.elevation,
                    'accuracy': indexedPoint.$2.accuracy,
                  },
              ], onConflict: 'activity_id,seq')
              .timeout(saveTimeout);
        }
        final sessionId = _sessionId;
        if (sessionId != null) {
          _localRepository.deleteSession(sessionId).ignore();
        }
        _didSave = true;
        if (mounted) Navigator.of(context).pop(activityId);
        return;
      } on TimeoutException {
        if (attempt == maxRetries) {
          if (mounted) {
            setState(
              () => _message = 'Saving timed out after ${maxRetries + 1} attempts. '
                  'Your activity is still stored on this device. Try again when you have better signal.',
            );
          }
        }
      } catch (error) {
        final isNetworkError = error.toString().contains('SocketException') ||
            error.toString().contains('Failed host lookup') ||
            error.toString().contains('Connection refused') ||
            error.toString().contains('Network is unreachable') ||
            error.toString().contains('ClientException');
        if (!isNetworkError || attempt == maxRetries) {
          if (mounted) {
            final userMessage = isNetworkError
                ? 'No internet connection. Your activity is safe on this device — tap Save when you are back online.'
                : 'Activity could not be saved: $error';
            setState(() => _message = userMessage);
          }
          break;
        }
      }
      // Wait before retrying (exponential backoff).
      if (attempt < maxRetries) {
        await Future<void>.delayed(retryDelays[attempt]);
        if (!mounted) return;
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  /// Shown when the signed-in account differs from the one that recorded the
  /// activity. Returns true if the user chooses to claim it for the current
  /// account, false/null to keep it for the original account.
  Future<bool?> _promptAccountMismatch() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Different account'),
        content: const Text(
          'This activity was recorded while signed in as a different account. '
          'Sign in as that account to save it there, or save it under the '
          'account you are signed in with now.\n\n'
          'Your activity stays on this device either way.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save under this account'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecoverySave() async {
    final snapshot = _snapshot;
    if (snapshot == null || !mounted) return;
    final shouldSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            FinishedActivitySummaryScreen(type: _type, snapshot: snapshot),
      ),
    );
    if (shouldSave == true && mounted) await _save();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final isPaused = snapshot?.isPaused ?? false;
    final isActive = _isRecording || snapshot != null;
    final teal = Theme.of(context).colorScheme.primary;

    return PopScope<void>(
      canPop: !_isRecording,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: _bg,
          appBarTheme: AppBarTheme(
            backgroundColor: _bg,
            foregroundColor: _valueColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _isRecording
                  ? 'Recording ${_type[0].toUpperCase()}${_type.substring(1)}'
                  : (isActive ? 'Save activity' : 'Track activity'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBack,
            ),
            actions: [
              if (_isRecording)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: AnimatedOpacity(
                    opacity: isPaused || _recVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 100),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isPaused ? _bannerColor : _recColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPaused ? 'PAUSED' : 'REC',
                          style: TextStyle(
                            color: isPaused ? _bannerColor : _recColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          body: isActive
              ? _buildActiveBody(snapshot, isPaused, teal)
              : _buildPreActivity(teal),
        ),
      ),
    );
  }

  Widget _buildActiveBody(
    TrackingSnapshot? snapshot,
    bool isPaused,
    Color teal,
  ) {
    final dimmed = isPaused;
    final accuracyM = snapshot?.lastAccuracyM;
    final accepted = snapshot?.acceptedFixes ?? 0;
    final showGpsWeakBanner =
        _isRecording && !isPaused && accepted > 0 && (accuracyM ?? 0) > 25;

    return SafeArea(
      child: Column(
        children: [
          // Status banner — only for auto-pause and GPS weak
          if (snapshot?.isAutoPaused == true)
            _StatusBanner(
              icon: Icons.pause_rounded,
              text: 'Auto-paused · start moving to resume',
            )
          else if (showGpsWeakBanner)
            _StatusBanner(
              icon: Icons.gps_not_fixed,
              text: 'GPS signal weak · still tracking your route',
            ),

          // Tile grid — nudged above center so message+buttons sit closer to grid
          Expanded(
            child: Align(
              alignment: const Alignment(0, -0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Distance + Time
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 90,
                            child: _StatTile(
                              label: 'DISTANCE',
                              value: _distanceValue(snapshot?.distanceM ?? 0),
                              unit: 'km',
                              large: true,
                              dimmed: dimmed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 90,
                            child: _StatTile(
                              label: 'TIME',
                              value: _elapsedLabel(
                                snapshot?.elapsed ?? Duration.zero,
                              ),
                              dimmed: dimmed,
                              large: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2: Pace + Speed
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 90,
                            child: _StatTile(
                              label: 'PACE',
                              value: _paceValue(snapshot),
                              unit: '/km',
                              dimmed: dimmed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 90,
                            child: _StatTile(
                              label: 'SPEED',
                              value: _speedValue(snapshot),
                              unit: 'km/h',
                              dimmed: dimmed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 3: Elevation + GPS Signal
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 90,
                            child: _StatTile(
                              label: 'ELEVATION',
                              value:
                                  '${(snapshot?.elevationGainM ?? 0).round()}',
                              unit: 'm',
                              dimmed: dimmed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 90,
                            child: _GpsSignalTile(
                              accuracyM: accuracyM,
                              acceptedFixes: accepted,
                              dimmed: dimmed,
                              teal: teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Moving time — dimmed when zero, brighter when counting
                    if (snapshot != null)
                      Text(
                        'Moving time  ${_movingTimeLabel(snapshot.movingTime)}',
                        style: TextStyle(
                          color: snapshot.movingTime.inSeconds > 0
                              ? teal.withValues(alpha: 0.8)
                              : _labelDimColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Message + bottom buttons
          if (_message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _bannerColor, fontSize: 13),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: _isRecording
                ? Row(
                    children: [
                      // Pause / Resume circle button
                      GestureDetector(
                        onTap: isPaused ? _resumeActivity : _pauseActivity,
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _valueColor, width: 2),
                          ),
                          child: Icon(
                            isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: _valueColor,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 62,
                          child: FilledButton.icon(
                            onPressed: _finish,
                            style: FilledButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(31),
                              ),
                            ),
                            icon: const Icon(Icons.stop_rounded, size: 20),
                            label: const Text(
                              'Finish',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: widget.recoverySession != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton.icon(
                                onPressed: _start,
                                style: FilledButton.styleFrom(
                                  backgroundColor: teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text(
                                  'Resume activity',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _isSaving ? null : _showRecoverySave,
                                icon: const Icon(Icons.save_alt),
                                label: Text(
                                  _isSaving ? 'Saving...' : 'Save activity',
                                ),
                              ),
                            ],
                          )
                        : FilledButton.icon(
                            onPressed: _isSaving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            icon: const Icon(Icons.save_alt),
                            label: Text(
                              _isSaving ? 'Saving…' : 'Save activity',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreActivity(Color teal) {
    final activityLabel = switch (_type) {
      'run' => 'Run',
      'walk' => 'Walk',
      'cycle' => 'Cycle',
      _ => 'Activity',
    };
    final activityIcon = switch (_type) {
      'run' => Icons.directions_run_rounded,
      'walk' => Icons.directions_walk_rounded,
      'cycle' => Icons.directions_bike_rounded,
      _ => Icons.sports_rounded,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                backgroundColor: _tileBg,
                foregroundColor: _labelColor,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: _selectorTeal,
              ),
              segments: const [
                ButtonSegment(value: 'run', label: Text('Run')),
                ButtonSegment(value: 'walk', label: Text('Walk')),
                ButtonSegment(value: 'cycle', label: Text('Cycle')),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  _selectActivityType(selection.first),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 64,
              child: FilledButton.icon(
                onPressed: _start,
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: teal.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text(
                  'Start',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_message != null) ...[
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _bannerColor),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _tileBgDim,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: teal.withValues(alpha: 0.28)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: teal.withValues(alpha: 0.14),
                        border: Border.all(
                          color: teal.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(activityIcon, color: teal, size: 42),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '$activityLabel mode',
                      style: const TextStyle(
                        color: _valueColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your distance, pace, and route will be tracked here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _labelColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Labels ─────────────────────────────────────────────────────────────────

  static String _distanceValue(double meters) =>
      (meters / 1000).toStringAsFixed(2);

  static String _elapsedLabel(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  static String _movingTimeLabel(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  static String _paceValue(TrackingSnapshot? snapshot) {
    if (snapshot == null || snapshot.paceSecondsPerKm <= 0) return '--:--';
    final seconds = snapshot.paceSecondsPerKm.round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  static String _speedValue(TrackingSnapshot? snapshot) {
    if (snapshot == null ||
        snapshot.distanceM <= 0 ||
        snapshot.movingTime.inSeconds <= 0) {
      return '--.-';
    }
    final hours = snapshot.movingTime.inSeconds / 3600;
    return (snapshot.distanceM / 1000 / hours).toStringAsFixed(1);
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bannerBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: _bannerColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _bannerColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.unit,
    this.large = false,
    this.dimmed = false,
  });

  final String label;
  final String value;
  final String? unit;
  final bool large;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final valueStyle = large
        ? TextStyle(
            color: dimmed ? _valueDimColor : _valueColor,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1,
          )
        : TextStyle(
            color: dimmed ? _valueDimColor : _valueColor,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1,
          );
    final unitStyle = TextStyle(
      color: dimmed ? _valueDimColor : _valueColor,
      fontSize: large ? 16 : 13,
      fontWeight: FontWeight.w600,
    );

    return Container(
      decoration: BoxDecoration(
        color: dimmed ? _tileBgDim : _tileBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: dimmed ? _labelDimColor : _labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: valueStyle),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit!, style: unitStyle),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GpsSignalTile extends StatelessWidget {
  const _GpsSignalTile({
    required this.accuracyM,
    required this.acceptedFixes,
    required this.dimmed,
    required this.teal,
  });

  final double? accuracyM;
  final int acceptedFixes;
  final bool dimmed;
  final Color teal;

  int get _bars {
    if (acceptedFixes == 0 || accuracyM == null) return 0;
    if (accuracyM! <= 10) return 4;
    if (accuracyM! <= 25) return 3;
    if (accuracyM! <= 50) return 2;
    return 1;
  }

  String get _label {
    if (acceptedFixes == 0 || accuracyM == null) return 'No Signal';
    if (accuracyM! <= 10) return 'Good';
    if (accuracyM! <= 25) return 'Ok';
    if (accuracyM! <= 50) return 'Weak';
    return 'Poor';
  }

  Color get _signalColor {
    if (dimmed) return _valueDimColor;
    if (acceptedFixes == 0 || accuracyM == null || accuracyM! > 50) {
      return _labelColor;
    }
    if (accuracyM! <= 25) return teal;
    return _bannerColor; // orange for weak/poor
  }

  @override
  Widget build(BuildContext context) {
    final bars = _bars;
    final label = _label;
    final color = _signalColor;

    return Container(
      decoration: BoxDecoration(
        color: dimmed ? _tileBgDim : _tileBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'GPS SIGNAL',
            style: TextStyle(
              color: dimmed ? _labelDimColor : _labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 1; i <= 4; i++) ...[
                    if (i > 1) const SizedBox(width: 4),
                    Container(
                      width: 7,
                      height: 6.0 + (i * 5),
                      decoration: BoxDecoration(
                        color: i <= bars ? color : const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrackingException implements Exception {
  const TrackingException(this.message);

  final String message;
}
