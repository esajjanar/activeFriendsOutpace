import 'dart:async';

import 'package:activefriends/core/data/connectivity_service.dart';
import 'package:flutter/material.dart';

/// Wraps a child widget with an offline banner and auto-reload on reconnect.
///
/// When the device goes offline, a thin banner appears at the top:
///   "You're offline"
/// When the device comes back online, [onReconnect] is called automatically
/// so the screen can reload its data.
///
/// The child is always rendered — this is additive, not blocking.
class ConnectionAwareBuilder extends StatefulWidget {
  const ConnectionAwareBuilder({
    super.key,
    required this.child,
    this.onReconnect,
  });

  /// The screen content — always shown, even when offline.
  final Widget child;

  /// Called when the device transitions from offline → online.
  /// Typically triggers a data reload.
  final VoidCallback? onReconnect;

  @override
  State<ConnectionAwareBuilder> createState() =>
      _ConnectionAwareBuilderState();
}

class _ConnectionAwareBuilderState extends State<ConnectionAwareBuilder> {
  final _service = ConnectivityService.instance;
  late bool _isOnline;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _isOnline = _service.isOnline;
    _subscription = _service.onlineStream.listen((online) {
      if (!mounted) return;
      setState(() => _isOnline = online);
      if (online) {
        widget.onReconnect?.call();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: _isOnline
              ? const SizedBox.shrink()
              : Container(
                  width: double.infinity,
                  color: Colors.orange.shade800,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 16,
                        color: Colors.orange.shade50,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "You're offline",
                        style: TextStyle(
                          color: Colors.orange.shade50,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
