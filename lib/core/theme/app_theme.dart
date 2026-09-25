import 'package:flutter/material.dart';

import '../../features/places/domain/place_category.dart';
import '../../features/recommendations/domain/scored_place.dart';
import '../../features/transport/domain/transport_option.dart';
import '../../features/weather/domain/weather.dart';

class AppTheme {
  /// Wireframe navy blue.
  static const seed = Color(0xFF1D4E89);

  // Accent pairs from the wireframes (icon colour, pale background).
  static const aiColor = Color(0xFF4B3FB0);
  static const aiBackground = Color(0xFFEDEBFC);
  static const alertColor = Color(0xFF8A4B08);
  static const alertBackground = Color(0xFFFCEBD6);
  static const eventColor = Color(0xFF2E6B1F);
  static const eventBackground = Color(0xFFE3F1DC);
  static const transitBackground = Color(0xFFE3EEFA);
  static const plannedBackground = Color(0xFFF0EEE8);
  static const plannedColor = Color(0xFF8A877F);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: const ChipThemeData(showCheckmark: false),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
    );
  }
}

extension CategoryStyle on PlaceCategory {
  IconData get icon => switch (this) {
        PlaceCategory.heritage => Icons.account_balance,
        PlaceCategory.temple => Icons.temple_buddhist,
        PlaceCategory.nature => Icons.park,
        PlaceCategory.food => Icons.restaurant,
        PlaceCategory.shopping => Icons.shopping_bag,
        PlaceCategory.viewpoint => Icons.landscape,
      };

  Color get color => switch (this) {
        PlaceCategory.heritage => const Color(0xFF8D5B3E),
        PlaceCategory.temple => const Color(0xFFD35400),
        PlaceCategory.nature => const Color(0xFF2E7D32),
        PlaceCategory.food => const Color(0xFFC2185B),
        PlaceCategory.shopping => const Color(0xFF6A1B9A),
        PlaceCategory.viewpoint => const Color(0xFF1565C0),
      };
}

extension WeatherStyle on WeatherCondition {
  IconData icon({bool isDay = true}) => switch (this) {
        WeatherCondition.clear => isDay ? Icons.wb_sunny : Icons.nightlight_round,
        WeatherCondition.partlyCloudy => isDay ? Icons.wb_cloudy : Icons.nights_stay,
        WeatherCondition.cloudy => Icons.cloud,
        WeatherCondition.fog => Icons.foggy,
        WeatherCondition.drizzle => Icons.grain,
        WeatherCondition.rain => Icons.umbrella,
        WeatherCondition.heavyRain => Icons.water_drop,
        WeatherCondition.thunderstorm => Icons.thunderstorm,
        WeatherCondition.snow => Icons.ac_unit,
      };
}

extension AirQualityStyle on AirQualityLevel {
  Color get color => switch (this) {
        AirQualityLevel.good => const Color(0xFF2E7D32),
        AirQualityLevel.moderate => const Color(0xFF9E7700),
        AirQualityLevel.sensitive => const Color(0xFFE65100),
        AirQualityLevel.unhealthy => const Color(0xFFC62828),
        AirQualityLevel.veryUnhealthy => const Color(0xFF6A1B9A),
      };
}

extension SuitabilityStyle on Suitability {
  Color color(ColorScheme scheme) => switch (this) {
        Suitability.excellent => const Color(0xFF2E7D32),
        Suitability.good => const Color(0xFF558B2F),
        Suitability.fair => const Color(0xFF9E7700),
        Suitability.notIdeal => const Color(0xFFE65100),
        Suitability.unavailable => scheme.outline,
      };

  IconData get icon => switch (this) {
        Suitability.excellent => Icons.star,
        Suitability.good => Icons.thumb_up_alt_outlined,
        Suitability.fair => Icons.remove_circle_outline,
        Suitability.notIdeal => Icons.warning_amber,
        Suitability.unavailable => Icons.block,
      };
}

extension TransportStyle on TransportMode {
  IconData get icon => switch (this) {
        TransportMode.walk => Icons.directions_walk,
        TransportMode.bikeTaxi => Icons.two_wheeler,
        TransportMode.taxi => Icons.local_taxi,
        TransportMode.bus => Icons.directions_bus,
      };
}
