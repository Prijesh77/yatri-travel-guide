import 'dart:math' as math;

import '../../../core/geo/geo_point.dart';
import 'route_network.dart';

/// One part of a public-transport journey.
sealed class JourneyLeg {
  const JourneyLeg();
  int get minutes;
}

class WalkLeg extends JourneyLeg {
  const WalkLeg({required this.km, required this.minutes, this.toStop, this.fromStop});

  final double km;
  @override
  final int minutes;

  /// Null when walking from the origin / to the destination.
  final TransitStop? fromStop;
  final TransitStop? toStop;
}

class RideLeg extends JourneyLeg {
  const RideLeg({
    required this.route,
    required this.board,
    required this.alight,
    required this.stopCount,
    required this.km,
    required this.rideMinutes,
    required this.waitMinutes,
    required this.fare,
  });

  final BusRoute route;
  final TransitStop board;
  final TransitStop alight;

  /// Stops travelled (alight index - board index, absolute).
  final int stopCount;
  final double km;
  final int rideMinutes;
  final int waitMinutes;

  /// NPR per person.
  final int fare;

  @override
  int get minutes => rideMinutes + waitMinutes;
}

class Journey {
  const Journey(this.legs);

  final List<JourneyLeg> legs;

  List<RideLeg> get rides => [for (final l in legs) if (l is RideLeg) l];

  int get totalMinutes => legs.fold(0, (sum, l) => sum + l.minutes);
  int get walkMinutes => legs.whereType<WalkLeg>().fold(0, (sum, l) => sum + l.minutes);
  int get fare => rides.fold(0, (sum, r) => sum + r.fare);
  int get transfers => math.max(0, rides.length - 1);
  double get rideKm => rides.fold(0.0, (sum, r) => sum + r.km);

  /// Least trustworthy route used.
  RouteStatus get weakestStatus =>
      rides.map((r) => r.route.status).reduce((a, b) => a.index >= b.index ? a : b);

  bool get allVerified => rides.every((r) => r.route.status.isVerified);

  /// Uses a stop we could only place roughly.
  bool get hasRoughStop =>
      rides.any((r) => r.board.accuracy == StopAccuracy.rough || r.alight.accuracy == StopAccuracy.rough);

  String get key => rides.map((r) => r.route.id).join('>');

  /// Same stops for boarding, changing and alighting (routes may differ).
  String get stopSignature => rides.map((r) => '${r.board.id}-${r.alight.id}').join('>');
}

/// Journeys that use the same stops, e.g. SAJ-01, SAJ-02 and SAJ-04 all
/// running Lainchaur -> Tripureshwor. Shown as one "take any of these" option.
class JourneyGroup {
  JourneyGroup(this.journeys) : assert(journeys.isNotEmpty);

  /// Best first.
  final List<Journey> journeys;

  Journey get best => journeys.first;

  /// For each ride, the ids of routes that serve it.
  List<List<String>> get routeIdsPerRide => [
        for (var i = 0; i < best.rides.length; i++)
          <String>{for (final j in journeys) j.rides[i].route.id}.toList(),
      ];

  static List<JourneyGroup> group(List<Journey> journeys) {
    final bySignature = <String, List<Journey>>{};
    for (final j in journeys) {
      (bySignature[j.stopSignature] ??= []).add(j);
    }
    return [for (final list in bySignature.values) JourneyGroup(list)];
  }
}

/// Finds bus journeys between two points: walk to a stop, ride, optionally
/// change once, ride, walk to the destination.
///
/// The network is small (tens of routes), so an exhaustive search over
/// boarding / alighting / transfer stops is fast and easy to reason about.
class JourneyPlanner {
  JourneyPlanner(this.network)
      : _nearby = _buildNearby(network),
        _cumulativeKm = {
          for (final r in network.routes) r.id: _cumulative(r),
        };

  final RouteNetwork network;

  /// route id -> straight-line km from the first stop to each stop.
  final Map<String, List<double>> _cumulativeKm;

