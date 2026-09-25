import '../../../core/geo/geo_point.dart';
import '../../../core/time/kathmandu_time.dart';

/// Parsed `routes.json`: fare models per mode plus sample bus routes.
///
/// The format is intentionally simple (named stops + ordered stop lists) so
/// it can be regenerated from real GTFS / municipal data later.
class RouteNetwork {
  const RouteNetwork({
    required this.version,
    required this.settings,
    required this.walk,
    required this.bikeTaxi,
    required this.taxi,
    required this.bus,
    required this.stops,
    required this.routes,
    this.disclaimer = '',
  });

  final int version;
  final String disclaimer;
  final NetworkSettings settings;
  final WalkModel walk;
  final HailedModel bikeTaxi;
  final HailedModel taxi;
  final BusModel bus;
  final Map<String, TransitStop> stops;
  final List<BusRoute> routes;

  factory RouteNetwork.fromJson(Map<String, dynamic> json) {
    final modes = json['modes'] as Map<String, dynamic>;
    final stops = <String, TransitStop>{};
    for (final raw in json['stops'] as List) {
      final stop = TransitStop.fromJson(raw as Map<String, dynamic>);
      if (stops.containsKey(stop.id)) throw FormatException('Duplicate stop "${stop.id}"');
      stops[stop.id] = stop;
    }
    return RouteNetwork(
      version: (json['version'] as num?)?.toInt() ?? 0,
      disclaimer: json['disclaimer'] as String? ?? '',
      settings: NetworkSettings.fromJson(json['network'] as Map<String, dynamic>),
      walk: WalkModel.fromJson(modes['walk'] as Map<String, dynamic>),
      bikeTaxi: HailedModel.fromJson(modes['bikeTaxi'] as Map<String, dynamic>),
      taxi: HailedModel.fromJson(modes['taxi'] as Map<String, dynamic>),
      bus: BusModel.fromJson(modes['bus'] as Map<String, dynamic>),
      stops: stops,
      routes: [
        for (final raw in json['routes'] as List) BusRoute.fromJson(raw as Map<String, dynamic>, stops),
      ],
    );
  }
}

class TimeWindow {
  const TimeWindow(this.startMinute, this.endMinute);
  final int startMinute;
  final int endMinute;

  /// Handles windows that wrap past midnight (e.g. 21:00-06:00).
  bool contains(DateTime t) {
    final m = minuteOfDay(t);
    return startMinute <= endMinute
        ? m >= startMinute && m < endMinute
        : m >= startMinute || m < endMinute;
  }

  factory TimeWindow.fromJson(Map<String, dynamic> json) =>
      TimeWindow(parseHhMm(json['start'] as String), parseHhMm(json['end'] as String));
}

class NetworkSettings {
  const NetworkSettings({
    this.roadDistanceFactor = 1.35,
    this.maxWalkToStopKm = 1.2,
    this.rushHours = const [],
    this.rushHourSpeedFactor = 0.7,
  });

  /// Straight-line distance x factor = approximate road distance.
  final double roadDistanceFactor;
  final double maxWalkToStopKm;
  final List<TimeWindow> rushHours;
  final double rushHourSpeedFactor;

  bool isRushHour(DateTime t) => rushHours.any((w) => w.contains(t));

  factory NetworkSettings.fromJson(Map<String, dynamic> json) => NetworkSettings(
        roadDistanceFactor: (json['roadDistanceFactor'] as num?)?.toDouble() ?? 1.35,
        maxWalkToStopKm: (json['maxWalkToStopKm'] as num?)?.toDouble() ?? 1.2,
        rushHours: [
          for (final w in (json['rushHours'] as List? ?? const [])) TimeWindow.fromJson(w as Map<String, dynamic>),
        ],
        rushHourSpeedFactor: (json['rushHourSpeedFactor'] as num?)?.toDouble() ?? 0.7,
      );
}

class WalkModel {
  const WalkModel({required this.speedKmh, required this.maxKm});
  final double speedKmh;
  final double maxKm;

  factory WalkModel.fromJson(Map<String, dynamic> json) => WalkModel(
        speedKmh: (json['speedKmh'] as num).toDouble(),
        maxKm: (json['maxKm'] as num).toDouble(),
      );
}

