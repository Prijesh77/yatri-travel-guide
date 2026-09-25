import 'journey_planner.dart';

enum TransportMode { walk, bikeTaxi, taxi, bus }

/// How the traveller trades cost against comfort when we pick a default
/// option for itinerary timing.
enum TravelStyle { budget, balanced, comfort }

class FareRange {
  const FareRange(this.min, this.max);
  const FareRange.free()
      : min = 0,
        max = 0;
  const FareRange.exact(int value)
      : min = value,
        max = value;

  /// NPR.
  final int min;
  final int max;

  bool get isFree => max == 0;
  bool get isExact => min == max;

  FareRange operator +(FareRange other) => FareRange(min + other.min, max + other.max);

  @override
  bool operator ==(Object other) => other is FareRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'NPR $min-$max';
}

enum TransportNote {
  /// Night surcharge applied.
  nightFare,

  /// Rush-hour traffic slows road travel.
  rushHour,

  /// Outside bus service hours.
  noBusService,

  /// No sample route found; generic estimate, ask locally for the right bus.
  estimatedRoute,

  /// A bandh (strike) is active: vehicles may not run.
  bandh,

  /// Uses a route whose data is not verified for 2026.
  unverifiedRoute,

  /// Slowed down to avoid a reported road closure or disruption.
  rerouted,
}

class TransportOption {
  const TransportOption({
    required this.mode,
    required this.durationMinutes,
    required this.fare,
    required this.distanceKm,
    this.available = true,
    this.notes = const [],
    this.routeName,
    this.vehicle,
    this.boardAt,
    this.alightAt,
    this.walkMinutes = 0,
    this.journey,
  });

  final TransportMode mode;

  /// Door to door, including waiting and walking to stops.
  final int durationMinutes;

  /// Per person for walk/bus; per vehicle for taxi and bike taxi.
  final FareRange fare;

  /// Approximate road distance.
  final double distanceKm;
  final bool available;
  final List<TransportNote> notes;

  // Bus only.
  final String? routeName;
  final String? vehicle;
  final String? boardAt;
  final String? alightAt;
  final int walkMinutes;

  /// Full bus journey (walks, rides, transfer) when found in the network.
  final Journey? journey;

  int get transfers => journey?.transfers ?? 0;

  bool get isEstimate => notes.contains(TransportNote.estimatedRoute);

  TransportOption copyWith({int? durationMinutes, List<TransportNote>? notes}) => TransportOption(
        mode: mode,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        fare: fare,
        distanceKm: distanceKm,
        available: available,
        notes: notes ?? this.notes,
        routeName: routeName,
        vehicle: vehicle,
        boardAt: boardAt,
        alightAt: alightAt,
        walkMinutes: walkMinutes,
        journey: journey,
      );
}
