import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A bare animated refresh icon — no background, no border.
/// Full-opacity primary icon that spins while refreshing. The InkWell ripple
/// provides the button affordance on tap.
///
/// Pass [onRefresh] — a future-returning callback. The button auto-tracks the
/// loading state: it spins while the future is pending and stops when it
/// completes.
class AnimatedRefreshButton extends StatefulWidget {
  const AnimatedRefreshButton({
    super.key,
    required this.onRefresh,
    this.size = 24.0,
  });

  /// Called when the user taps the button. Return a [Future] that completes
  /// when the refresh is done — the spin animation tracks it automatically.
  final Future<void> Function() onRefresh;

  /// Icon size (default 24). The surrounding padding keeps the tap target
  /// comfortable.
  final double size;

  @override
  State<AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    _spin.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        // Finish the current rotation cleanly so it never stops mid-spin.
        await _spin.forward(from: _spin.value);
        _spin.reset();
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _refreshing ? null : _handleTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedBuilder(
            animation: _spin,
            builder: (context, child) {
              return Transform.rotate(
                angle: _spin.value * 2 * math.pi,
                child: child,
              );
            },
            child: Icon(
              Icons.sync,
              size: widget.size,
              color: primary.withValues(alpha: _refreshing ? 0.45 : 1.0),
            ),
          ),
        ),
      ),
    );
  }
}