/// Taxi or ride-hailing bike: base + per-km fare with a minimum.
class HailedModel {
  const HailedModel({
    required this.speedKmh,
    required this.pickupMinutes,
    required this.baseFare,
    required this.perKm,
    required this.minFare,
    this.fareSpread = 0.15,
    this.night,
    this.nightMultiplier = 1,
  });

  final double speedKmh;
  final int pickupMinutes;
  final double baseFare;
  final double perKm;
  final double minFare;

  /// +/- fraction for the displayed fare range (bargaining, traffic).
  final double fareSpread;
  final TimeWindow? night;
  final double nightMultiplier;

  factory HailedModel.fromJson(Map<String, dynamic> json) {
    final night = json['night'] as Map<String, dynamic>?;
    return HailedModel(
      speedKmh: (json['speedKmh'] as num).toDouble(),
      pickupMinutes: (json['pickupMinutes'] as num?)?.toInt() ?? 0,
      baseFare: (json['baseFare'] as num).toDouble(),
      perKm: (json['perKm'] as num).toDouble(),
      minFare: (json['minFare'] as num).toDouble(),
      fareSpread: (json['fareSpread'] as num?)?.toDouble() ?? 0.15,
      night: night == null ? null : TimeWindow.fromJson(night),
      nightMultiplier: (night?['multiplier'] as num?)?.toDouble() ?? 1,
    );
  }
}

class FareSlab {
  const FareSlab(this.upToKm, this.fare);
  final double upToKm;
  final int fare;
}

class BusModel {
  const BusModel({
    required this.speedKmh,
    required this.waitMinutes,
    required this.serviceHours,
    required this.fareSlabs,
  });

  final double speedKmh;
  final int waitMinutes;
  final TimeWindow serviceHours;

  /// Sorted by [FareSlab.upToKm].
  final List<FareSlab> fareSlabs;

  int fareForKm(double km) {
    for (final slab in fareSlabs) {
      if (km <= slab.upToKm) return slab.fare;
    }
    return fareSlabs.last.fare;
  }

  factory BusModel.fromJson(Map<String, dynamic> json) {
    final slabs = [
      for (final s in json['fareSlabs'] as List)
        FareSlab(((s as Map<String, dynamic>)['upToKm'] as num).toDouble(), (s['fare'] as num).toInt()),
    ]..sort((a, b) => a.upToKm.compareTo(b.upToKm));
    if (slabs.isEmpty) throw const FormatException('bus.fareSlabs must not be empty');
    return BusModel(
      speedKmh: (json['speedKmh'] as num).toDouble(),
      waitMinutes: (json['waitMinutes'] as num).toInt(),
      serviceHours: TimeWindow.fromJson(json['serviceHours'] as Map<String, dynamic>),
      fareSlabs: slabs,
    );
  }
}

class TransitStop {
  const TransitStop({required this.id, required this.name, required this.location});
  final String id;
  final String name;
  final GeoPoint location;

  factory TransitStop.fromJson(Map<String, dynamic> json) => TransitStop(
        id: json['id'] as String,
        name: json['name'] as String,
        location: GeoPoint.fromJson(json),
      );
}

/// A bus/microbus line, usable in both directions.
class BusRoute {
  const BusRoute({
    required this.id,
    required this.name,
    required this.stops,
    this.vehicle = 'Bus',
    this.frequencyMinutes,
    this.flatFare,
  });

  final String id;
  final String name;
  final String vehicle;
  final List<TransitStop> stops;
  final int? frequencyMinutes;

  /// Overrides the distance fare slabs when set.
  final int? flatFare;

  factory BusRoute.fromJson(Map<String, dynamic> json, Map<String, TransitStop> stops) {
    final ids = [for (final s in json['stops'] as List) s as String];
    if (ids.length < 2) throw FormatException('Route ${json['id']} needs at least 2 stops');
    return BusRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      vehicle: json['vehicle'] as String? ?? 'Bus',
      stops: [
        for (final id in ids) stops[id] ?? (throw FormatException('Route ${json['id']} uses unknown stop "$id"')),
      ],
      frequencyMinutes: (json['frequencyMinutes'] as num?)?.toInt(),
      flatFare: (json['flatFare'] as num?)?.toInt(),
    );
  }
}
