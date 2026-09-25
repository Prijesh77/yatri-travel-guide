import 'dart:math' as math;

import '../../../core/geo/geo_point.dart';
import '../../alerts/domain/condition_alert.dart';
import 'journey_planner.dart';
import 'route_network.dart';
import 'transport_option.dart';

/// Estimates door-to-door time and fare for each transport mode between two
/// points, using the fare models and bus routes in [RouteNetwork].
class FareEstimator {
  FareEstimator(this.network) : journeys = JourneyPlanner(network);

  final RouteNetwork network;
  final JourneyPlanner journeys;

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
      durationMinutes: math.max(1, walk.minutesFor(km)),
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
      _roundTo10(fare * (1 - model.fareSpreadLow)),
      _roundTo10(fare * (1 + model.fareSpreadHigh)),
    );
  }

  /// Best bus journey (direct or with one change), else a generic estimate
  /// for trips too long to walk.
  TransportOption? busOption(GeoPoint from, GeoPoint to, DateTime departure, {bool bandh = false}) {
    final settings = network.settings;
    final bus = network.bus;
    final rush = settings.isRushHour(departure);

    final found = journeys.plan(from, to, departure, maxResults: 1);
    if (found.isNotEmpty) return busOptionFor(found.first, departure, bandh: bandh);

    final km = roadKm(from, to);
    if (km <= network.walk.maxKm) return null;
    final inService = bus.serviceHours.contains(departure);
    final speed = bus.speedKmh * (rush ? settings.rushHourSpeedFactor : 1);
    const walkMinutes = 16; // to and from stops, both ends
    const transferMinutes = 10; // likely one change
    return TransportOption(
      mode: TransportMode.bus,
      durationMinutes: walkMinutes + bus.waitMinutes + transferMinutes + (km / speed * 60).ceil(),
      fare: FareRange.exact(bus.fareForKm(km)),
      distanceKm: km,
      available: inService && !bandh,
      notes: [
        if (!inService) TransportNote.noBusService,
        if (bandh) TransportNote.bandh,
        if (rush) TransportNote.rushHour,
        TransportNote.estimatedRoute,
      ],
      walkMinutes: walkMinutes,
    );
  }

  TransportOption busOptionFor(Journey journey, DateTime departure, {bool bandh = false}) {
    final rides = journey.rides;
    return TransportOption(
      mode: TransportMode.bus,
      durationMinutes: journey.totalMinutes,
      fare: FareRange.exact(journey.fare),
      distanceKm: journey.rideKm,
      available: !bandh,
      notes: [
        if (bandh) TransportNote.bandh,
        if (network.settings.isRushHour(departure)) TransportNote.rushHour,
        if (!journey.allVerified) TransportNote.unverifiedRoute,
      ],
      routeName: rides.first.route.name,
      vehicle: rides.first.route.vehicle,
      boardAt: rides.first.board.name,
      alightAt: rides.last.alight.name,
      walkMinutes: journey.walkMinutes,
      journey: journey,
    );
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
          : (taxi ?? bike ?? bus ?? walk),
      TravelStyle.comfort => taxi ?? bike ?? bus ?? walk,
    };
  }

  static int _roundTo10(double v) => (v / 10).round() * 10;
}
