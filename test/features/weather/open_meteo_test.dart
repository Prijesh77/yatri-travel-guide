import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yatri/core/data/key_value_store.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/weather/data/open_meteo_parser.dart';
import 'package:yatri/features/weather/data/weather_repository.dart';
import 'package:yatri/features/weather/domain/weather.dart';

import '../../helpers/fixtures.dart';

void main() {
  final forecast = readJson('test/fixtures/open_meteo_forecast.json');
  final air = readJson('test/fixtures/open_meteo_air.json');
  final fetchedAt = ktm(2026, 10, 1, 14, 20);

  group('OpenMeteoParser', () {
    final report = OpenMeteoParser.parse(forecast: forecast, airQuality: air, fetchedAt: fetchedAt);

    test('parses current conditions in Kathmandu time', () {
      expect(report.current.time, ktm(2026, 10, 1, 14, 15));
      expect(report.current.temperatureC, 22.4);
      expect(report.current.condition, WeatherCondition.rain);
      expect(report.current.isWet, isTrue);
      expect(report.current.usAqi, 162);
      expect(report.current.airQuality, AirQualityLevel.unhealthy);
    });

    test('parses hourly data, skipping incomplete hours, and merges AQI', () {
      expect(report.hourly.length, 3);
      expect(report.hourly[0].condition, WeatherCondition.cloudy);
      expect(report.hourly[0].usAqi, 150);
      expect(report.hourly[2].condition, WeatherCondition.rain);
      expect(report.hourly[2].usAqi, isNull);
    });

    test('parses daily forecast', () {
      expect(report.daily.length, 2);
      expect(report.daily[1].date, ktm(2026, 10, 2));
      expect(report.daily[1].condition, WeatherCondition.clear);
      expect(report.daily[0].precipitationProbability, 95);
    });

    test('at() picks the nearest hour, then the day', () {
      expect(report.at(ktm(2026, 10, 1, 15, 20))!.time, ktm(2026, 10, 1, 15));
      final tomorrow = report.at(ktm(2026, 10, 2, 11))!;
      expect(tomorrow.condition, WeatherCondition.clear);
      expect(report.at(ktm(2026, 10, 9, 11)), isNull);
    });

    test('air quality is optional', () {
      final noAir = OpenMeteoParser.parse(forecast: forecast, fetchedAt: fetchedAt);
      expect(noAir.current.usAqi, isNull);
    });
  });

  test('WMO codes map to conditions', () {
    expect(WeatherCondition.fromWmo(0), WeatherCondition.clear);
    expect(WeatherCondition.fromWmo(45), WeatherCondition.fog);
    expect(WeatherCondition.fromWmo(53), WeatherCondition.drizzle);
    expect(WeatherCondition.fromWmo(82), WeatherCondition.heavyRain);
    expect(WeatherCondition.fromWmo(95), WeatherCondition.thunderstorm);
  });

  group('OpenMeteoWeatherRepository offline cache', () {
    OpenMeteoWeatherRepository repo(MemoryStore store, {required bool online}) => OpenMeteoWeatherRepository(
          store: store,
          clock: FixedClock(fetchedAt),
          client: MockClient((req) async {
            if (!online) throw http.ClientException('offline');
            final body = req.url.host.startsWith('air') ? air : forecast;
            return http.Response(jsonEncode(body), 200);
          }),
        );

    test('returns fresh data and caches it', () async {
      final store = MemoryStore();
      final report = await repo(store, online: true).getWeather();
      expect(report.fromCache, isFalse);
      expect(store.getString(OpenMeteoWeatherRepository.cacheKey), isNotNull);
    });

    test('falls back to the last result when offline', () async {
      final store = MemoryStore();
      await repo(store, online: true).getWeather();
      final offline = await repo(store, online: false).getWeather();
      expect(offline.fromCache, isTrue);
      expect(offline.fetchedAt, fetchedAt);
      expect(offline.current.temperatureC, 22.4);
    });

    test('throws when offline with nothing cached', () async {
      expect(repo(MemoryStore(), online: false).getWeather(), throwsA(isA<http.ClientException>()));
    });
  });
}
