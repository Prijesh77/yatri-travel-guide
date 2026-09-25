import 'dart:convert';
import 'dart:io';

import 'package:yatri/core/data/json_source.dart';
import 'package:yatri/core/data/key_value_store.dart';
import 'package:yatri/core/geo/geo_point.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/places/data/places_repository.dart';
import 'package:yatri/features/places/domain/opening_hours.dart';
import 'package:yatri/features/places/domain/place.dart';
import 'package:yatri/features/places/domain/place_category.dart';
import 'package:yatri/features/recommendations/domain/recommendation_context.dart';
import 'package:yatri/features/transport/domain/route_network.dart';
import 'package:yatri/features/weather/domain/weather.dart';

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<Place> loadBundledPlaces() => JsonPlacesRepository.parsePlaces(readJson('assets/data/places.json'));

RouteNetwork loadBundledNetwork() => RouteNetwork.fromJson(readJson('assets/data/routes.json'));

Place testPlace({
  String id = 'p',
  PlaceCategory category = PlaceCategory.heritage,
  List<PlaceCategory> secondary = const [],
  Setting setting = Setting.outdoor,
  GeoPoint location = const GeoPoint(27.7042, 85.3067),
  int visitMinutes = 60,
  OpeningHours hours = const OpeningHours.always(),
  List<String> bestTimes = const [],
  int popularity = 3,
  City city = City.kathmandu,
}) =>
    Place(
      id: id,
      name: id,
      city: city,
      category: category,
      secondaryCategories: secondary,
      location: location,
      visitMinutes: visitMinutes,
      entryFee: const EntryFee.free(),
      openingHours: hours,
      setting: setting,
      description: '',
      bestTimes: bestTimes,
      popularity: popularity,
    );

OpeningHours hours(String open, String close, {Set<int> closed = const {}}) =>
    OpeningHours(openMinute: parseHhMm(open), closeMinute: parseHhMm(close), closedWeekdays: closed);

WeatherSnapshot rainy(DateTime t) => WeatherSnapshot(
      time: t,
      temperatureC: 21,
      condition: WeatherCondition.rain,
      precipitationMm: 2.5,
      precipitationProbability: 90,
      usAqi: 40,
    );

WeatherSnapshot sunny(DateTime t, {int aqi = 40, double temp = 24}) => WeatherSnapshot(
      time: t,
      temperatureC: temp,
      condition: WeatherCondition.clear,
      precipitationProbability: 0,
      usAqi: aqi,
    );

WeatherReport reportOf(WeatherSnapshot Function(DateTime) at, DateTime day) {
  final hours = [for (var h = 0; h < 24; h++) at(ktm(day.year, day.month, day.day, h))];
  return WeatherReport(current: hours.first, hourly: hours, fetchedAt: day);
}

/// 2026-09-29 is a Tuesday.
final tuesday = ktm(2026, 9, 29);

/// 2026-10-01 is a Thursday.
final thursday = ktm(2026, 10, 1);

const thamel = GeoPoint(27.7154, 85.3123);
const patan = GeoPoint(27.67275, 85.3253);

/// Context at a time with no weather, location or alerts.
class RecommendationContextFixture {
  static RecommendationContext at(DateTime t) => RecommendationContext(time: t);
}

/// Loads a bundled data file straight from disk (no asset bundle).
class OfflineFirstJsonLoaderFixture {
  OfflineFirstJsonLoaderFixture(String name)
      : loader = OfflineFirstJsonLoader(
          cacheKey: name,
          bundled: StringJsonSource(File('assets/data/$name').readAsStringSync()),
          store: MemoryStore(),
        );
  final OfflineFirstJsonLoader loader;
}
