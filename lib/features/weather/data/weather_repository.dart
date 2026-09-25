import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/data/key_value_store.dart';
import '../../../core/geo/geo_point.dart';
import '../../../core/time/kathmandu_time.dart';
import '../domain/weather.dart';
import 'open_meteo_parser.dart';

abstract interface class WeatherRepository {
  /// Returns fresh weather, or the last saved result (marked
  /// [WeatherReport.fromCache]) when offline. Throws only when there is
  /// neither.
  Future<WeatherReport> getWeather();
}

/// Open-Meteo (free, no API key) forecast + air-quality with an offline cache
/// of the raw responses.
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({
    required this.store,
    http.Client? client,
    this.location = ValleyBounds.center,
    this.clock = const SystemClock(),
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final KeyValueStore store;
  final http.Client _client;
  final GeoPoint location;
  final Clock clock;
  final Duration timeout;

  static const cacheKey = 'cache.weather.v1';

  Uri get forecastUri => Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${location.lat}',
        'longitude': '${location.lng}',
        'current': 'temperature_2m,precipitation,weather_code,is_day',
        'hourly': 'temperature_2m,precipitation,precipitation_probability,weather_code,is_day',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
        'timezone': 'Asia/Kathmandu',
        'forecast_days': '7',
      });

  Uri get airQualityUri => Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
        'latitude': '${location.lat}',
        'longitude': '${location.lng}',
        'current': 'us_aqi',
        'hourly': 'us_aqi',
        'timezone': 'Asia/Kathmandu',
        'forecast_days': '5',
      });

  @override
  Future<WeatherReport> getWeather() async {
    try {
      final forecast = await _getJson(forecastUri);
      Map<String, dynamic>? air;
      try {
        air = await _getJson(airQualityUri);
      } catch (_) {
        air = null; // Air quality is a bonus; weather alone is still useful.
      }
      final fetchedAt = clock.now();
      final report = OpenMeteoParser.parse(forecast: forecast, airQuality: air, fetchedAt: fetchedAt);
      await store.setString(
        cacheKey,
        jsonEncode({'fetchedAt': fetchedAt.toIso8601String(), 'forecast': forecast, 'air': air}),
      );
      return report;
    } catch (error) {
      final cached = _readCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  WeatherReport? _readCache() {
    final raw = store.getString(cacheKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return OpenMeteoParser.parse(
        forecast: json['forecast'] as Map<String, dynamic>,
        airQuality: json['air'] as Map<String, dynamic>?,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      ).markCached();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final res = await _client.get(uri).timeout(timeout);
    if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}', uri);
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}
