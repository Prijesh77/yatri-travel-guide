import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/geo/geo_point.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/transport/domain/journey_planner.dart';

import '../../helpers/fixtures.dart';

void main() {
  final network = loadBundledNetwork();
  final planner = JourneyPlanner(network);
  final places = loadBundledPlaces();

  test('searchFrom().bestTo() matches plan(maxResults: 1) across the valley', () {
    final rnd = Random(7);
    final origins = [
      thamel,
      for (var i = 0; i < 12; i++) places[rnd.nextInt(places.length)].location,
      const GeoPoint(27.6966, 85.3591), // airport
    ];
    var compared = 0;
    var found = 0;
    for (final time in [ktm(2026, 11, 19, 9), ktm(2026, 11, 19, 13, 30), ktm(2026, 11, 19, 21)]) {
      for (final from in origins) {
        final search = planner.searchFrom(from, time);
        for (final p in places) {
          final expected = planner.plan(from, p.location, time, maxResults: 1);
          final actual = search.bestTo(p.location);
          compared++;
          if (expected.isEmpty) {
            expect(actual, isNull, reason: '$from -> ${p.id} at $time');
            continue;
          }
          found++;
          expect(actual, isNotNull, reason: '$from -> ${p.id} at $time');
          expect(actual!.totalMinutes, expected.first.totalMinutes, reason: '$from -> ${p.id} at $time');
          expect(actual.fare, expected.first.fare, reason: '$from -> ${p.id} at $time');
          expect(actual.transfers, expected.first.transfers, reason: '$from -> ${p.id} at $time');
        }
      }
    }
    expect(compared, greaterThan(2000));
    expect(found, greaterThan(500));
  });
}
