import '../../../core/geo/geo_point.dart';
import '../../alerts/domain/condition_alert.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_category.dart';
import '../../recommendations/domain/scored_place.dart';
import '../../transport/domain/transport_option.dart';

class StartPoint {
  const StartPoint(this.label, this.location);
  final String label;
  final GeoPoint location;

  factory StartPoint.fromJson(Map<String, dynamic> json) =>
      StartPoint(json['label'] as String, GeoPoint.fromJson(json));

  Map<String, dynamic> toJson() => {'label': label, ...location.toJson()};
}

class ItineraryRequest {
  const ItineraryRequest({
    required this.startTime,
    required this.availableMinutes,
    required this.start,
    this.interests = const {},
    this.travelStyle = TravelStyle.balanced,
    this.maxStops = 6,
  });

  /// Kathmandu wall time the day starts (date + time).
  final DateTime startTime;
  final int availableMinutes;
  final StartPoint start;
  final Set<PlaceCategory> interests;
  final TravelStyle travelStyle;
  final int maxStops;

  DateTime get endTime => startTime.add(Duration(minutes: availableMinutes));

  factory ItineraryRequest.fromJson(Map<String, dynamic> json) => ItineraryRequest(
        startTime: DateTime.parse(json['startTime'] as String),
        availableMinutes: (json['availableMinutes'] as num).toInt(),
        start: StartPoint.fromJson(json['start'] as Map<String, dynamic>),
        interests: {for (final c in json['interests'] as List) PlaceCategory.parse(c as String)},
        travelStyle: TravelStyle.values.byName(json['travelStyle'] as String),
        maxStops: (json['maxStops'] as num?)?.toInt() ?? 6,
      );

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'availableMinutes': availableMinutes,
        'start': start.toJson(),
        'interests': [for (final c in interests) c.name],
        'travelStyle': travelStyle.name,
        'maxStops': maxStops,
      };
}

class ItineraryLeg {
  const ItineraryLeg({required this.from, required this.to, required this.options, this.chosen, this.avoiding});

  final GeoPoint from;
  final GeoPoint to;
  final List<TransportOption> options;

  /// Option used for timing (depends on the travel style).
  final TransportOption? chosen;

  /// A reported disruption on the way; the leg is timed to go around it.
  final ConditionAlert? avoiding;

  bool get isRerouted => avoiding != null;

  int get minutes => chosen?.durationMinutes ?? 0;
}

enum StopWarning {
  /// Planned arrival is on a closing day or after closing time.
  closedOnArrival,

  /// The place closes before the typical visit would end.
  closesDuringVisit,

  /// This stop runs past the end of the time available.
  pastEndTime,
}

class ItineraryStop {
  const ItineraryStop({
    required this.place,
    required this.leg,
    required this.arrival,
    required this.visitStart,
    required this.departure,
    required this.scored,
    this.warnings = const [],
    this.nearbyEvents = const [],
    this.note,
  });

  final Place place;

  /// Travel from the previous stop (or from the start point).
  final ItineraryLeg leg;
  final DateTime arrival;

  /// Later than [arrival] when waiting for the place to open.
  final DateTime visitStart;
  final DateTime departure;

  /// Suitability at the planned visit time.
  final ScoredPlace scored;
  final List<StopWarning> warnings;

  /// Events (jatras, processions) near this stop during the visit.
  final List<ConditionAlert> nearbyEvents;

  /// Short tip from the AI planner, if the plan came from it.
  final String? note;

  int get waitMinutes => visitStart.difference(arrival).inMinutes;
}

enum PlanSource {
  /// Built by the on-device condition-aware planner.
  local,

  /// Places and order chosen by the AI model, then checked and timed on
  /// device.
  ai,

  /// The AI planner was asked but failed (offline, quota, bad answer), so
  /// the on-device planner was used instead.
  localFallback,
}

class Itinerary {
  const Itinerary({
    required this.request,
    required this.stops,
    this.source = PlanSource.local,
    this.summary,
  });

  final ItineraryRequest request;
  final List<ItineraryStop> stops;
  final PlanSource source;

  /// One or two sentences from the AI planner about the day.
  final String? summary;

  bool get isEmpty => stops.isEmpty;

  DateTime get endTime => stops.isEmpty ? request.startTime : stops.last.departure;

  int get totalTravelMinutes => stops.fold(0, (sum, s) => sum + s.leg.minutes);

  FareRange get transportCost =>
      stops.fold(const FareRange.free(), (sum, s) => sum + (s.leg.chosen?.fare ?? const FareRange.free()));

  int entryFees(VisitorType visitor) => stops.fold(0, (sum, s) => sum + s.place.entryFee.forVisitor(visitor));

  bool get hasWarnings => stops.any((s) => s.warnings.isNotEmpty);

  List<Place> get places => [for (final s in stops) s.place];
}
