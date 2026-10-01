import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

/// A static (non-live) tracking map using OpenStreetMap tiles. Plots a
/// laundromat marker and a driver marker and a straight line between them.
/// No GPS streaming or routing — it reflects the last-known coordinates.
///
/// OpenStreetMap needs no API key or billing. Free tiles come with a fair-use
/// policy, so this is intended for demo/low-volume use.
class TrackingMap extends StatelessWidget {
  final LatLng laundromat;
  final LatLng? driver;
  final double height;

  /// When true, the map fills its parent (no fixed height, no rounded corners)
  /// and gestures are enabled — used as a full-screen background.
  final bool fill;

  const TrackingMap({
    super.key,
    required this.laundromat,
    this.driver,
    this.height = 220,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    // Center on the midpoint if we have both points, otherwise the laundromat.
    final center = driver == null
        ? laundromat
        : LatLng(
            (laundromat.latitude + driver!.latitude) / 2,
            (laundromat.longitude + driver!.longitude) / 2,
          );

    final map = Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
            interactionOptions: InteractionOptions(
              flags: fill
                  ? (InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom)
                  : InteractiveFlag.none,
            ),
          ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.washly.app',
                ),
            if (driver != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePath(driver!, laundromat),
                    strokeWidth: 4,
                    color: AppColors.primary.withValues(alpha: 0.7),
                    borderStrokeWidth: 2,
                    borderColor: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                _marker(
                  laundromat,
                  icon: Icons.local_laundry_service,
                  color: AppColors.primary,
                ),
                if (driver != null)
                  _marker(
                    driver!,
                    icon: Icons.delivery_dining,
                    color: AppColors.primaryDark,
                  ),
              ],
            ),
          ],
        ),
        // OSM attribution (required by their tile usage policy).
        Positioned(
          right: 4,
          bottom: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            color: Colors.white.withValues(alpha: 0.7),
            child: const Text(
              '© OpenStreetMap',
              style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );

    if (fill) return map;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(height: height, child: map),
    );
  }

  /// Build a synthetic, natural-looking route between two points. It's a
  /// quadratic Bézier curve bowed to one side with a little stepwise jitter,
  /// so it reads like a road path rather than a dead-straight line. Purely
  /// cosmetic (no routing API).
  List<LatLng> _routePath(LatLng from, LatLng to) {
    const segments = 24;
    final dLat = to.latitude - from.latitude;
    final dLng = to.longitude - from.longitude;

    // A control point offset perpendicular to the straight line, so the curve
    // bows out. Scaled to the distance; deterministic given the endpoints.
    final midLat = (from.latitude + to.latitude) / 2;
    final midLng = (from.longitude + to.longitude) / 2;
    const bow = 0.18; // how far the curve bows out
    final ctrlLat = midLat + (-dLng) * bow;
    final ctrlLng = midLng + (dLat) * bow;

    final points = <LatLng>[];
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final mt = 1 - t;
      // Quadratic Bézier: (1-t)^2*P0 + 2(1-t)t*C + t^2*P1
      var lat = mt * mt * from.latitude +
          2 * mt * t * ctrlLat +
          t * t * to.latitude;
      var lng = mt * mt * from.longitude +
          2 * mt * t * ctrlLng +
          t * t * to.longitude;

      // Small stepwise jitter in the middle to suggest turns (fades at the
      // endpoints). Deterministic (based on segment index), so it's stable.
      final taper = (t * (1 - t)) * 4; // 0 at ends, 1 at middle
      final wobble = ((i % 3) - 1) * 0.0006 * taper;
      lat += wobble;
      lng += wobble * 0.6;

      points.add(LatLng(lat, lng));
    }
    return points;
  }

  Marker _marker(LatLng point,
      {required IconData icon, required Color color}) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
