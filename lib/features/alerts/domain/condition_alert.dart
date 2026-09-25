import '../../../core/geo/geo_point.dart';
import '../../../core/time/kathmandu_time.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_category.dart';

enum AlertType {
  /// Festival, jatra or other event: expect crowds, worth a detour.
  festival,

  /// A specific place is closed (renovation, private event, ...).
  closure,

  /// A closed road slowing access to an area.
  roadClosure,

  /// Heavy traffic / jam.
  traffic,

  /// General strike: vehicles largely off the road.
  bandh;

  static AlertType parse(String value) => values.firstWhere(
        (t) => t.name == value,
        orElse: () => throw FormatException('Unknown alert type "$value"'),
      );

  /// Everything except events is a disruption.
  bool get isDisruption => this != festival;

  /// Disruptions that slow or block road travel near their location.
  bool get affectsRoads => this == roadClosure || this == traffic || this == bandh;
}

enum AlertSource {
  /// From the curated alerts feed (`alerts.json` today, an API later).
  official,

  /// Reported by a user on this device.
  community,

  /// Demo data loaded from the empty state; clearly labelled in the UI.
  sample;

  static AlertSource parse(String? value) => values.asNameMap()[value] ?? official;
}

/// A time-bound condition that affects recommendations and transport.
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
    this.location,
    this.radiusKm = 0.5,
    this.locationLabel = '',
    this.source = AlertSource.official,
    this.reportedAt,
    this.confirmations = 0,
  });

  final String id;
  final AlertType type;
  final String title;
  final String description;

  /// Kathmandu wall times, inclusive start / exclusive end.
  final DateTime start;
  final DateTime end;

  /// Scope. With no cities, place ids or location the alert is valley-wide.
  final Set<City> cities;
  final Set<String> placeIds;
  final GeoPoint? location;
  final double radiusKm;
  final String locationLabel;

  final AlertSource source;
  final DateTime? reportedAt;

  /// "Still there" confirmations from other users.
  final int confirmations;

  bool get isValleyWide => cities.isEmpty && placeIds.isEmpty && location == null;

  bool get isEvent => type == AlertType.festival;

  bool isActiveAt(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  bool isExpiredAt(DateTime t) => !t.isBefore(end);

  /// Active now or later on the same day as [t].
  bool isRelevantOn(DateTime t) {
    final endOfDay = dateOnly(t).add(const Duration(days: 1));
    return end.isAfter(t) && start.isBefore(endOfDay);
  }

  bool isNear(GeoPoint point, {double extraKm = 0}) =>
      location != null && location!.distanceKmTo(point) <= radiusKm + extraKm;

  bool affects(Place place) =>
      isValleyWide ||
      placeIds.contains(place.id) ||
      cities.contains(place.city) ||
      isNear(place.location);

  /// True when a trip between [a] and [b] passes this alert's area.
  bool liesOnPath(GeoPoint a, GeoPoint b, {double bufferKm = 0.3}) =>
      location != null && location!.distanceKmToSegment(a, b) <= radiusKm + bufferKm;

  ConditionAlert copyWith({int? confirmations}) => ConditionAlert(
        id: id,
        type: type,
        title: title,
        start: start,
        end: end,
        description: description,
        cities: cities,
        placeIds: placeIds,
        location: location,
        radiusKm: radiusKm,
        locationLabel: locationLabel,
        source: source,
        reportedAt: reportedAt,
        confirmations: confirmations ?? this.confirmations,
      );

  factory ConditionAlert.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    return ConditionAlert(
      id: json['id'] as String,
      type: AlertType.parse(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      start: parseKtmLocal(json['start'] as String),
      end: parseKtmLocal(json['end'] as String),
      cities: {for (final c in (json['cities'] as List? ?? const [])) City.parse(c as String)},
      placeIds: {for (final p in (json['placeIds'] as List? ?? const [])) p as String},
      location: loc == null ? null : GeoPoint.fromJson(loc),
      radiusKm: (loc?['radiusKm'] as num?)?.toDouble() ?? 0.5,
      locationLabel: loc?['label'] as String? ?? '',
      source: AlertSource.parse(json['source'] as String?),
      reportedAt: json['reportedAt'] == null ? null : parseKtmLocal(json['reportedAt'] as String),
      confirmations: (json['confirmations'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        if (description.isNotEmpty) 'description': description,
        'start': _local(start),
        'end': _local(end),
        if (cities.isNotEmpty) 'cities': [for (final c in cities) c.name],
        if (placeIds.isNotEmpty) 'placeIds': placeIds.toList(),
        if (location != null)
          'location': {...location!.toJson(), 'radiusKm': radiusKm, if (locationLabel.isNotEmpty) 'label': locationLabel},
        'source': source.name,
        if (reportedAt != null) 'reportedAt': _local(reportedAt!),
        'confirmations': confirmations,
      };

  /// Kathmandu wall time without a zone suffix, as used in the JSON files.
  static String _local(DateTime t) => t.toIso8601String().replaceAll('Z', '').split('.').first;
}
