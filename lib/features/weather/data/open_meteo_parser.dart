import '../../../core/time/kathmandu_time.dart';
import '../domain/weather.dart';

/// Converts Open-Meteo forecast and air-quality responses into a
/// [WeatherReport]. Pure and synchronous so it can be unit-tested with
/// recorded responses.
class OpenMeteoParser {
  static WeatherReport parse({
    required Map<String, dynamic> forecast,
    Map<String, dynamic>? airQuality,
    required DateTime fetchedAt,
  }) {
    final aqiByHour = <DateTime, int>{};
    int? currentAqi;
    if (airQuality != null) {
      final hourly = airQuality['hourly'] as Map<String, dynamic>?;
      if (hourly != null) {
        final times = hourly['time'] as List;
        final values = hourly['us_aqi'] as List;
        for (var i = 0; i < times.length; i++) {
          final v = values[i];
          if (v is num) aqiByHour[parseKtmLocal(times[i] as String)] = v.round();
        }
      }
      final current = airQuality['current'] as Map<String, dynamic>?;
      currentAqi = (current?['us_aqi'] as num?)?.round();
    }

    final c = forecast['current'] as Map<String, dynamic>;
    final currentTime = parseKtmLocal(c['time'] as String);
    final current = WeatherSnapshot(
      time: currentTime,
      temperatureC: (c['temperature_2m'] as num).toDouble(),
      condition: WeatherCondition.fromWmo((c['weather_code'] as num).toInt()),
      precipitationMm: (c['precipitation'] as num?)?.toDouble() ?? 0,
      isDay: (c['is_day'] as num?) != 0,
      usAqi: currentAqi ?? aqiByHour[_hourOf(currentTime)],
    );

    final hourly = <WeatherSnapshot>[];
    final h = forecast['hourly'] as Map<String, dynamic>?;
    if (h != null) {
      final times = h['time'] as List;
      for (var i = 0; i < times.length; i++) {
        final t = parseKtmLocal(times[i] as String);
        final temp = _numAt(h['temperature_2m'], i);
        final code = _numAt(h['weather_code'], i);
        if (temp == null || code == null) continue;
        hourly.add(WeatherSnapshot(
          time: t,
          temperatureC: temp.toDouble(),
          condition: WeatherCondition.fromWmo(code.toInt()),
          precipitationMm: _numAt(h['precipitation'], i)?.toDouble() ?? 0,
          precipitationProbability: _numAt(h['precipitation_probability'], i)?.round(),
          isDay: (_numAt(h['is_day'], i) ?? 1) != 0,
          usAqi: aqiByHour[t],
        ));
      }
    }

    final daily = <DailyForecast>[];
    final d = forecast['daily'] as Map<String, dynamic>?;
    if (d != null) {
      final times = d['time'] as List;
      for (var i = 0; i < times.length; i++) {
        final code = _numAt(d['weather_code'], i);
        final max = _numAt(d['temperature_2m_max'], i);
        final min = _numAt(d['temperature_2m_min'], i);
        if (code == null || max == null || min == null) continue;
        daily.add(DailyForecast(
          date: parseKtmLocal('${times[i]}T00:00'),
          condition: WeatherCondition.fromWmo(code.toInt()),
          maxC: max.toDouble(),
          minC: min.toDouble(),
          precipitationMm: _numAt(d['precipitation_sum'], i)?.toDouble() ?? 0,
          precipitationProbability: _numAt(d['precipitation_probability_max'], i)?.round(),
        ));
      }
    }

    return WeatherReport(current: current, hourly: hourly, daily: daily, fetchedAt: fetchedAt);
  }

  static DateTime _hourOf(DateTime t) => DateTime.utc(t.year, t.month, t.day, t.hour);

  static num? _numAt(Object? list, int i) {
    if (list is! List || i >= list.length) return null;
    final v = list[i];
    return v is num ? v : null;
  }
}
