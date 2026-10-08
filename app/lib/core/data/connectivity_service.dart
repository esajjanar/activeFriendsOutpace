import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton service that tracks network connectivity and exposes
/// a stream of online/offline transitions.
///
/// Usage:
///   await ConnectivityService.instance.initialize();
///   ConnectivityService.instance.onlineStream.listen((isOnline) { ... });
class ConnectivityService {
  ConnectivityService._();

  static final instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  /// Whether the device currently has a network connection.
  bool get isOnline => _isOnline;

  /// Broadcast stream that emits `true` on reconnect and `false` on disconnect.
  Stream<bool> get onlineStream => _controller.stream;

  /// Call once from main.dart before runApp.
  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _connected(result);
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final nowOnline = _connected(result);
      if (nowOnline != _isOnline) {
        _isOnline = nowOnline;
        _controller.add(nowOnline);
        if (kDebugMode) {
          debugPrint('[outpace][connectivity] ${nowOnline ? "online" : "offline"}');
        }
      }
    });
  }

  static bool _connected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
