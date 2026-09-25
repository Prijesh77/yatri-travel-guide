import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/app/app.dart';
import 'package:yatri/core/data/json_source.dart';
import 'package:yatri/core/data/key_value_store.dart';
import 'package:yatri/features/alerts/application/alerts_providers.dart';
import 'package:yatri/features/alerts/data/alerts_repository.dart';
import 'package:yatri/features/places/application/places_providers.dart';
import 'package:yatri/features/places/data/places_repository.dart';
import 'package:yatri/features/places/presentation/place_detail_screen.dart';
import 'package:yatri/features/transport/application/transport_providers.dart';
import 'package:yatri/features/transport/data/routes_repository.dart';
import 'package:yatri/core/geo/geo_point.dart';
import 'package:yatri/core/providers/core_providers.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/location/application/location_providers.dart';
import 'package:yatri/features/location/data/location_service.dart';
import 'package:yatri/features/map/application/map_providers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:yatri/features/weather/application/weather_providers.dart';
import 'package:yatri/features/weather/data/weather_repository.dart';
import 'package:yatri/features/weather/domain/weather.dart';

import '../helpers/fixtures.dart';

class _FakeWeather implements WeatherRepository {
  _FakeWeather(this.report);
  final WeatherReport report;

  @override
  Future<WeatherReport> getWeather() async => report;
}

class _FakeLocation implements LocationService {
  _FakeLocation(this.location);
  final GeoPoint? location;

  @override
  Future<GeoPoint?> currentLocation() async => location;
}

/// Serves blank tiles without touching the network or disk.
class _NoTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => MemoryImage(_transparentPng);
}

final _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

void main() {
  final now = ktm(2026, 10, 1, 14); // Thursday afternoon

  OfflineFirstJsonLoader fileLoader(String name) => OfflineFirstJsonLoader(
        cacheKey: name,
        bundled: StringJsonSource(File('assets/data/$name').readAsStringSync()),
        store: MemoryStore(),
      );

  Future<void> pumpApp(WidgetTester tester, {required WeatherReport weather}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(MemoryStore()),
        // Read data files directly: the asset bundle caches futures across
        // tests, which does not mix well with the fake-async test zone.
        placesRepositoryProvider.overrideWithValue(JsonPlacesRepository(fileLoader('places.json'))),
        routesRepositoryProvider.overrideWithValue(JsonRoutesRepository(fileLoader('routes.json'))),
        alertsRepositoryProvider.overrideWithValue(JsonAlertsRepository(fileLoader('alerts.json'))),
        clockProvider.overrideWithValue(FixedClock(now)),
        weatherRepositoryProvider.overrideWithValue(_FakeWeather(weather)),
        locationServiceProvider.overrideWithValue(_FakeLocation(thamel)),
        mapTileProviderProvider.overrideWithValue(_NoTiles()),
      ],
      child: const YatriApp(),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> disposeApp(WidgetTester tester) => tester.pumpWidget(const SizedBox());

  testWidgets('home shows weather and rain-aware suggestions', (tester) async {
    await pumpApp(tester, weather: reportOf(rainy, now));

    expect(find.text('Good for today'), findsOneWidget);
    expect(find.text('21°'), findsOneWidget);
    expect(find.text('Rain'), findsOneWidget);
    expect(find.textContaining('Indoor, good for a rainy afternoon'), findsWidgets);

    // Filter to temples: every card is then a temple (or has temple as a
    // secondary category).
    await tester.tap(find.widgetWithText(ChoiceChip, 'Temples'));
    await tester.pumpAndSettle();
    expect(find.text('Golden Temple (Hiranya Varna Mahavihar)'), findsOneWidget);
    expect(find.text('Patan Museum'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('place detail shows info and adds to the itinerary', (tester) async {
    await pumpApp(tester, weather: reportOf(sunny, now));

    await tester.scrollUntilVisible(find.text('Patan Museum'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Patan Museum'));
    await tester.pumpAndSettle();
    expect(find.text('Opening hours'), findsOneWidget);
    expect(find.text('10:30–17:30'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Getting there'),
      300,
      scrollable: find.descendant(of: find.byType(PlaceDetailScreen), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Getting there'), findsOneWidget);
    final taxi = find.textContaining('Taxi', findRichText: true);
    await tester.scrollUntilVisible(taxi, 200,
        scrollable: find.descendant(of: find.byType(PlaceDetailScreen), matching: find.byType(Scrollable)).first);
    expect(taxi, findsOneWidget);

    await tester.tap(find.text('Add to itinerary'));
    await tester.pumpAndSettle();
    expect(find.text('Added to your plan'), findsOneWidget);

    await tester.tap(find.text('View plan'));
    await tester.pumpAndSettle();
    expect(find.text('Your day'), findsOneWidget);
    expect(find.text('Patan Museum'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('planner builds a day plan that can be edited', (tester) async {
    await pumpApp(tester, weather: reportOf(sunny, now));

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Plan your day'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Plan my day'), 300, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Plan my day'));
    await tester.pumpAndSettle();

    expect(find.text('Your day'), findsOneWidget);
    int stopCount() {
      final summary = find.textContaining(RegExp(r'^\d+ stops? · ')).evaluate().single.widget as Text;
      return int.parse(summary.data!.split(' ').first);
    }

    final before = stopCount();
    expect(before, greaterThan(1));

    await tester.tap(find.byTooltip('Remove stop').first);
    await tester.pumpAndSettle();
    expect(stopCount(), before - 1);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(stopCount(), before);
    await disposeApp(tester);
  });
}