  static List<double> _cumulative(BusRoute route) {
    final out = <double>[0];
    for (var s = 1; s < route.stops.length; s++) {
      out.add(out.last + route.stops[s - 1].location.distanceKmTo(route.stops[s].location));
    }
    return out;
  }

  /// stopId -> (route, index) pairs within transfer walking distance.
  final Map<String, List<_RoutePos>> _nearby;

  static const transferPenaltyMinutes = 5;

  /// When nothing is within [NetworkSettings.maxWalkToStopKm], allow a longer
  /// walk to the nearest stops rather than giving up.
  static const fallbackWalkKm = 2.5;

  List<Journey> plan(
    GeoPoint from,
    GeoPoint to,
    DateTime departure, {
    int maxResults = 3,
    int maxTransfers = 1,
  }) {
    final settings = network.settings;
    final access = _stopsWithin(from);
    final egress = _stopsWithin(to);
    if (access.isEmpty || egress.isEmpty) return const [];

    final speed = network.bus.speedKmh * (settings.isRushHour(departure) ? settings.rushHourSpeedFactor : 1);
    final running = {
      for (final r in network.routes)
        if ((r.serviceHours ?? network.bus.serviceHours).contains(departure)) r.id,
    };

    // route id -> positions on that route within walking distance of `to`.
    final egressByRoute = <String, List<(int, double)>>{};
    for (final r in network.routes) {
      if (!running.contains(r.id)) continue;
      for (var j = 0; j < r.stops.length; j++) {
        final km = egress[r.stops[j].id];
        if (km != null) (egressByRoute[r.id] ??= []).add((j, km));
      }
    }

    // Best candidate per route combination.
    final best = <String, _Candidate>{};
    void consider(_Candidate c) {
      final existing = best[c.journey.key];
      if (existing == null || c.compareTo(existing) < 0) best[c.journey.key] = c;
    }

    for (final r1 in network.routes) {
      if (!running.contains(r1.id)) continue;
      for (var i = 0; i < r1.stops.length; i++) {
        final walkIn = access[r1.stops[i].id];
        if (walkIn == null) continue;

        // Direct.
        for (final (j, walkOut) in egressByRoute[r1.id] ?? const <(int, double)>[]) {
          final ride = _ride(r1, i, j, speed);
          if (ride == null) continue;
          consider(_Candidate(
            Journey([_walkIn(walkIn, r1.stops[i]), ride, _walkOut(walkOut, r1.stops[j])]),
            r1.status.rankingPenaltyMinutes,
          ));
        }

        // One transfer at stop k.
        if (maxTransfers < 1) continue;
        for (var k = 0; k < r1.stops.length; k++) {
          if (k == i) continue;
          RideLeg? ride1;
          for (final pos in _nearby[r1.stops[k].id] ?? const <_RoutePos>[]) {
            final r2 = pos.route;
            if (r2.id == r1.id) continue;
            final exits = egressByRoute[r2.id];
            if (exits == null) continue;
            for (final (j, walkOut) in exits) {
              if (j == pos.index) continue;
              ride1 ??= _ride(r1, i, k, speed);
              if (ride1 == null) break;
              final ride2 = _ride(r2, pos.index, j, speed);
              if (ride2 == null) continue;
              final transferKm = r1.stops[k].location.distanceKmTo(r2.stops[pos.index].location) *
                  settings.roadDistanceFactor;
              consider(_Candidate(
                Journey([
                  _walkIn(walkIn, r1.stops[i]),
                  ride1,
                  if (transferKm > 0.05)
                    WalkLeg(
                      km: transferKm,
                      minutes: network.walk.minutesFor(transferKm),
                      fromStop: r1.stops[k],
                      toStop: r2.stops[pos.index],
                    ),
                  ride2,
                  _walkOut(walkOut, r2.stops[j]),
                ]),
                r1.status.rankingPenaltyMinutes + r2.status.rankingPenaltyMinutes + transferPenaltyMinutes,
              ));
            }
          }
        }
      }
    }

    if (best.isEmpty) return const [];
    final candidates = best.values.toList()..sort((a, b) => a.compareTo(b));
    final bestCost = candidates.first.cost;
    final directRoutes = {for (final c in candidates) if (c.journey.transfers == 0) c.journey.key};
    final result = <Journey>[];
    for (final c in candidates) {
      if (c.cost > bestCost * 1.8 + 10) break;
      // A transfer journey that starts on a route which also goes direct adds nothing.
      if (c.journey.transfers > 0 && directRoutes.contains(c.journey.rides.first.route.id)) continue;
      result.add(c.journey);
      if (result.length == maxResults) break;
    }
    return result;
  }

