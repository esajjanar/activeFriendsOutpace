import 'package:activefriends/features/tracking/data/gps_tracker.dart';
import 'package:activefriends/core/presentation/date_time_format.dart';
import 'package:activefriends/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';


class FinishedActivitySummaryScreen extends StatelessWidget {
  const FinishedActivitySummaryScreen({
    super.key,
    required this.type,
    required this.snapshot,
  });

  final String type;
  final TrackingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(false);
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('Review activity')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            _typeLabel(type),
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Check your route and stats before sharing with the club.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            _dateLabel(snapshot.startedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          _RouteMap(points: snapshot.points),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.save_alt),
            label: const Text('Save activity'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Discard activity'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).extension<AppColors>()!.danger,
              side: BorderSide(
                color: Theme.of(context).extension<AppColors>()!.danger,
              ),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 2.2,
                children: [
                  _Metric(
                    label: 'Distance',
                    value:
                        '${(snapshot.distanceM / 1000).toStringAsFixed(2)} km',
                  ),
                  _Metric(
                    label: 'Elapsed time',
                    value: _durationLabel(snapshot.elapsed),
                  ),
                  _Metric(
                    label: 'Moving time',
                    value: _durationLabel(snapshot.movingTime),
                  ),
                  _Metric(label: 'Pace', value: _paceLabel(snapshot)),
                  _Metric(label: 'Avg speed', value: _speedLabel(snapshot)),
                  _Metric(
                    label: 'Elevation gain',
                    value: '${snapshot.elevationGainM.round()} m',
                  ),
                  _Metric(label: 'Max speed', value: _maxSpeedLabel(snapshot)),
                  _Metric(
                    label: 'Max elevation',
                    value: '${snapshot.maxElevationM.round()} m',
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

  static String _typeLabel(String value) => switch (value) {
    'run' => 'Run complete',
    'walk' => 'Walk complete',
    'cycle' => 'Cycle complete',
    _ => 'Activity complete',
  };

  static String _dateLabel(DateTime dateTime) =>
      formatShortLocalDateTime(dateTime);

  static String _durationLabel(Duration duration) =>
      '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

  static String _paceLabel(TrackingSnapshot snapshot) {
    if (snapshot.paceSecondsPerKm <= 0) return '--:-- /km';
    final seconds = snapshot.paceSecondsPerKm.round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} /km';
  }

  static String _speedLabel(TrackingSnapshot snapshot) {
    if (snapshot.distanceM <= 0 || snapshot.movingTime.inSeconds <= 0) {
      return '--.- km/h';
    }
    final hours = snapshot.movingTime.inSeconds / 3600;
    return '${(snapshot.distanceM / 1000 / hours).toStringAsFixed(1)} km/h';
  }

  static String _maxSpeedLabel(TrackingSnapshot snapshot) =>
      snapshot.maxSpeedKmh <= 0
      ? '--.- km/h'
      : '${snapshot.maxSpeedKmh.toStringAsFixed(1)} km/h';
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.points});

  final List<TrackingPoint> points;

  @override
  Widget build(BuildContext context) {
    final coordinates = points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
    if (coordinates.length < 2) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('A route map will appear after two GPS fixes.'),
      );
    }
    return SizedBox(
      height: 260,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.coordinates(
              coordinates: coordinates,
              padding: const EdgeInsets.all(24),
              maxZoom: 17,
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app.activefriends.app',
              tileProvider: NetworkTileProvider(
                silenceExceptions: true,
                abortObsoleteRequests: false,
              ),
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: coordinates,
                  color: const Color(0xFF3294cd),
                  strokeWidth: 5,
                  borderColor: Colors.white,
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
}
