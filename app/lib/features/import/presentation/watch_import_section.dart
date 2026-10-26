import 'dart:developer' as developer;

import 'package:activefriends/features/import/data/health_import_service.dart';
import 'package:flutter/material.dart';

class WatchImportSection extends StatefulWidget {
  const WatchImportSection({super.key});

  @override
  State<WatchImportSection> createState() => _WatchImportSectionState();
}

class _WatchImportSectionState extends State<WatchImportSection> {
  final _service = HealthImportService();
  var _isImporting = false;
  String? _message;

  Future<void> _import() async {
    setState(() {
      _isImporting = true;
      _message = null;
    });
    try {
      final result = await _service.importRecentWorkouts();
      if (mounted) {
        setState(() {
          final parts = <String>[];
          if (result.importedCount > 0) {
            final a = result.importedCount == 1 ? 'activity' : 'activities';
            parts.add('${result.importedCount} new $a synced');
          }
          if (result.alreadySyncedCount > 0) {
            parts.add('${result.alreadySyncedCount} already synced');
          }
          if (result.skippedDuplicates > 0) {
            final a = result.skippedDuplicates == 1 ? 'activity' : 'activities';
            parts.add('${result.skippedDuplicates} $a tracked via Outpace');
          }
          if (result.queuedCount > 0) {
            parts.add('${result.queuedCount} queued for sync');
          }
          var summary = parts.isEmpty
              ? 'No new activities found in your health hub.'
              : '${parts.join(' · ')}.';
          if (!result.historyAuthorized) {
            summary = '$summary Older history was not authorized.';
          }
          // The raw diagnostics are non-empty only when nothing came through.
          _message = result.diagnostics.isEmpty
              ? summary
              : '$summary\n\n${result.diagnostics}';
        });
      }
    } on HealthImportException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (error, stack) {
      developer.log('Watch import failed', error: error, stackTrace: stack, name: 'WatchImport');
      if (mounted) setState(() => _message = 'Watch import could not finish.\n\nDetails: $error');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Health Connect or Apple Health', style: Theme.of(context).textTheme.bodyMedium)),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _import,
              icon: const Icon(Icons.watch_outlined, size: 18),
              label: Text(_isImporting ? 'Syncing' : 'Import'),
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          SelectableText(_message!),
        ],
      ],
    );
  }
}