  /// Prepares the origin side of [plan] once, so the best journey to many
  /// destinations from the same place and time can be found cheaply. The
  /// itinerary planner compares dozens of candidate places per step; running
  /// [plan] for each of them made planning take most of a second.
  ///
  /// `searchFrom(from, t).bestTo(to)` returns the same journey as
  /// `plan(from, to, t, maxResults: 1).firstOrNull`.
  JourneySearch searchFrom(GeoPoint from, DateTime departure) => JourneySearch._(this, from, departure);

  /// stopId -> road walking distance (km) from [point].
  Map<String, double> _stopsWithin(GeoPoint point) {
    final factor = network.settings.roadDistanceFactor;
    var near = network.stopsNear(point, withinKm: network.settings.maxWalkToStopKm);
    if (near.isEmpty) {
      near = network.stopsNear(point, withinKm: fallbackWalkKm).take(3).toList();
    }
    return {for (final (stop, km) in near) stop.id: km * factor};
  }

  WalkLeg _walkIn(double km, TransitStop stop) =>
      WalkLeg(km: km, minutes: network.walk.minutesFor(km), toStop: stop);

  WalkLeg _walkOut(double km, TransitStop stop) =>
      WalkLeg(km: km, minutes: network.walk.minutesFor(km), fromStop: stop);

  RideLeg? _ride(BusRoute route, int from, int to, double speedKmh) {
    final lo = math.min(from, to);
    final hi = math.max(from, to);
    final cum = _cumulativeKm[route.id]!;
    final km = (cum[hi] - cum[lo]) * network.settings.routeDistanceFactor;
    if (km < 0.3) return null;
    final wait = route.frequencyMinutes == null
        ? network.bus.waitMinutes
        : math.min(network.bus.waitMinutes, (route.frequencyMinutes! / 2).ceil());
    return RideLeg(
      route: route,
      board: route.stops[from],
      alight: route.stops[to],
      stopCount: hi - lo,
      km: km,
      rideMinutes: (km / speedKmh * 60).ceil(),
      waitMinutes: wait,
      fare: route.flatFare ?? network.bus.fareForKm(km),
    );
  }

  static Map<String, List<_RoutePos>> _buildNearby(RouteNetwork network) {
    final map = <String, List<_RoutePos>>{};
    for (final stop in network.stops.values) {
      final list = <_RoutePos>[];
      for (final route in network.routes) {
        for (var i = 0; i < route.stops.length; i++) {
          if (route.stops[i].location.distanceKmTo(stop.location) <= network.settings.transferWalkKm) {
            list.add(_RoutePos(route, i));
          }
        }
      }
      map[stop.id] = list;
    }
    return map;
  }
}

class _RoutePos {
  const _RoutePos(this.route, this.index);
  final BusRoute route;
  final int index;
}

class _Candidate {
  _Candidate(this.journey, int penalty) : cost = journey.totalMinutes + penalty;
  final Journey journey;
  final int cost;

  /// Cheapest cost first; ties go to the shorter, then the cheaper journey
  /// (a penalised route can tie a slower one).
  int compareTo(_Candidate other) => _compareJourney(
        cost,
        journey.totalMinutes,
        journey.fare,
        other.cost,
        other.journey.totalMinutes,
        other.journey.fare,
      );
}

