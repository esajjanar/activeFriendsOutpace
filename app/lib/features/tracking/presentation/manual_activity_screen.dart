import 'package:activefriends/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ManualActivityScreen extends StatefulWidget {
  const ManualActivityScreen({super.key});

  @override
  State<ManualActivityScreen> createState() => _ManualActivityScreenState();
}

class _ManualActivityScreenState extends State<ManualActivityScreen> {
  String _type = 'strength';
  DateTime _date = DateTime.now();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '30');
  final _distanceController = TextEditingController();
  final _volumeController = TextEditingController();
  final _setsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  static const _types = ['run', 'walk', 'cycle', 'strength'];
  static const _labels = {'run': 'Run', 'walk': 'Walk', 'cycle': 'Cycle', 'strength': 'Strength'};
  static const _icons = {
    'run': Icons.directions_run,
    'walk': Icons.directions_walk,
    'cycle': Icons.directions_bike,
    'strength': Icons.fitness_center,
  };

  bool get _needsDistance => _type == 'run' || _type == 'walk' || _type == 'cycle';

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _distanceController.dispose();
    _volumeController.dispose();
    _setsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = DateTime(
        picked.year, picked.month, picked.day,
        _date.hour, _date.minute,
      ));
    }
  }

  Future<void> _save() async {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final totalSeconds = (hours * 60 + minutes) * 60;
    if (totalSeconds <= 0) {
      setState(() => _error = 'Enter a duration greater than zero.');
      return;
    }

    double? distanceM;
    if (_needsDistance) {
      final km = double.tryParse(_distanceController.text.trim());
      if (km == null || km <= 0) {
        setState(() => _error = 'Enter a valid distance in km.');
        return;
      }
      distanceM = km * 1000;
    }

    setState(() { _isSaving = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final startedAt = _date;
      final endedAt = startedAt.add(Duration(seconds: totalSeconds));
      final activityId = const Uuid().v4();

      await Supabase.instance.client.from('activities').insert({
        'id': activityId,
        'user_id': user.id,
        'type': _type,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt.toUtc().toIso8601String(),
        if (distanceM != null) 'distance_m': distanceM.round(),
        'moving_time_s': totalSeconds,
        'elapsed_s': totalSeconds,
        'source': 'manual',
        'external_id': const Uuid().v4(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
        'track_summary': {
          if (_type == 'strength' &&
              _volumeController.text.trim().isNotEmpty)
            'volume_kg': double.tryParse(_volumeController.text.trim()),
          if (_type == 'strength' &&
              _setsController.text.trim().isNotEmpty)
            'sets': int.tryParse(_setsController.text.trim()),
        },
        'status': 'synced',
      });

      if (mounted) Navigator.of(context).pop(activityId);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Log activity')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          24, 20, 24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Text('Activity type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in _types)
                ChoiceChip(
                  avatar: Icon(_icons[type], size: 16),
                  label: Text(_labels[type]!),
                  selected: _type == type,
                  onSelected: (_) => setState(() {
                    _type = type;
                    _distanceController.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Date', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_formatDate(_date)),
          ),
          const SizedBox(height: 24),
          Text('Duration', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Hours',
                    suffixText: 'h',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Minutes',
                    suffixText: 'min',
                  ),
                ),
              ),
            ],
          ),
          if (_needsDistance) ...[
            const SizedBox(height: 24),
            Text('Distance', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Distance',
                suffixText: 'km',
              ),
            ),
          ],
          if (_type == 'strength') ...[
            const SizedBox(height: 24),
            Text('Strength details (optional)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _volumeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(
                      labelText: 'Volume',
                      suffixText: 'kg',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Sets',
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text('Notes (optional)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Morning strength session',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: colors.accent)),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: Text(_isSaving ? 'Saving…' : 'Save activity'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) return 'Yesterday';
    return '${date.day} / ${date.month} / ${date.year}';
  }
}
