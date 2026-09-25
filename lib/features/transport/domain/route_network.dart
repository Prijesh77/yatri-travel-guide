import '../../../core/geo/geo_point.dart';
import '../../../core/time/kathmandu_time.dart';

/// Parsed `routes.json`: fare models per mode, bus routes with ordered stops,
/// hubs and ride-hailing operators.
///
/// `routes.json` is generated from the transport data pack by
/// `tool/import_transport.py`; see the README.
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
    this.hubs = const [],
    this.operators = const [],
    this.disclaimer = '',
    this.source = '',
  });

  final int version;
  final String disclaimer;
  final String source;
  final NetworkSettings settings;
  final WalkModel walk;
  final HailedModel bikeTaxi;
  final HailedModel taxi;
  final BusModel bus;
  final Map<String, TransitStop> stops;
  final List<BusRoute> routes;
  final List<TransitHub> hubs;
  final List<RideOperator> operators;

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
      source: json['source'] as String? ?? '',
      settings: NetworkSettings.fromJson(json['network'] as Map<String, dynamic>),
      walk: WalkModel.fromJson(modes['walk'] as Map<String, dynamic>),
      bikeTaxi: HailedModel.fromJson(modes['bikeTaxi'] as Map<String, dynamic>),
      taxi: HailedModel.fromJson(modes['taxi'] as Map<String, dynamic>),
      bus: BusModel.fromJson(modes['bus'] as Map<String, dynamic>),
      stops: stops,
      routes: [
        for (final raw in json['routes'] as List) BusRoute.fromJson(raw as Map<String, dynamic>, stops),
      ],
      hubs: [
        for (final raw in (json['hubs'] as List? ?? const []))
          TransitHub.fromJson(raw as Map<String, dynamic>, stops),
      ],
      operators: [
        for (final raw in (json['operators'] as List? ?? const [])) RideOperator.fromJson(raw as Map<String, dynamic>),
      ],
    );
  }

  /// Stops sorted by distance from [point], nearest first.
  List<(TransitStop, double)> stopsNear(GeoPoint point, {double withinKm = double.infinity}) {
    final result = <(TransitStop, double)>[
      for (final s in stops.values)
        if (s.location.distanceKmTo(point) case final d when d <= withinKm) (s, d),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return result;
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
    this.routeDistanceFactor = 1.15,
    this.maxWalkToStopKm = 1.2,
    this.transferWalkKm = 0.4,
    this.rushHours = const [],
    this.rushHourSpeedFactor = 0.7,
  });

  /// Straight-line distance x factor = approximate road distance.
  final double roadDistanceFactor;

  /// Along a bus route, consecutive stops are close and roughly follow the
  /// road, so the detour factor is smaller.
  final double routeDistanceFactor;
  final double maxWalkToStopKm;

  /// How far someone will walk between stops to change buses.
  final double transferWalkKm;
  final List<TimeWindow> rushHours;
  final double rushHourSpeedFactor;

  bool isRushHour(DateTime t) => rushHours.any((w) => w.contains(t));

  factory NetworkSettings.fromJson(Map<String, dynamic> json) => NetworkSettings(
        roadDistanceFactor: (json['roadDistanceFactor'] as num?)?.toDouble() ?? 1.35,
        routeDistanceFactor: (json['routeDistanceFactor'] as num?)?.toDouble() ?? 1.15,
        maxWalkToStopKm: (json['maxWalkToStopKm'] as num?)?.toDouble() ?? 1.2,
        transferWalkKm: (json['transferWalkKm'] as num?)?.toDouble() ?? 0.4,
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

  int minutesFor(double km) => (km / speedKmh * 60).ceil();

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
    this.fareSpreadLow = 0.15,
    this.fareSpreadHigh = 0.15,
    this.night,
    this.nightMultiplier = 1,
    this.label = '',
  });

  final String label;
  final double speedKmh;
  final int pickupMinutes;
  final double baseFare;
  final double perKm;
  final double minFare;

  /// Fraction below / above the formula fare for the displayed range
  /// (bargaining, surge, traffic). A meter is exact at the low end.
  final double fareSpreadLow;
  final double fareSpreadHigh;
  final TimeWindow? night;
  final double nightMultiplier;

  factory HailedModel.fromJson(Map<String, dynamic> json) {
    final night = json['night'] as Map<String, dynamic>?;
    final spread = (json['fareSpread'] as num?)?.toDouble() ?? 0.15;
    return HailedModel(
      label: json['label'] as String? ?? '',
      speedKmh: (json['speedKmh'] as num).toDouble(),
      pickupMinutes: (json['pickupMinutes'] as num?)?.toInt() ?? 0,
      baseFare: (json['baseFare'] as num).toDouble(),
      perKm: (json['perKm'] as num).toDouble(),
      minFare: (json['minFare'] as num).toDouble(),
      fareSpreadLow: (json['fareSpreadLow'] as num?)?.toDouble() ?? spread,
      fareSpreadHigh: (json['fareSpreadHigh'] as num?)?.toDouble() ?? spread,
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

  /// Default service hours for routes that do not publish their own.
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

/// How sure we are that a stop is where we put it.
enum StopAccuracy {
  /// Within a few hundred metres.
  approx,

  /// Placed roughly (up to ~1-2 km off); verify before relying on it.
  rough;

  static StopAccuracy parse(String? value) => value == 'rough' ? rough : approx;
}

class TransitStop {
  const TransitStop({
    required this.id,
    required this.name,
    required this.location,
    this.accuracy = StopAccuracy.approx,
  });

  final String id;
  final String name;
  final GeoPoint location;
  final StopAccuracy accuracy;

  factory TransitStop.fromJson(Map<String, dynamic> json) => TransitStop(
        id: json['id'] as String,
        name: json['name'] as String,
        location: GeoPoint.fromJson(json),
        accuracy: StopAccuracy.parse(json['accuracy'] as String?),
      );

  @override
  bool operator ==(Object other) => other is TransitStop && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Where a route's data comes from, from most to least trustworthy.
enum RouteStatus {
  /// Operator's own 2026 website.
  verified,

  /// Announced (e.g. new night bus) but not confirmed running.
  announced,

  /// Mapped in OpenStreetMap.
  osm,

  /// Reported in the news; may have changed.
  reported,

  /// Listed by a local website.
  local,

  /// Older numbering / source; may be discontinued.
  historical,

  unverified;

  static RouteStatus parse(String? value) =>
      values.asNameMap()[value] ?? RouteStatus.unverified;

  bool get isVerified => this == verified;

  /// Extra minutes added when ranking journeys, so verified routes win ties
  /// and historical ones are only suggested when clearly better.
  int get rankingPenaltyMinutes => switch (this) {
        verified => 0,
        announced => 6,
        osm => 6,
        reported => 8,
        local => 8,
        unverified => 10,
        historical => 15,
      };
}

/// A bus/microbus line, usable in both directions.
class BusRoute {
  const BusRoute({
    required this.id,
    required this.name,
    required this.stops,
    this.operator = '',
    this.vehicle = 'Bus',
    this.status = RouteStatus.unverified,
    this.statusLabel = '',
    this.frequencyMinutes,
    this.serviceHours,
    this.flatFare,
    this.source = '',
    this.notes = '',
    this.missingStops = const [],
  });

  final String id;
  final String name;
  final String operator;
  final String vehicle;
  final RouteStatus status;
  final String statusLabel;
  final List<TransitStop> stops;
  final int? frequencyMinutes;

  /// Overrides the network default when set (e.g. night buses).
  final TimeWindow? serviceHours;

  /// Overrides the distance fare slabs when set.
  final int? flatFare;
  final String source;
  final String notes;

  /// Stops in the source data we could not place (dropped from [stops]).
  final List<String> missingStops;

  factory BusRoute.fromJson(Map<String, dynamic> json, Map<String, TransitStop> stops) {
    final ids = [for (final s in json['stops'] as List) s as String];
    if (ids.length < 2) throw FormatException('Route ${json['id']} needs at least 2 stops');
    final hours = json['serviceHours'] as Map<String, dynamic>?;
    return BusRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      operator: json['operator'] as String? ?? '',
      vehicle: json['vehicle'] as String? ?? 'Bus',
      status: RouteStatus.parse(json['status'] as String?),
      statusLabel: json['statusLabel'] as String? ?? '',
      stops: [
        for (final id in ids) stops[id] ?? (throw FormatException('Route ${json['id']} uses unknown stop "$id"')),
      ],
      frequencyMinutes: (json['frequencyMinutes'] as num?)?.toInt(),
      serviceHours: hours == null ? null : TimeWindow.fromJson(hours),
      flatFare: (json['flatFare'] as num?)?.toInt(),
      source: json['source'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      missingStops: [for (final s in (json['missingStops'] as List? ?? const [])) s as String],
    );
  }
}

class TransitHub {
  const TransitHub({required this.name, this.district = '', this.notes = '', this.stop});
  final String name;
  final String district;
  final String notes;
  final TransitStop? stop;

  factory TransitHub.fromJson(Map<String, dynamic> json, Map<String, TransitStop> stops) => TransitHub(
        name: json['name'] as String,
        district: json['district'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        stop: stops[json['stopId']],
      );
}

/// Taxi / ride-hailing operator, shown for information (no fixed routes).
class RideOperator {
  const RideOperator({
    required this.name,
    this.modes = '',
    this.pricing = '',
    this.fareInfo = '',
    this.status = '',
  });

  final String name;
  final String modes;
  final String pricing;
  final String fareInfo;
  final String status;

  factory RideOperator.fromJson(Map<String, dynamic> json) => RideOperator(
        name: json['name'] as String,
        modes: json['modes'] as String? ?? '',
        pricing: json['pricing'] as String? ?? '',
        fareInfo: json['fareInfo'] as String? ?? '',
        status: json['status'] as String? ?? '',
      );
}