int _compareJourney(int cost, int minutes, int fare, int otherCost, int otherMinutes, int otherFare) {
  if (cost != otherCost) return cost.compareTo(otherCost);
  if (minutes != otherMinutes) return minutes.compareTo(otherMinutes);
  return fare.compareTo(otherFare);
}

/// Best partial journeys from one origin, indexed by where they end. See
/// [JourneyPlanner.searchFrom].
class JourneySearch {
  JourneySearch._(this._planner, this.from, this.departure) {
    final network = _planner.network;
    final settings = network.settings;
    _access = _planner._stopsWithin(from);
    _speed = network.bus.speedKmh * (settings.isRushHour(departure) ? settings.rushHourSpeedFactor : 1);
    final routes = [
      for (final r in network.routes)
        if ((r.serviceHours ?? network.bus.serviceHours).contains(departure)) r,
    ];
    _running = {for (final r in routes) r.id};

    for (final r1 in routes) {
      for (var i = 0; i < r1.stops.length; i++) {
        final walkInKm = _access[r1.stops[i].id];
        if (walkInKm == null) continue;
        final walkIn = network.walk.minutesFor(walkInKm);

        // Direct rides ending at each stop j of r1.
        for (var j = 0; j < r1.stops.length; j++) {
          if (j == i) continue;
          final ride = _planner._ride(r1, i, j, _speed);
          if (ride == null) continue;
          final minutes = walkIn + ride.minutes;
          final candidate = _Partial(minutes + r1.status.rankingPenaltyMinutes, minutes, ride.fare, r1, i);
          final key = (r1.id, j);
          final existing = _direct[key];
          if (existing == null || candidate.beats(existing)) _direct[key] = candidate;
        }

        // One transfer at stop k of r1 onto r2 at position m, ending at j.
        for (var k = 0; k < r1.stops.length; k++) {
          if (k == i) continue;
          final ride1 = _planner._ride(r1, i, k, _speed);
          if (ride1 == null) continue;
          for (final pos in _planner._nearby[r1.stops[k].id] ?? const <_RoutePos>[]) {
            final r2 = pos.route;
            if (r2.id == r1.id || !_running.contains(r2.id)) continue;
            final transferKm =
                r1.stops[k].location.distanceKmTo(r2.stops[pos.index].location) * settings.roadDistanceFactor;
            final transferWalk = transferKm > 0.05 ? network.walk.minutesFor(transferKm) : 0;
            final prefixMinutes = walkIn + ride1.minutes + transferWalk;
            final penalty = r1.status.rankingPenaltyMinutes +
                r2.status.rankingPenaltyMinutes +
                JourneyPlanner.transferPenaltyMinutes;
            for (var j = 0; j < r2.stops.length; j++) {
              if (j == pos.index) continue;
              final ride2 = _planner._ride(r2, pos.index, j, _speed);
              if (ride2 == null) continue;
              final minutes = prefixMinutes + ride2.minutes;
              final candidate =
                  _Partial(minutes + penalty, minutes, ride1.fare + ride2.fare, r1, i, k: k, r2: r2, m: pos.index);
              final byFirst = _transfer[(r2.id, j)] ??= {};
              final existing = byFirst[r1.id];
              if (existing == null || candidate.beats(existing)) byFirst[r1.id] = candidate;
            }
          }
        }
      }
    }
  }

  final JourneyPlanner _planner;
  final GeoPoint from;
  final DateTime departure;

  late final Map<String, double> _access;
  late final double _speed;
  late final Set<String> _running;

  /// (route id, stop index) -> cheapest direct ride ending there (cost
  /// without the final walk).
  final _direct = <(String, int), _Partial>{};

  /// (second route id, stop index) -> first route id -> cheapest one-transfer
  /// journey ending there.
  final _transfer = <(String, int), Map<String, _Partial>>{};

