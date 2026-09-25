import 'dart:math' as math;

/// A latitude/longitude pair used throughout the domain layer.
///
/// The domain deliberately does not depend on a map package; the map layer
/// converts to `LatLng` at the edge.
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  static const _earthRadiusKm = 6371.0;

  /// Great-circle (haversine) distance in kilometres.
  double distanceKmTo(GeoPoint other) {
    final dLat = _rad(other.lat - lat);
    final dLng = _rad(other.lng - lng);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(other.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
  }

  /// Distance in km from this point to the segment [a]-[b]. Uses a local
  /// flat projection, which is accurate at valley scale.
  double distanceKmToSegment(GeoPoint a, GeoPoint b) {
    final kx = 111.32 * math.cos(_rad(lat));
    const ky = 110.57;
    final ax = (a.lng - lng) * kx, ay = (a.lat - lat) * ky;
    final bx = (b.lng - lng) * kx, by = (b.lat - lat) * ky;
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0 ? 0.0 : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0);
    final px = ax + t * dx, py = ay + t * dy;
    return math.sqrt(px * px + py * py);
  }

  static double _rad(double deg) => deg * math.pi / 180;

  factory GeoPoint.fromJson(Map<String, dynamic> json) =>
      GeoPoint((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

/// Rough bounds of the Kathmandu Valley, used for data validation and to
/// decide whether a device location is useful for distance scoring.
class ValleyBounds {
  static const south = 27.52;
  static const north = 27.82;
  static const west = 85.15;
  static const east = 85.58;
  static const center = GeoPoint(27.6915, 85.3420);

  static bool contains(GeoPoint p) =>
      p.lat >= south && p.lat <= north && p.lng >= west && p.lng <= east;
}
