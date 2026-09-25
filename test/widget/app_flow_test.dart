import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/app/app.dart';
import 'package:yatri/core/config/app_config.dart';
import 'package:yatri/core/data/json_source.dart';
import 'package:yatri/core/data/key_value_store.dart';
import 'package:yatri/core/geo/geo_point.dart';
import 'package:yatri/core/providers/core_providers.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/alerts/application/alerts_providers.dart';
import 'package:yatri/features/alerts/data/alerts_repository.dart';
import 'package:yatri/features/itinerary/application/itinerary_controller.dart';
import 'package:yatri/features/location/application/location_providers.dart';
import 'package:yatri/features/location/data/location_service.dart';
import 'package:yatri/features/map/application/map_providers.dart';
import 'package:yatri/features/places/application/places_providers.dart';
import 'package:yatri/features/places/data/places_repository.dart';
import 'package:yatri/features/places/presentation/place_detail_screen.dart';
import 'package:yatri/features/stays/application/stays_providers.dart';
import 'package:yatri/features/stays/data/stays_repository.dart';
import 'package:yatri/features/transport/application/transport_providers.dart';
import 'package:yatri/features/transport/data/routes_repository.dart';
import 'package:yatri/features/transport/presentation/journey_card.dart';
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
        staysRepositoryProvider.overrideWithValue(JsonStaysRepository(fileLoader('stays.json'))),
        clockProvider.overrideWithValue(FixedClock(now)),
        weatherRepositoryProvider.overrideWithValue(_FakeWeather(weather)),
        locationServiceProvider.overrideWithValue(_FakeLocation(thamel)),
        mapTileProviderProvider.overrideWithValue(_NoTiles()),
        aiConfigProvider.overrideWithValue(const AiConfig(apiKey: '', model: 'test')),
      ],
      child: const YatriApp(),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> disposeApp(WidgetTester tester) => tester.pumpWidget(const SizedBox());

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  Finder scrollableOf(Type screen) => find.descendant(of: find.byType(screen), matching: find.byType(Scrollable)).first;

  testWidgets('home follows the wireframe and ranks for the rain', (tester) async {
    await pumpApp(tester, weather: reportOf(rainy, now));

    expect(find.text('Yatri'), findsOneWidget);
    expect(find.text('Plan a trip with AI'), findsOneWidget);
    for (final label in ['Transport', 'Stays', 'Education', 'Fitness', 'Adventure', 'Health']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('No disruptions'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Good for today'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('21°'), findsOneWidget);
    final rainReason = find.textContaining('Indoor, good for a rainy afternoon');
    for (var i = 0; i < 20 && rainReason.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(rainReason, findsWidgets);
    await disposeApp(tester);
  });

  testWidgets('planned categories open a placeholder screen', (tester) async {
    await pumpApp(tester, weather: reportOf(sunny, now));
    await tester.tap(find.text('Fitness'));
    await tester.pumpAndSettle();
    expect(find.text('Search gyms, studios'), findsOneWidget);
    expect(find.text('Details coming soon'), findsNWidgets(2));
    await disposeApp(tester);
  });

  testWidgets('place detail adds to the plan', (tester) async {
    await pumpApp(tester, weather: reportOf(sunny, now));

    await tester.scrollUntilVisible(find.text('Patan Museum'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Patan Museum'));
    await tester.pumpAndSettle();
    expect(find.text('10:30–17:30'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Getting there'), 200, scrollable: scrollableOf(PlaceDetailScreen));
    expect(find.textContaining('Taxi', findRichText: true), findsWidgets);

    await tester.tap(find.text('Add to itinerary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View plan'));
    await tester.pumpAndSettle();
    expect(find.text('Suggested itinerary'), findsOneWidget);
    expect(find.textContaining('Patan Museum'), findsWidgets);
    await disposeApp(tester);
  });

  testWidgets('plan with AI off uses the on-device planner; stops can be removed and restored', (tester) async {
    await pumpApp(tester, weather: reportOf(sunny, now));
    await tapTab(tester, 'Plan');
    expect(find.text('Plan with AI'), findsOneWidget);
    expect(find.textContaining('AI is off'), findsOneWidget);

    await tester.tap(find.text('Culture'));
    await tester.tap(find.text('Generate itinerary'));
    await tester.pumpAndSettle();
    expect(find.text('Planned on this device (condition-aware)'), findsOneWidget);

    int stopCount() {
      final summary = find.textContaining(RegExp(r'\d+ stops? · ')).evaluate().single.widget as Text;
      return int.parse(RegExp(r'(\d+) stops?').firstMatch(summary.data!)!.group(1)!);
    }

    final before = stopCount();
    expect(before, greaterThan(1));
    await tester.scrollUntilVisible(find.byTooltip('Remove stop').first, 200, scrollable: scrollableOf(Scaffold));
    await tester.tap(find.byTooltip('Remove stop').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining(RegExp(r'\d+ stops? · ')), -200, scrollable: scrollableOf(Scaffold));
    expect(stopCount(), before - 1);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(stopCount(), before);
    await disposeApp(tester);
  });

  testWidgets('transit finds bus routes to a hub', (tester) async {
    await pumpApp(tester, weather: reportOf(sunny, now));
    await tapTab(tester, 'Transit');
    expect(find.text('Find your route'), findsOneWidget);
    expect(find.text('Popular hubs'), findsOneWidget);

    await tester.tap(find.text('Lagankhel Bus Park'));
    await tester.pumpAndSettle();
    expect(find.text('Best option'), findsOneWidget);
    expect(find.byType(JourneyCard), findsWidgets);
    expect(find.textContaining('Board at'), findsWidgets);
    expect(find.text('Other ways to go'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('live conditions: samples, confirm, and home counts', (tester) async {
    await pumpApp(tester, weather: reportOf(sunny, now));
    await tapTab(tester, 'Alerts');
    expect(find.text('All clear'), findsOneWidget);

    await tester.tap(find.text('Load sample reports'));
    await tester.pumpAndSettle();
    expect(find.text('Road closed – Naxal, near Narayanhiti'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.textContaining('14 confirms'), findsOneWidget);

    // Newest disruption first: the Koteshwor traffic sample (5 confirms).
    await tester.tap(find.text('Still there').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('6 confirms'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);

    await tapTab(tester, 'Home');
    expect(find.text('2 disruptions'), findsOneWidget);
    expect(find.text('1 event today'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('fare check shows crowdsourced range and official fare', (tester) async {
    await pumpApp(tester, weather: reportOf(sunny, now));
    await tapTab(tester, 'Transit');
    await tester.tap(find.byTooltip('Fare check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load sample fare reports'));
    await tester.pumpAndSettle();

    Future<void> pick(String field, String query, String result) async {
      await tester.tap(find.text(field));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, query);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, result).first);
      await tester.pumpAndSettle();
    }

    await pick('From (stop or place)', 'Ratnapark', 'Ratnapark');
    await pick('To (stop or place)', 'Koteshwor', 'Koteshwor');
    expect(find.text('Based on 7 crowdsourced reports · includes sample data'), findsOneWidget);
    expect(find.text('NPR 32–37'), findsOneWidget); // 10th-90th percentile
    expect(find.textContaining('Official fare: NPR 33'), findsOneWidget);
    await disposeApp(tester);
  });
}
