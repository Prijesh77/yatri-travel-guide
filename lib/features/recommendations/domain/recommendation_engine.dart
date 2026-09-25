import '../../../core/geo/geo_point.dart';
import '../../../core/time/kathmandu_time.dart';
import '../../alerts/domain/condition_alert.dart';
import '../../places/domain/opening_hours.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_category.dart';
import '../../weather/domain/weather.dart';
import 'recommendation_context.dart';
import 'scored_place.dart';

/// Tunable weights for [RecommendationEngine]. Kept in one place so the
/// ranking can be adjusted (or A/B tested) without touching the rules.
class ScoringWeights {
  const ScoringWeights({
    this.popularity = 5,
    this.indoorInRain = 18,
    this.coveredInRain = 5,
    this.outdoorInRain = -18,
    this.viewsHidden = -12,
    this.clearViews = 8,
    this.pleasantOutdoors = 6,
    this.poorAirOutdoor = -12,
    this.moderateAirOutdoor = -4,
    this.indoorPoorAir = 6,
    this.hotMidday = -6,
    this.bestTime = 10,
    this.mealTime = 8,
    this.afterDarkNature = -20,
    this.afterDarkOther = -8,
    this.blocked = -100,
    this.opensWithinHour = -6,
    this.opensMuchLater = -25,
    this.closesVerySoon = -30,
    this.closesBeforeVisitEnds = -10,
    this.distanceMax = 10,
    this.distanceMin = -14,
    this.distancePerKm = 0.9,
    this.primaryInterest = 12,
    this.secondaryInterest = 6,
    this.festival = 4,
    this.roadClosure = -10,
    this.bandhWalkable = 8,
    this.bandhMaxPenalty = -25,
  });

  final double popularity;
  final double indoorInRain;
  final double coveredInRain;
  final double outdoorInRain;
  final double viewsHidden;
  final double clearViews;
  final double pleasantOutdoors;
  final double poorAirOutdoor;
  final double moderateAirOutdoor;
  final double indoorPoorAir;
  final double hotMidday;
  final double bestTime;
  final double mealTime;
  final double afterDarkNature;
  final double afterDarkOther;
  final double blocked;
  final double opensWithinHour;
  final double opensMuchLater;
  final double closesVerySoon;
  final double closesBeforeVisitEnds;
  final double distanceMax;
  final double distanceMin;
  final double distancePerKm;
  final double primaryInterest;
  final double secondaryInterest;
  final double festival;
  final double roadClosure;
  final double bandhWalkable;
  final double bandhMaxPenalty;
}

/// Scores places for the current conditions. Pure: the same inputs always
/// give the same ranking, which keeps it easy to test.
class RecommendationEngine {
  const RecommendationEngine({this.weights = const ScoringWeights()});

  final ScoringWeights weights;

  /// Walking distance during a bandh.
  static const bandhWalkKm = 2.5;

