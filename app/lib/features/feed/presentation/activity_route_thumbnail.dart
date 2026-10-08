import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityRouteThumbnail extends StatefulWidget {
  const ActivityRouteThumbnail({
    super.key,
    required this.activityId,
    this.interactive = false,
    this.height = 156,
    this.lightweight = false,
  });

  final String activityId;

  /// When true the user can pan and zoom the map.
  /// Keep false in scrollable lists (feed cards) to avoid gesture conflicts.
  final bool interactive;

  final double height;

  /// When true, renders a simple polyline on a dark background using
  /// [CustomPaint] instead of a full [FlutterMap] — dramatically cheaper
  /// to build, layout, and paint. Use this in scrolling lists (feed).
  final bool lightweight;

  @override
  State<ActivityRouteThumbnail> createState() => _ActivityRouteThumbnailState();
}

class _ActivityRouteThumbnailState extends State<ActivityRouteThumbnail> {
  late Future<List<LatLng>> _pointsFuture;

  @override
  void initState() {
    super.initState();
    _pointsFuture = _loadPoints(widget.activityId);
  }

  @override
  void didUpdateWidget(covariant ActivityRouteThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activityId != widget.activityId) {
      _pointsFuture = _loadPoints(widget.activityId);
    }
  }

  Future<List<LatLng>> _loadPoints(String activityId) async {
    const maxAttempts = 3;
    const timeout = Duration(seconds: 15);
    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        // Fetch the route via the activity_route RPC, which returns the
        // full route server-downsampled to ~800 points in a SINGLE row.
        // Reading track_points directly is capped by PostgREST max_rows
        // (1000), which truncated long rides to ~half the route; an RPC
        // payload is one row, so the cap never applies.
        final result = await Supabase.instance.client
            .rpc('activity_route', params: {'p_activity_id': activityId})
            .timeout(timeout);
        final rows = (result as List?) ?? const [];
        return rows
            .map(
              (row) => LatLng(
                (row['lat'] as num).toDouble(),
                (row['lon'] as num).toDouble(),
              ),
            )
            .toList();
      } catch (error) {
        lastError = error;
        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 500 * (1 << attempt)),
          );
        }
      }
    }
    throw lastError!;
  }

  List<LatLng> _displayPoints(List<LatLng> points) {
    const maximumPoints = 120;
    if (points.length <= maximumPoints) return points;
    final step = (points.length - 1) / (maximumPoints - 1);
    return [
      for (var index = 0; index < maximumPoints; index++)
        points[(index * step).round().clamp(0, points.length - 1)],
    ];
  }

  /// Route spread is negligible — all points cluster in one spot (GPS drift).
  bool _isDriftCluster(List<LatLng> points) {
    if (points.length < 2) return false;
    var minLat = points.first.latitude, maxLat = minLat;
    var minLon = points.first.longitude, maxLon = minLon;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    // Collapse to a dot ONLY for genuine stationary GPS jitter — both
    // dimensions under ~40 m. Real routes, even small park loops of a few
    // hundred metres, keep their trail. (Previously ~300 m, which wrongly
    // flattened small-radius activities into a single dot.)
    const driftThresholdM = 40.0;
    const metersPerDegLat = 111320.0;
    final midLatRad = ((minLat + maxLat) / 2) * math.pi / 180.0;
    final latSpanM = (maxLat - minLat) * metersPerDegLat;
    final lonSpanM =
        (maxLon - minLon) * metersPerDegLat * math.cos(midLatRad);
    return latSpanM < driftThresholdM && lonSpanM < driftThresholdM;
  }

  LatLng _centroid(List<LatLng> points) {
    var lat = 0.0, lon = 0.0;
    for (final p in points) {
      lat += p.latitude;
      lon += p.longitude;
    }
    return LatLng(lat / points.length, lon / points.length);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LatLng>>(
      future: _pointsFuture,
      builder: (context, snapshot) {
        final points = _displayPoints(snapshot.data ?? const <LatLng>[]);
        if (snapshot.connectionState != ConnectionState.done ||
            points.length < 2) {
          return const SizedBox.shrink();
        }
        final driftCluster = _isDriftCluster(points);
        final center = driftCluster ? _centroid(points) : null;

        // ── Lightweight renderer (feed thumbnails) ──
        // Delegates to _StaticMapThumbnail which renders FlutterMap once,
        // captures a raster snapshot after tiles load, then swaps to a flat
        // image. During scroll Flutter just composites a cached texture —
        // zero map-controller overhead per card.
        if (widget.lightweight) {
          return _StaticMapThumbnail(
            points: points,
            driftCluster: driftCluster,
            center: center ?? _centroid(points),
            height: widget.height,
          );
        }

        // ── Full FlutterMap renderer (detail / summary screens) ──
        return RepaintBoundary(
          child: Container(
            height: widget.height,
            margin: const EdgeInsets.only(top: 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center ?? LatLng(0, 0),
                initialZoom: driftCluster ? 15 : 1,
                maxZoom: 18,
                initialCameraFit: driftCluster
                    ? null
                    : CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(18),
                        maxZoom: 15,
                      ),
                interactionOptions: InteractionOptions(
                  flags: widget.interactive
                      ? InteractiveFlag.drag |
                            InteractiveFlag.flingAnimation |
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.doubleTapZoom |
                            InteractiveFlag.scrollWheelZoom
                      : InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'app.activefriends.app',
                  maxZoom: 18,
                  tileProvider: NetworkTileProvider(
                    silenceExceptions: true,
                    abortObsoleteRequests: false,
                  ),
                ),
                if (!driftCluster)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        color: const Color(0xFF3294cd),
                        strokeWidth: 4,
                        borderColor: Colors.white,
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),
                if (driftCluster)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center!,
                        width: 18,
                        height: 18,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF3294cd),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
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
      },
    );
  }
}

