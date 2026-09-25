import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/geo/geo_point.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/alerts/domain/condition_alert.dart';
import 'package:yatri/features/places/domain/place_category.dart';

import '../../helpers/fixtures.dart';

/// Guards the hand-edited JSON files in assets/data. Run `flutter test` after
/// editing them.
void main() {
  group('places.json', () {
    final places = loadBundledPlaces();

    test('has about 60 places across the three cities', () {
      expect(places.length, greaterThanOrEqualTo(55));
      for (final city in City.values) {
        expect(places.where((p) => p.city == city).length, greaterThanOrEqualTo(10), reason: city.name);
      }
    });

    test('covers every category', () {
      for (final c in PlaceCategory.values) {
        expect(places.where((p) => p.category == c), isNotEmpty, reason: c.name);
      }
    });

    test('ids are unique, kebab-case', () {
      expect(places.map((p) => p.id).toSet().length, places.length);
      for (final p in places) {
        expect(p.id, matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')));
      }
    });

    test('coordinates are inside the Kathmandu Valley', () {
      for (final p in places) {
        expect(ValleyBounds.contains(p.location), isTrue, reason: '${p.id} ${p.location}');
      }
    });

    test('values are plausible', () {
      for (final p in places) {
        expect(p.visitMinutes, inInclusiveRange(15, 480), reason: p.id);
        expect(p.entryFee.foreigner, greaterThanOrEqualTo(p.entryFee.saarc), reason: p.id);
        expect(p.entryFee.saarc, greaterThanOrEqualTo(p.entryFee.nepali), reason: p.id);
        expect(p.description.length, inInclusiveRange(40, 300), reason: p.id);
        for (final t in p.bestTimes) {
          expect(DayPart.tryParse(t), isNotNull, reason: '${p.id}: bestTimes "$t"');
        }
        expect(p.secondaryCategories, isNot(contains(p.category)), reason: p.id);
      }
    });
  });

  group('routes.json', () {
    final network = loadBundledNetwork();

    test('every stop is in the valley and every route has stops', () {
      for (final s in network.stops.values) {
        expect(ValleyBounds.contains(s.location), isTrue, reason: s.id);
      }
      for (final r in network.routes) {
        expect(r.stops.length, greaterThanOrEqualTo(2), reason: r.id);
      }
      expect(network.routes.map((r) => r.id).toSet().length, network.routes.length);
    });

    test('fare slabs increase with distance', () {
      final slabs = network.bus.fareSlabs;
      for (var i = 1; i < slabs.length; i++) {
        expect(slabs[i].fare, greaterThanOrEqualTo(slabs[i - 1].fare));
      }
    });
  });

  test('alerts.json parses', () {
    final json = readJson('assets/data/alerts.json');
    for (final a in json['alerts'] as List) {
      final alert = ConditionAlert.fromJson(a as Map<String, dynamic>);
      expect(alert.end.isAfter(alert.start), isTrue, reason: alert.id);
    }
  });
}