  /// The best journey to [to], or null when no bus journey is found.
  Journey? bestTo(GeoPoint to) {
    if (_access.isEmpty) return null;
    final egress = _planner._stopsWithin(to);
    if (egress.isEmpty) return null;
    final walk = _planner.network.walk;

    // Exits: positions on running routes within walking distance of `to`.
    final exits = <(BusRoute, int, double)>[];
    for (final r in _planner.network.routes) {
      if (!_running.contains(r.id)) continue;
      for (var j = 0; j < r.stops.length; j++) {
        final km = egress[r.stops[j].id];
        if (km != null) exits.add((r, j, km));
      }
    }

    _Partial? best;
    int? bestJ;
    double? bestOutKm;
    var bestCost = 1 << 30;
    var bestMinutes = 1 << 30;
    var bestFare = 1 << 30;
    bool better(int cost, int minutes, int fare) =>
        _compareJourney(cost, minutes, fare, bestCost, bestMinutes, bestFare) < 0;
    var cheapest = 1 << 30;
    final directRoutes = <String>{};
    for (final (r, j, km) in exits) {
      final d = _direct[(r.id, j)];
      if (d == null) continue;
      directRoutes.add(r.id);
      final out = walk.minutesFor(km);
      if (better(d.cost + out, d.minutes + out, d.fare)) {
        (best, bestJ, bestOutKm, bestCost, bestMinutes, bestFare) = (d, j, km, d.cost + out, d.minutes + out, d.fare);
      }
    }
    for (final (r, j, km) in exits) {
      final byFirst = _transfer[(r.id, j)];
      if (byFirst == null) continue;
      for (final MapEntry(key: firstRoute, value: t) in byFirst.entries) {
        // As in [JourneyPlanner.plan]: changing off a route that also goes
        // direct adds nothing.
        final out = walk.minutesFor(km);
        if (t.cost + out < cheapest) cheapest = t.cost + out;
        if (directRoutes.contains(firstRoute)) continue;
        if (better(t.cost + out, t.minutes + out, t.fare)) {
          (best, bestJ, bestOutKm, bestCost, bestMinutes, bestFare) = (t, j, km, t.cost + out, t.minutes + out, t.fare);
        }
      }
    }
    if (cheapest > bestCost) cheapest = bestCost;
    // Same cut-off as [JourneyPlanner.plan]: options far worse than the
    // cheapest one found are not offered.
    if (best == null || bestCost > cheapest * 1.8 + 10) return null;
    return _build(best, bestJ!, bestOutKm!);
  }

  Journey _build(_Partial p, int j, double walkOutKm) {
    final planner = _planner;
    final r1 = p.r1;
    final walkIn = planner._walkIn(_access[r1.stops[p.i].id]!, r1.stops[p.i]);
    if (p.r2 == null) {
      return Journey([walkIn, planner._ride(r1, p.i, j, _speed)!, planner._walkOut(walkOutKm, r1.stops[j])]);
    }
    final r2 = p.r2!;
    final transferKm = r1.stops[p.k!].location.distanceKmTo(r2.stops[p.m!].location) *
        planner.network.settings.roadDistanceFactor;
    return Journey([
      walkIn,
      planner._ride(r1, p.i, p.k!, _speed)!,
      if (transferKm > 0.05)
        WalkLeg(
          km: transferKm,
          minutes: planner.network.walk.minutesFor(transferKm),
          fromStop: r1.stops[p.k!],
          toStop: r2.stops[p.m!],
        ),
      planner._ride(r2, p.m!, j, _speed)!,
      planner._walkOut(walkOutKm, r2.stops[j]),
    ]);
  }
}

/// Start of a journey: board r1 at i; for transfers, change at k onto r2 at m.
class _Partial {
  _Partial(this.cost, this.minutes, this.fare, this.r1, this.i, {this.k, this.r2, this.m});

  /// Minutes plus ranking penalties, without the final walk.
  final int cost;

  /// Travel minutes without the final walk; breaks ties in [cost].
  final int minutes;

  /// NPR for the rides; breaks remaining ties.
  final int fare;

  bool beats(_Partial other) => _compareJourney(cost, minutes, fare, other.cost, other.minutes, other.fare) < 0;
  final BusRoute r1;
  final int i;
  final int? k;
  final BusRoute? r2;
  final int? m;
}
