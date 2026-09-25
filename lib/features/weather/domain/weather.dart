import '../../../core/time/kathmandu_time.dart';

enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  heavyRain,
  thunderstorm,
  snow;

  /// Maps a WMO weather interpretation code (used by Open-Meteo).
  static WeatherCondition fromWmo(int code) => switch (code) {
        0 || 1 => clear,
        2 => partlyCloudy,
        3 => cloudy,
        45 || 48 => fog,
        >= 51 && <= 57 => drizzle,
        61 || 63 || 66 || 80 || 81 => rain,
        65 || 67 || 82 => heavyRain,
        >= 71 && <= 77 || 85 || 86 => snow,
        >= 95 => thunderstorm,
        _ => cloudy,
      };

  bool get isWet => switch (this) {
        drizzle || rain || heavyRain || thunderstorm || snow => true,
        _ => false,
      };
}

/// US AQI bands.
enum AirQualityLevel {
  good, // 0-50
  moderate, // 51-100
  sensitive, // 101-150 unhealthy for sensitive groups
  unhealthy, // 151-200
  veryUnhealthy; // 201+

  static AirQualityLevel fromUsAqi(int aqi) => switch (aqi) {
        <= 50 => good,
        <= 100 => moderate,
        <= 150 => sensitive,
        <= 200 => unhealthy,
        _ => veryUnhealthy,
      };
}

/// Weather at one moment (current conditions or one forecast hour).
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.time,
    required this.temperatureC,
    required this.condition,
    this.precipitationMm = 0,
    this.precipitationProbability,
    this.usAqi,
    this.isDay = true,
  });

  /// Kathmandu wall time.
  final DateTime time;
  final double temperatureC;
  final WeatherCondition condition;
  final double precipitationMm;
  final int? precipitationProbability;
  final int? usAqi;
  final bool isDay;

  /// Raining now or very likely to within the hour.
  bool get isWet =>
      condition.isWet || precipitationMm >= 0.3 || (precipitationProbability ?? 0) >= 65;

  /// Mountain views are unlikely.
  bool get isLowVisibility =>
      isWet || condition == WeatherCondition.fog || condition == WeatherCondition.cloudy;

  bool get isClearSky =>
      !isWet && (condition == WeatherCondition.clear || condition == WeatherCondition.partlyCloudy);

  bool get isHot => temperatureC >= 30;

  AirQualityLevel? get airQuality => usAqi == null ? null : AirQualityLevel.fromUsAqi(usAqi!);

  WeatherSnapshot copyWith({int? usAqi}) => WeatherSnapshot(
        time: time,
        temperatureC: temperatureC,
        condition: condition,
        precipitationMm: precipitationMm,
        precipitationProbability: precipitationProbability,
        usAqi: usAqi ?? this.usAqi,
        isDay: isDay,
      );
}

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.condition,
    required this.maxC,
    required this.minC,
    this.precipitationMm = 0,
    this.precipitationProbability,
  });

  final DateTime date;
  final WeatherCondition condition;
  final double maxC;
  final double minC;
  final double precipitationMm;
  final int? precipitationProbability;
}

class WeatherReport {
  const WeatherReport({
    required this.current,
    required this.fetchedAt,
    this.hourly = const [],
    this.daily = const [],
    this.fromCache = false,
  });

  final WeatherSnapshot current;
  final List<WeatherSnapshot> hourly;
  final List<DailyForecast> daily;

  /// Kathmandu wall time of the network fetch.
  final DateTime fetchedAt;

  /// True when the network was unavailable and this is the last saved result.
  final bool fromCache;

  WeatherReport markCached() => WeatherReport(
        current: current,
        fetchedAt: fetchedAt,
        hourly: hourly,
        daily: daily,
        fromCache: true,
      );

  /// Best available estimate of conditions at [t]: the matching forecast hour,
  /// else the daily forecast, else current conditions if [t] is close to now.
  WeatherSnapshot? at(DateTime t) {
    WeatherSnapshot? best;
    var bestDiff = const Duration(minutes: 61);
    for (final h in hourly) {
      final diff = h.time.difference(t).abs();
      if (diff < bestDiff) {
        best = h;
        bestDiff = diff;
      }
    }
    if (best != null) return best;

    final day = dateOnly(t);
    for (final d in daily) {
      if (dateOnly(d.date) == day) {
        return WeatherSnapshot(
          time: t,
          temperatureC: (d.maxC + d.minC) / 2,
          condition: d.condition,
          precipitationMm: 0,
          precipitationProbability: d.precipitationProbability,
          usAqi: current.usAqi,
        );
      }
    }
    if (current.time.difference(t).abs() <= const Duration(hours: 2)) return current;
    return null;
  }

  DailyForecast? dayOf(DateTime t) {
    final day = dateOnly(t);
    for (final d in daily) {
      if (dateOnly(d.date) == day) return d;
    }
    return null;
  }
}