/// Renders a non-interactive [FlutterMap] with tiles + route, captures a raster
/// snapshot after tiles load, then swaps to a plain [RawImage]. During scroll
/// Flutter composites a cached GPU texture — zero widget-tree overhead.
///
/// Uses [AutomaticKeepAliveClientMixin] so the captured snapshot survives when
/// the card scrolls off-screen, avoiding re-fetch and re-capture on scroll-back.
class _StaticMapThumbnail extends StatefulWidget {
  const _StaticMapThumbnail({
    required this.points,
    required this.driftCluster,
    required this.center,
    required this.height,
  });

  final List<LatLng> points;
  final bool driftCluster;
  final LatLng center;
  final double height;

  @override
  State<_StaticMapThumbnail> createState() => _StaticMapThumbnailState();
}

class _StaticMapThumbnailState extends State<_StaticMapThumbnail>
    with AutomaticKeepAliveClientMixin {
  final _boundaryKey = GlobalKey();
  ui.Image? _rasterCache;

  @override
  bool get wantKeepAlive => _rasterCache != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleSnapshot();
    });
  }

  /// Waits for tiles to arrive, then captures the [RepaintBoundary] into a
  /// raster image. On failure the live FlutterMap stays visible (still usable,
  /// just not as cheap to scroll).
  Future<void> _scheduleSnapshot() async {
    // Give the tile layer time to fetch and paint tiles.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) return;

    try {
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: dpr);
      if (mounted) {
        setState(() => _rasterCache = image);
        updateKeepAlive();
      }
    } catch (_) {
      // Capture failed — the live FlutterMap remains; still functional.
    }
  }

  @override
  void dispose() {
    _rasterCache?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Container(
      height: widget.height,
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: _rasterCache != null
          // ── Frozen snapshot: just a flat texture, zero map overhead ──
          ? RawImage(
              image: _rasterCache,
              fit: BoxFit.fill,
              width: double.infinity,
              height: widget.height,
            )
          // ── Live FlutterMap: shown until snapshot is captured ──
          : RepaintBoundary(
              key: _boundaryKey,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: widget.center,
                    initialZoom: widget.driftCluster ? 15 : 1,
                    maxZoom: 18,
                    initialCameraFit: widget.driftCluster
                        ? null
                        : CameraFit.coordinates(
                            coordinates: widget.points,
                            padding: const EdgeInsets.all(18),
                            maxZoom: 15,
                          ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'app.activefriends.app',
                      maxZoom: 18,
                      tileProvider: NetworkTileProvider(
                        silenceExceptions: true,
                        abortObsoleteRequests: false,
                      ),
                    ),
                    if (!widget.driftCluster)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: widget.points,
                            color: const Color(0xFF3294cd),
                            strokeWidth: 4,
                            borderColor: Colors.white,
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                    if (widget.driftCluster)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: widget.center,
                            width: 18,
                            height: 18,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3294cd),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Draws a route polyline on a plain dark background — zero tile loads,
/// zero map-controller overhead. Perfect for feed-card thumbnails.
/// NOTE: Currently unused — retained as a fallback if snapshot approach
/// needs to be reverted.
class _RouteShapePainter extends CustomPainter {
  _RouteShapePainter(this.points);

  final List<LatLng> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Compute bounding box.
    var minLat = points.first.latitude, maxLat = minLat;
    var minLon = points.first.longitude, maxLon = minLon;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    final latSpan = maxLat - minLat;
    final lonSpan = maxLon - minLon;

    const padding = 16.0;
    final drawW = size.width - padding * 2;
    final drawH = size.height - padding * 2;
    if (drawW <= 0 || drawH <= 0) return;

    final scale = (latSpan == 0 && lonSpan == 0)
        ? 1.0
        : math.min(
            drawW / (lonSpan == 0 ? 1e-6 : lonSpan),
            drawH / (latSpan == 0 ? 1e-6 : latSpan),
          );

    final routeW = lonSpan * scale;
    final routeH = latSpan * scale;
    final offX = padding + (drawW - routeW) / 2;
    final offY = padding + (drawH - routeH) / 2;

    final path = ui.Path();
    for (var i = 0; i < points.length; i++) {
      final x = offX + (points[i].longitude - minLon) * scale;
      final y = offY + (maxLat - points[i].latitude) * scale; // flip Y
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // White glow behind the route line.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x44FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Route line.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3294cd)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_RouteShapePainter old) => !identical(old.points, points);
}
