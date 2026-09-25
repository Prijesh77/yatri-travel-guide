import 'dart:math' as math;

import '../../../core/geo/geo_point.dart';
import '../../alerts/domain/condition_alert.dart';
import 'route_network.dart';
import 'transport_option.dart';

/// Estimates door-to-door time and fare for each transport mode between two
/// points, using the fare models and sample routes in [RouteNetwork].
class FareEstimator {
  const FareEstimator(this.network);

  final RouteNetwork network;

  /// Below this distance, walking is the only sensible option.
  static const walkOnlyKm = 0.4;

  double roadKm(GeoPoint from, GeoPoint to) =>
      from.distanceKmTo(to) * network.settings.roadDistanceFactor;

  List<TransportOption> optionsFor(
    GeoPoint from,
    GeoPoint to,
    DateTime departure, {
    List<ConditionAlert> alerts = const [],
  }) {
    final km = roadKm(from, to);
    final options = <TransportOption>[];
    final walk = walkOption(km);
    if (walk != null) options.add(walk);
    if (km < walkOnlyKm) return options;

    final bandh = alerts.any((a) => a.type == AlertType.bandh && a.isActiveAt(departure));
    options
      ..add(hailedOption(TransportMode.bikeTaxi, km, departure, bandh: bandh))
      ..add(hailedOption(TransportMode.taxi, km, departure, bandh: bandh));
    final bus = busOption(from, to, departure, bandh: bandh);
    if (bus != null) options.add(bus);
    return options;
  }

  TransportOption? walkOption(double km) {
    final walk = network.walk;
    if (km > walk.maxKm) return null;
    return TransportOption(
      mode: TransportMode.walk,
      durationMinutes: math.max(1, (km / walk.speedKmh * 60).ceil()),
      fare: const FareRange.free(),
      distanceKm: km,
    );
  }

  TransportOption hailedOption(TransportMode mode, double km, DateTime departure, {bool bandh = false}) {
    assert(mode == TransportMode.taxi || mode == TransportMode.bikeTaxi);
    final model = mode == TransportMode.taxi ? network.taxi : network.bikeTaxi;
    final rush = network.settings.isRushHour(departure);
    final night = model.night?.contains(departure) ?? false;
    final speed = model.speedKmh * (rush ? network.settings.rushHourSpeedFactor : 1);
    return TransportOption(
      mode: mode,
      durationMinutes: model.pickupMinutes + (km / speed * 60).ceil(),
      fare: hailedFare(model, km, night: night),
      distanceKm: km,
      notes: [
        if (night && model.nightMultiplier != 1) TransportNote.nightFare,
        if (rush) TransportNote.rushHour,
        if (bandh) TransportNote.bandh,
      ],
    );
  }

  /// Fare range for a taxi / bike taxi ride of [km].
  FareRange hailedFare(HailedModel model, double km, {bool night = false}) {
    var fare = math.max(model.minFare, model.baseFare + model.perKm * km);
    if (night) fare *= model.nightMultiplier;
    return FareRange(
      _roundTo10(fare * (1 - model.fareSpread)),
      _roundTo10(fare * (1 + model.fareSpread)),
    );
  }

  /// Best direct bus between two points (within walking distance of a stop
  /// at each end), else a generic estimate for longer trips.
  TransportOption? busOption(GeoPoint from, GeoPoint to, DateTime departure, {bool bandh = false}) {
    final settings = network.settings;
    final bus = network.bus;
    final rush = settings.isRushHour(departure);
    final speed = bus.speedKmh * (rush ? settings.rushHourSpeedFactor : 1);
    final inService = bus.serviceHours.contains(departure) && !bandh;
    final notes = <TransportNote>[
      if (!bus.serviceHours.contains(departure)) TransportNote.noBusService,
      if (bandh) TransportNote.bandh,
      if (rush) TransportNote.rushHour,
    ];

    _BusMatch? best;
    for (final route in network.routes) {
      final match = _matchRoute(route, from, to, speed);
      if (match != null && (best == null || match.totalMinutes < best.totalMinutes)) best = match;
    }

    if (best != null) {
      return TransportOption(
        mode: TransportMode.bus,
        durationMinutes: best.totalMinutes,
        fare: FareRange.exact(best.route.flatFare ?? bus.fareForKm(best.rideKm)),
        distanceKm: best.rideKm,
        available: inService,
        notes: notes,
        routeName: best.route.name,
        vehicle: best.route.vehicle,
        boardAt: best.board.name,
        alightAt: best.alight.name,
        walkMinutes: best.walkMinutes,
      );
    }

    // No sample route: offer a rough estimate for trips too long to walk.
    final km = roadKm(from, to);
    if (km <= network.walk.maxKm) return null;
    const walkMinutes = 16; // to and from stops, both ends
    const transferMinutes = 10; // likely one change
    return TransportOption(
      mode: TransportMode.bus,
      durationMinutes: walkMinutes + bus.waitMinutes + transferMinutes + (km / speed * 60).ceil(),
      fare: FareRange.exact(bus.fareForKm(km)),
      distanceKm: km,
      available: inService,
      notes: [...notes, TransportNote.estimatedRoute],
      walkMinutes: walkMinutes,
    );
  }

