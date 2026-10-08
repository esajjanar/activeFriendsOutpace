import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Full-screen error state shown when a screen fails to load.
/// Displays the app icon, offline illustration, error message, and retry button.
class OfflineErrorView extends StatelessWidget {
  const OfflineErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App icon
            Image.asset(
              'assets/icon-lines-only.png',
              width: 48,
              height: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Outpace',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            // Offline illustration
            SvgPicture.asset(
              'assets/offline_illustration.svg',
              width: 200,
              theme: SvgTheme(
                currentColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : const Color(0xFF5f6368),
              ),
            ),
            const SizedBox(height: 24),
            // Error message
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
