import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/data/key_value_store.dart';
import 'package:yatri/core/geo/geo_point.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/alerts/data/community_reports_repository.dart';
import 'package:yatri/features/alerts/domain/condition_alert.dart';
import 'package:yatri/features/places/domain/place_category.dart';

import '../../helpers/fixtures.dart';

void main() {
  final now = ktm(2026, 10, 1, 14);
  const naxal = GeoPoint(27.7150, 85.3225);

  NewReport closure({Duration? duration}) => NewReport(
        type: AlertType.roadClosure,
        title: '  Road closed at Naxal ',
        location: naxal,
        locationLabel: 'Naxal',
        duration: duration,
      );

  group('LocalReportsRepository', () {
    test('adds a community report with defaults', () async {
      final repo = LocalReportsRepository(MemoryStore());
      final a = await repo.add(closure(), now);
      expect(a.title, 'Road closed at Naxal');
      expect(a.source, AlertSource.community);
      expect(a.start, now);
      expect(a.end, now.add(LocalReportsRepository.defaultDuration(AlertType.roadClosure)));
      expect(a.location, naxal);
      expect(repo.all().single.id, a.id);
    });

    test('reports survive a restart (same store)', () async {
      final store = MemoryStore();
      await LocalReportsRepository(store).add(closure(), now);
      expect(LocalReportsRepository(store).all(), hasLength(1));
    });

    test('a device can confirm a report once', () async {
      final repo = LocalReportsRepository(MemoryStore());
      final a = await repo.add(closure(), now);
      expect(await repo.confirm(a.id), isTrue);
      expect(await repo.confirm(a.id), isFalse);
      expect(repo.hasConfirmed(a.id), isTrue);
      expect(repo.all().single.confirmations, 1);
    });

    test('prune drops expired reports', () async {
      final repo = LocalReportsRepository(MemoryStore());
      await repo.add(closure(duration: const Duration(minutes: 30)), now);
      await repo.add(closure(duration: const Duration(hours: 5)), now.add(const Duration(microseconds: 1)));
      await repo.prune(now.add(const Duration(hours: 1)));
      expect(repo.all(), hasLength(1));
    });

    test('samples are labelled and can be loaded twice without duplicates', () async {
      final repo = LocalReportsRepository(MemoryStore());
      await repo.loadSamples(now);
      await repo.loadSamples(now);
      final all = repo.all();
      expect(all, hasLength(3));
      expect(all.every((a) => a.source == AlertSource.sample), isTrue);
      expect(all.where((a) => a.isEvent), hasLength(1));
    });

    test('JSON round trip keeps location and counts', () {
      final a = ConditionAlert(
        id: 'x',
        type: AlertType.traffic,
        title: 'Jam',
        start: now,
        end: now.add(const Duration(hours: 1)),
        location: naxal,
        radiusKm: 0.7,
        locationLabel: 'Naxal',
        source: AlertSource.community,
        reportedAt: now,
        confirmations: 3,
      );
      final back = ConditionAlert.fromJson(a.toJson());
      expect(back.location, naxal);
      expect(back.radiusKm, 0.7);
      expect(back.start, now);
      expect(back.source, AlertSource.community);
      expect(back.confirmations, 3);
    });
  });

  group('location-aware alerts', () {
    final alert = ConditionAlert(
      id: 'c',
      type: AlertType.closure,
      title: 'Closed',
      start: now,
      end: now.add(const Duration(hours: 2)),
      location: const GeoPoint(27.7143, 85.3152), // Garden of Dreams
      radiusKm: 0.2,
    );

    test('affects only places within the radius', () {
      final garden = testPlace(id: 'garden', location: const GeoPoint(27.71425, 85.31525));
      final far = testPlace(id: 'far', location: patan);
      expect(alert.affects(garden), isTrue);
      expect(alert.affects(far), isFalse);
      expect(alert.isValleyWide, isFalse);
    });

    test('city scope still works', () {
      final cityAlert = ConditionAlert(
          id: 'b', type: AlertType.bandh, title: 'B', start: now, end: now, cities: {City.bhaktapur});
      expect(cityAlert.affects(testPlace(city: City.bhaktapur)), isTrue);
      expect(cityAlert.affects(testPlace(city: City.lalitpur)), isFalse);
    });

    test('liesOnPath detects a closure between two points', () {
      const west = GeoPoint(27.7150, 85.3000);
      const east = GeoPoint(27.7150, 85.3500);
      final onRoad = ConditionAlert(
          id: 'r', type: AlertType.roadClosure, title: 'R', start: now, end: now, location: naxal, radiusKm: 0.3);
      expect(onRoad.liesOnPath(west, east), isTrue);
      expect(onRoad.liesOnPath(const GeoPoint(27.66, 85.30), const GeoPoint(27.66, 85.35)), isFalse);
    });

    test('relevant today includes later events but not ended ones', () {
      final later = ConditionAlert(
          id: 'l', type: AlertType.festival, title: 'L', start: ktm(2026, 10, 1, 18), end: ktm(2026, 10, 1, 20));
      final ended = ConditionAlert(
          id: 'e', type: AlertType.traffic, title: 'E', start: ktm(2026, 10, 1, 8), end: ktm(2026, 10, 1, 9));
      final tomorrow = ConditionAlert(
          id: 't', type: AlertType.festival, title: 'T', start: ktm(2026, 10, 2, 10), end: ktm(2026, 10, 2, 12));
      expect(later.isRelevantOn(now), isTrue);
      expect(ended.isRelevantOn(now), isFalse);
      expect(tomorrow.isRelevantOn(now), isFalse);
    });
  });
}
