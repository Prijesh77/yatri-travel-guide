import '../../../core/geo/geo_point.dart';
import '../../alerts/domain/condition_alert.dart';
import '../../places/domain/opening_hours.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_category.dart';
import '../../recommendations/domain/recommendation_context.dart';
import '../../recommendations/domain/recommendation_engine.dart';
import '../../transport/domain/fare_estimator.dart';
import '../../weather/domain/weather.dart';
import 'itinerary.dart';

/// Builds a day plan and re-times it after edits.
///
/// Planning is greedy: from the current position and time, pick the place
/// with the best condition-aware score at its arrival time, minus a cost for
/// travel time and for repeating a category, as long as it is open for the
/// visit and fits before the end of the day.
class ItineraryPlanner {
  const ItineraryPlanner({
    required this.engine,
    required this.estimator,
    this.travelMinuteCost = 0.25,
    this.categoryRepeatCost = 7,
    this.minScore = 5,
    this.maxWaitMinutes = 30,
    this.minMinutesBetweenMeals = 210,
  });

  final RecommendationEngine engine;
  final FareEstimator estimator;

  /// Score points lost per minute of travel to reach a candidate.
  final double travelMinuteCost;

  /// Score points lost per earlier stop of the same category (variety).
  final double categoryRepeatCost;

  /// Places scoring below this at their slot are not added.
  final double minScore;

  /// How long we are willing to wait for a place to open.
  final int maxWaitMinutes;

  /// Minimum gap between two food stops when two are allowed.
  final int minMinutesBetweenMeals;

  Itinerary plan(
    ItineraryRequest request,
    List<Place> places, {
    WeatherReport? weather,
    List<ConditionAlert> alerts = const [],
  }) {
    final chosen = <Place>[];
    final categoryCount = <PlaceCategory, int>{};
    var position = request.start.location;
    var time = request.startTime;
    DateTime? lastMeal;

    while (chosen.length < request.maxStops) {
      Place? best;
      double bestUtility = double.negativeInfinity;
      DateTime? bestDeparture;

      for (final place in places) {
        if (chosen.contains(place)) continue;
        final options = estimator.optionsFor(position, place.location, time, alerts: alerts);
        final leg = estimator.recommend(options, request.travelStyle);
        if (leg == null || !leg.available) continue;

        final arrival = time.add(Duration(minutes: leg.durationMinutes));
        final visitStart = _visitStart(place, arrival);
        if (visitStart == null) continue;
        final departure = visitStart.add(Duration(minutes: place.visitMinutes));
        if (departure.isAfter(request.endTime)) continue;
        if (!place.openingHours.isOpenFor(visitStart, place.visitMinutes)) continue;
        if (place.category == PlaceCategory.food && !_mealFits(request, categoryCount, lastMeal, visitStart)) {
          continue;
        }

        final scored = engine.score(place, _context(request, visitStart, weather, alerts));
        if (!scored.isAvailable || scored.score < minScore) continue;

        final waited = visitStart.difference(arrival).inMinutes;
        final utility = scored.score -
            travelMinuteCost * (leg.durationMinutes + waited) -
            categoryRepeatCost * (categoryCount[place.category] ?? 0);
        if (utility > bestUtility) {
          best = place;
          bestUtility = utility;
          bestDeparture = departure;
        }
      }

      if (best == null) break;
      chosen.add(best);
      categoryCount.update(best.category, (n) => n + 1, ifAbsent: () => 1);
      if (best.category == PlaceCategory.food) {
        lastMeal = bestDeparture!.subtract(Duration(minutes: best.visitMinutes));
      }
      position = best.location;
      time = bestDeparture!;
    }

    return schedule(request, chosen, weather: weather, alerts: alerts);
  }