  List<ScoredPlace> rank(Iterable<Place> places, RecommendationContext context) {
    final scored = [for (final p in places) score(p, context)];
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byPopularity = b.place.popularity.compareTo(a.place.popularity);
      if (byPopularity != 0) return byPopularity;
      return a.place.name.compareTo(b.place.name);
    });
    return scored;
  }

  /// Re-orders a ranking so the list is not dominated by one category: each
  /// place loses [penalty] points per higher-ranked place of the same
  /// category. Unavailable places stay at the bottom.
  List<ScoredPlace> diversify(List<ScoredPlace> ranked, {double penalty = 5}) {
    final remaining = [...ranked];
    final result = <ScoredPlace>[];
    final seen = <PlaceCategory, int>{};
    double adjusted(ScoredPlace s) =>
        s.isAvailable ? s.score - penalty * (seen[s.place.category] ?? 0) : s.score;
    while (remaining.isNotEmpty) {
      var bestIndex = 0;
      for (var i = 1; i < remaining.length; i++) {
        if (adjusted(remaining[i]) > adjusted(remaining[bestIndex])) bestIndex = i;
      }
      final next = remaining.removeAt(bestIndex);
      seen.update(next.place.category, (n) => n + 1, ifAbsent: () => 1);
      result.add(next);
    }
    return result;
  }

  ScoredPlace score(Place place, RecommendationContext ctx) {
    final w = weights;
    final reasons = <ScoreReason>[];
    final dayPart = DayPart.of(ctx.time);
    var total = place.popularity * w.popularity;
    if (place.popularity >= 5) {
      // Already counted in the popularity base score; listed so the UI can
      // mention it. The small impact only orders it among the reasons.
      reasons.add(const ScoreReason(ReasonKind.highlight, 3));
    }

    void add(ScoreReason r) {
      reasons.add(r);
      total += r.impact;
    }

    // --- Opening hours -----------------------------------------------------
    final status = place.openingHours.statusAt(ctx.time);
    _scoreOpening(place, status, add);

    // --- Weather -----------------------------------------------------------
    if (ctx.weather case final weather?) {
      _scoreWeather(place, weather, dayPart, add);
    }

    // --- Time of day -------------------------------------------------------
    // Food uses meal times instead, so lunch is not counted twice.
    if (place.category != PlaceCategory.food && place.bestTimes.contains(dayPart.name)) {
      add(ScoreReason(ReasonKind.bestTimeNow, w.bestTime, dayPart: dayPart));
    }
    if (place.category == PlaceCategory.food && _isMealTime(ctx.time)) {
      add(ScoreReason(ReasonKind.mealTime, w.mealTime));
    }
    final livelyAtNight = place.category == PlaceCategory.food || place.category == PlaceCategory.shopping;
    if (dayPart == DayPart.night && place.setting != Setting.indoor && !livelyAtNight) {
      final natureLike = place.category == PlaceCategory.nature || place.category == PlaceCategory.viewpoint;
      add(ScoreReason(ReasonKind.afterDark, natureLike ? w.afterDarkNature : w.afterDarkOther));
    }

    // --- Distance ----------------------------------------------------------
    double? distance;
    if (ctx.userLocation case final here?) {
      distance = here.distanceKmTo(place.location);
      final impact = (w.distanceMax - w.distancePerKm * distance).clamp(w.distanceMin, w.distanceMax);
      if (distance <= 3) {
        add(ScoreReason(ReasonKind.nearby, impact, distanceKm: distance));
      } else if (distance > 15) {
        add(ScoreReason(ReasonKind.far, impact, distanceKm: distance));
      } else {
        total += impact; // Silent: mid-range distance is not worth a reason.
      }
    }

    // --- Interests ---------------------------------------------------------
    if (ctx.interests.contains(place.category)) {
      add(ScoreReason(ReasonKind.matchesInterest, w.primaryInterest, category: place.category));
    } else {
      for (final c in place.secondaryCategories) {
        if (ctx.interests.contains(c)) {
          add(ScoreReason(ReasonKind.matchesInterest, w.secondaryInterest, category: c));
          break;
        }
      }
    }

    // --- Alerts ------------------------------------------------------------
    for (final alert in ctx.alerts) {
      if (!alert.isActiveAt(ctx.time) || !alert.affects(place)) continue;
      _scoreAlert(place, alert, ctx.userLocation, add);
    }

    reasons.sort((a, b) => b.impact.abs().compareTo(a.impact.abs()));
    return ScoredPlace(
      place: place,
      score: total,
      reasons: List.unmodifiable(reasons),
      openStatus: status,
      distanceKm: distance,
    );
  }

  void _scoreOpening(Place place, OpenStatus status, void Function(ScoreReason) add) {
    final w = weights;
    switch (status.state) {
      case OpenState.closedToday:
        add(ScoreReason(ReasonKind.closedToday, w.blocked));
      case OpenState.closedForDay:
        add(ScoreReason(ReasonKind.closedNow, w.blocked, minutes: status.opensAt));
      case OpenState.opensLater:
        final soon = status.minutesUntilOpen! <= 60;
        add(ScoreReason(ReasonKind.opensLater, soon ? w.opensWithinHour : w.opensMuchLater,
            minutes: status.opensAt));
      case OpenState.open:
        final left = status.minutesUntilClose;
        if (left != null && left < place.visitMinutes) {
          add(ScoreReason(ReasonKind.closesSoon, left < 30 ? w.closesVerySoon : w.closesBeforeVisitEnds,
              minutes: left));
        }
    }
  }

  void _scoreWeather(Place place, WeatherSnapshot weather, DayPart dayPart, void Function(ScoreReason) add) {
    final w = weights;
    final isViewpoint = place.hasCategory(PlaceCategory.viewpoint);

    if (weather.isWet) {
      switch (place.setting) {
        case Setting.indoor:
          add(ScoreReason(ReasonKind.indoorInRain, w.indoorInRain, dayPart: dayPart));
        case Setting.mixed:
          add(ScoreReason(ReasonKind.coveredInRain, w.coveredInRain, dayPart: dayPart));
        case Setting.outdoor:
          add(ScoreReason(ReasonKind.outdoorInRain, w.outdoorInRain));
      }
    } else if (weather.isClearSky && place.setting != Setting.indoor && weather.isDay) {
      if (isViewpoint) {
        add(ScoreReason(ReasonKind.clearViews, w.clearViews));
      } else if (place.setting == Setting.outdoor) {
        add(ScoreReason(ReasonKind.pleasantOutdoors, w.pleasantOutdoors));
      }
    }

    if (isViewpoint && weather.isLowVisibility) {
      add(ScoreReason(ReasonKind.noViews, w.viewsHidden));
    }

    final air = weather.airQuality;
    if (air != null) {
      final poor = air.index >= AirQualityLevel.unhealthy.index;
      final moderate = air == AirQualityLevel.sensitive;
      if (place.setting == Setting.outdoor && (poor || moderate)) {
        add(ScoreReason(ReasonKind.poorAirOutdoor, poor ? w.poorAirOutdoor : w.moderateAirOutdoor,
            aqi: weather.usAqi));
      } else if (place.setting == Setting.indoor && poor) {
        add(ScoreReason(ReasonKind.indoorPoorAir, w.indoorPoorAir, aqi: weather.usAqi));
      }
    }

    if (weather.isHot && dayPart == DayPart.afternoon && place.setting == Setting.outdoor) {
      add(ScoreReason(ReasonKind.hotMidday, w.hotMidday));
    }
  }

  void _scoreAlert(Place place, ConditionAlert alert, GeoPoint? here, void Function(ScoreReason) add) {
    final w = weights;
    switch (alert.type) {
      case AlertType.closure:
        if (alert.placeIds.contains(place.id) || alert.isNear(place.location)) {
          add(ScoreReason(ReasonKind.closureAlert, w.blocked, alertTitle: alert.title));
        }
      case AlertType.festival:
        add(ScoreReason(ReasonKind.festival, w.festival, alertTitle: alert.title));
      case AlertType.roadClosure:
        add(ScoreReason(ReasonKind.roadClosure, w.roadClosure, alertTitle: alert.title));
      case AlertType.traffic:
        add(ScoreReason(ReasonKind.roadClosure, w.roadClosure / 2, alertTitle: alert.title));
      case AlertType.bandh:
        final d = here?.distanceKmTo(place.location);
        if (d != null && d <= bandhWalkKm) {
          add(ScoreReason(ReasonKind.bandhWalkable, w.bandhWalkable, alertTitle: alert.title, distanceKm: d));
        } else {
          final penalty = d == null ? w.bandhMaxPenalty / 2 : (-(5 + 2 * d)).clamp(w.bandhMaxPenalty, -5.0);
          add(ScoreReason(ReasonKind.bandhTransport, penalty.toDouble(), alertTitle: alert.title, distanceKm: d));
        }
    }
  }

  static bool _isMealTime(DateTime t) {
    final m = minuteOfDay(t);
    return (m >= 7 * 60 && m < 9 * 60 + 30) ||
        (m >= 12 * 60 && m < 14 * 60 + 30) ||
        (m >= 18 * 60 && m < 21 * 60);
  }
}
