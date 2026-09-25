import '../../../core/geo/geo_point.dart';
import '../../alerts/domain/condition_alert.dart';
import '../../places/domain/place_category.dart';
import '../../weather/domain/weather.dart';

/// Everything the scoring needs to know about "right now" (or about the
/// moment a planned visit starts).
class RecommendationContext {
  const RecommendationContext({
    required this.time,
    this.weather,
    this.userLocation,
    this.interests = const {},
    this.alerts = const [],
  });

  /// Kathmandu wall time of the (planned) visit.
  final DateTime time;

  /// Conditions at [time]; `null` when unknown (scoring then ignores weather).
  final WeatherSnapshot? weather;

  /// Used for distance scoring; `null` when unknown or outside the valley.
  final GeoPoint? userLocation;
  final Set<PlaceCategory> interests;
  final List<ConditionAlert> alerts;

  RecommendationContext copyWith({
    DateTime? time,
    WeatherSnapshot? weather,
    GeoPoint? userLocation,
    bool clearUserLocation = false,
  }) =>
      RecommendationContext(
        time: time ?? this.time,
        weather: weather ?? this.weather,
        userLocation: clearUserLocation ? null : (userLocation ?? this.userLocation),
        interests: interests,
        alerts: alerts,
      );
}