  /// Computes times, legs and warnings for places in the given order. Used
  /// after the user removes, adds or reorders stops.
  Itinerary schedule(
    ItineraryRequest request,
    List<Place> ordered, {
    WeatherReport? weather,
    List<ConditionAlert> alerts = const [],
  }) {
    final stops = <ItineraryStop>[];
    var position = request.start.location;
    var time = request.startTime;

    for (final place in ordered) {
      final options = estimator.optionsFor(position, place.location, time, alerts: alerts);
      final chosen = estimator.recommend(options, request.travelStyle);
      final leg = ItineraryLeg(from: position, to: place.location, options: options, chosen: chosen);
      final arrival = time.add(Duration(minutes: leg.minutes));
      final visitStart = _visitStart(place, arrival) ?? arrival;
      final departure = visitStart.add(Duration(minutes: place.visitMinutes));

      final status = place.openingHours.statusAt(visitStart);
      final warnings = <StopWarning>[
        if (!status.isOpen) StopWarning.closedOnArrival,
        if (status.isOpen && !place.openingHours.isOpenFor(visitStart, place.visitMinutes))
          StopWarning.closesDuringVisit,
        if (departure.isAfter(request.endTime)) StopWarning.pastEndTime,
      ];

      stops.add(ItineraryStop(
        place: place,
        leg: leg,
        arrival: arrival,
        visitStart: visitStart,
        departure: departure,
        scored: engine.score(place, _context(request, visitStart, weather, alerts)),
        warnings: warnings,
      ));
      position = place.location;
      time = departure;
    }
    return Itinerary(request: request, stops: List.unmodifiable(stops));
  }

  /// Reorders [places] to shorten total travel from [start]: nearest
  /// neighbour, then 2-opt improvement on the open path.
  List<Place> optimizeOrder(GeoPoint start, List<Place> places) {
    if (places.length < 3) {
      final remaining = [...places]
        ..sort((a, b) => start.distanceKmTo(a.location).compareTo(start.distanceKmTo(b.location)));
      return remaining;
    }

    final remaining = [...places];
    final route = <Place>[];
    var here = start;
    while (remaining.isNotEmpty) {
      remaining.sort((a, b) => here.distanceKmTo(a.location).compareTo(here.distanceKmTo(b.location)));
      final next = remaining.removeAt(0);
      route.add(next);
      here = next.location;
    }

    var improved = true;
    while (improved) {
      improved = false;
      for (var i = 0; i < route.length - 1; i++) {
        for (var k = i + 1; k < route.length; k++) {
          final candidate = [
            ...route.sublist(0, i),
            ...route.sublist(i, k + 1).reversed,
            ...route.sublist(k + 1),
          ];
          if (pathKm(start, candidate) + 1e-9 < pathKm(start, route)) {
            route
              ..clear()
              ..addAll(candidate);
            improved = true;
          }
        }
      }
    }
    return route;
  }

  static double pathKm(GeoPoint start, List<Place> places) {
    var km = 0.0;
    var here = start;
    for (final p in places) {
      km += here.distanceKmTo(p.location);
      here = p.location;
    }
    return km;
  }

  /// One meal stop per day (two for food lovers), spaced well apart.
  bool _mealFits(
    ItineraryRequest request,
    Map<PlaceCategory, int> categoryCount,
    DateTime? lastMeal,
    DateTime visitStart,
  ) {
    final maxMeals = request.interests.contains(PlaceCategory.food) ? 2 : 1;
    if ((categoryCount[PlaceCategory.food] ?? 0) >= maxMeals) return false;
    return lastMeal == null || visitStart.difference(lastMeal).inMinutes >= minMinutesBetweenMeals;
  }

  /// When the visit can begin: on arrival if open, at opening time if that is
  /// within [maxWaitMinutes], otherwise `null`.
  DateTime? _visitStart(Place place, DateTime arrival) {
    final status = place.openingHours.statusAt(arrival);
    if (status.isOpen) return arrival;
    if (status.state == OpenState.opensLater && status.minutesUntilOpen! <= maxWaitMinutes) {
      return arrival.add(Duration(minutes: status.minutesUntilOpen!));
    }
    return null;
  }

  RecommendationContext _context(
    ItineraryRequest request,
    DateTime at,
    WeatherReport? weather,
    List<ConditionAlert> alerts,
  ) =>
      RecommendationContext(
        time: at,
        weather: weather?.at(at),
        interests: request.interests,
        alerts: alerts,
      );
}