  _BusMatch? _matchRoute(BusRoute route, GeoPoint from, GeoPoint to, double speedKmh) {
    final settings = network.settings;
    final walk = network.walk;
    _BusMatch? best;
    for (var i = 0; i < route.stops.length; i++) {
      final walkIn = from.distanceKmTo(route.stops[i].location);
      if (walkIn > settings.maxWalkToStopKm) continue;
      for (var j = 0; j < route.stops.length; j++) {
        if (i == j || route.stops[i].id == route.stops[j].id) continue;
        final walkOut = to.distanceKmTo(route.stops[j].location);
        if (walkOut > settings.maxWalkToStopKm) continue;

        final rideKm = _alongRouteKm(route, i, j) * settings.roadDistanceFactor;
        final walkMinutes = ((walkIn + walkOut) * settings.roadDistanceFactor / walk.speedKmh * 60).ceil();
        final wait = route.frequencyMinutes == null
            ? network.bus.waitMinutes
            : math.min(network.bus.waitMinutes, (route.frequencyMinutes! / 2).ceil());
        final total = walkMinutes + wait + (rideKm / speedKmh * 60).ceil();
        if (best == null || total < best.totalMinutes) {
          best = _BusMatch(route, route.stops[i], route.stops[j], rideKm, walkMinutes, total);
        }
      }
    }
    return best;
  }

  static double _alongRouteKm(BusRoute route, int i, int j) {
    final lo = math.min(i, j);
    final hi = math.max(i, j);
    var km = 0.0;
    for (var k = lo; k < hi; k++) {
      km += route.stops[k].location.distanceKmTo(route.stops[k + 1].location);
    }
    return km;
  }

  /// Picks the option used for itinerary timing, given the traveller's style.
  TransportOption? recommend(List<TransportOption> options, TravelStyle style) {
    final usable = options.where((o) => o.available).toList();
    if (usable.isEmpty) return options.isEmpty ? null : options.first;

    TransportOption? byMode(TransportMode m) {
      for (final o in usable) {
        if (o.mode == m) return o;
      }
      return null;
    }

    final walk = byMode(TransportMode.walk);
    final walkLimitKm = switch (style) {
      TravelStyle.budget => 2.0,
      TravelStyle.balanced => 1.5,
      TravelStyle.comfort => 0.8,
    };
    if (walk != null && walk.distanceKm <= walkLimitKm) return walk;

    final bus = byMode(TransportMode.bus);
    final bike = byMode(TransportMode.bikeTaxi);
    final taxi = byMode(TransportMode.taxi);

    return switch (style) {
      TravelStyle.budget => bus ?? bike ?? walk ?? taxi,
      TravelStyle.balanced => (bus != null && taxi != null && bus.durationMinutes <= taxi.durationMinutes * 1.5 + 10)
          ? bus
          : (walk != null && walk.distanceKm <= 2 ? walk : (taxi ?? bike ?? bus ?? walk)),
      TravelStyle.comfort => taxi ?? bike ?? bus ?? walk,
    };
  }

  static int _roundTo10(double v) => (v / 10).round() * 10;
}

class _BusMatch {
  const _BusMatch(this.route, this.board, this.alight, this.rideKm, this.walkMinutes, this.totalMinutes);
  final BusRoute route;
  final TransitStop board;
  final TransitStop alight;
  final double rideKm;
  final int walkMinutes;
  final int totalMinutes;
}
