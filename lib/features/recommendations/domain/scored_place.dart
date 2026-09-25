import '../../../core/time/kathmandu_time.dart';
import '../../places/domain/opening_hours.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_category.dart';

/// Why a place moved up or down. The domain only returns codes and values;
/// the presentation layer turns them into (translatable) text.
enum ReasonKind {
  indoorInRain,
  coveredInRain,
  outdoorInRain,
  noViews,
  clearViews,
  pleasantOutdoors,
  poorAirOutdoor,
  indoorPoorAir,
  hotMidday,
  bestTimeNow,
  mealTime,
  afterDark,
  closedToday,
  closedNow,
  opensLater,
  closesSoon,
  nearby,
  far,
  matchesInterest,
  highlight,
  festival,
  closureAlert,
  roadClosure,
  bandhWalkable,
  bandhTransport;

  /// Reasons that make a visit impossible at that time.
  bool get isBlocking => this == closedToday || this == closedNow || this == closureAlert;
}

class ScoreReason {
  const ScoreReason(
    this.kind,
    this.impact, {
    this.dayPart,
    this.distanceKm,
    this.minutes,
    this.category,
    this.alertTitle,
    this.aqi,
  });

  final ReasonKind kind;

  /// Contribution to the score (positive = better).
  final double impact;
  final DayPart? dayPart;
  final double? distanceKm;

  /// Minutes (closes in / opens at minute-of-day, depending on [kind]).
  final int? minutes;
  final PlaceCategory? category;
  final String? alertTitle;
  final int? aqi;

  bool get isPositive => impact > 0;

  @override
  String toString() => '${kind.name}(${impact.toStringAsFixed(1)})';
}

enum Suitability { excellent, good, fair, notIdeal, unavailable }

class ScoredPlace {
  const ScoredPlace({
    required this.place,
    required this.score,
    required this.reasons,
    required this.openStatus,
    this.distanceKm,
  });

  final Place place;
  final double score;

  /// Sorted by absolute impact, largest first.
  final List<ScoreReason> reasons;
  final OpenStatus openStatus;
  final double? distanceKm;

  bool get isAvailable => !reasons.any((r) => r.kind.isBlocking);

  /// The one or two strongest positive reasons, for card subtitles.
  List<ScoreReason> get highlights =>
      reasons.where((r) => r.isPositive).take(2).toList(growable: false);

  /// The strongest negative reason worth warning about, if any.
  ScoreReason? get warning {
    for (final r in reasons) {
      if (r.impact <= -8) return r;
    }
    return null;
  }

  Suitability get suitability {
    if (!isAvailable) return Suitability.unavailable;
    if (score >= 40) return Suitability.excellent;
    if (score >= 25) return Suitability.good;
    if (score >= 10) return Suitability.fair;
    return Suitability.notIdeal;
  }
}
