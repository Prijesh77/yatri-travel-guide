import '../../../core/time/kathmandu_time.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_category.dart';

enum AlertType {
  /// Festival or large event: expect crowds and slow traffic.
  festival,

  /// A specific place is closed (renovation, private event, ...).
  closure,

  /// Road works or a closed road slowing access to an area.
  roadClosure,

  /// General strike: vehicles largely off the road.
  bandh;

  static AlertType parse(String value) => values.firstWhere(
        (t) => t.name == value,
        orElse: () => throw FormatException('Unknown alert type "$value"'),
      );
}

/// A time-bound condition that affects recommendations and transport.
///
/// v1 reads these from `assets/data/alerts.json`; a live feed can later
/// provide the same shape through `AlertsRepository`.
class ConditionAlert {
  const ConditionAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.start,
    required this.end,
    this.description = '',
    this.cities = const {},
    this.placeIds = const {},
  });

  final String id;
  final AlertType type;
  final String title;
  final String description;

  /// Kathmandu wall times, inclusive start / exclusive end.
  final DateTime start;
  final DateTime end;

  /// Empty [cities] and [placeIds] means the whole valley.
  final Set<City> cities;
  final Set<String> placeIds;

  bool get isValleyWide => cities.isEmpty && placeIds.isEmpty;

  bool isActiveAt(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  bool affects(Place place) =>
      isValleyWide || placeIds.contains(place.id) || cities.contains(place.city);

  factory ConditionAlert.fromJson(Map<String, dynamic> json) => ConditionAlert(
        id: json['id'] as String,
        type: AlertType.parse(json['type'] as String),
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        start: parseKtmLocal(json['start'] as String),
        end: parseKtmLocal(json['end'] as String),
        cities: {for (final c in (json['cities'] as List? ?? const [])) City.parse(c as String)},
        placeIds: {for (final p in (json['placeIds'] as List? ?? const [])) p as String},
      );
}
