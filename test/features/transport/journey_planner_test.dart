import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/geo/geo_point.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/transport/domain/journey_planner.dart';
import 'package:yatri/features/transport/domain/route_network.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_network.dart';

void main() {
  final noon = ktm(2026, 10, 1, 12);

  group('synthetic network', () {
    final planner = JourneyPlanner(testNetwork());
    const nearA1 = GeoPoint(27.7005, 85.3002);
    const nearA3 = GeoPoint(27.6995, 85.3398);
    const nearB3 = GeoPoint(27.7405, 85.3401);

    test('direct ride with walks at both ends', () {
      final j = planner.plan(nearA1, nearA3, noon).first;
      expect(j.rides.single.route.id, 'A');
      expect(j.transfers, 0);
      expect(j.legs.first, isA<WalkLeg>());
      expect(j.legs.last, isA<WalkLeg>());
      expect(j.totalMinutes, j.legs.fold<int>(0, (s, l) => s + l.minutes));
      // Frequency 6 min -> wait 3 min.
      expect(j.rides.single.waitMinutes, 3);
    });

    test('fare comes from the distance slabs', () {
      final ride = planner.plan(nearA1, nearA3, noon).first.rides.single;
      // ~3.95 km straight x 1.1 route factor = ~4.3 km -> first slab.
      expect(ride.km, closeTo(4.35, 0.2));
      expect(ride.fare, 24);
    });

    test('one transfer between nearby stops, verified routes preferred', () {
      final journeys = planner.plan(nearA1, nearB3, noon);
      final viaTransfer = journeys.firstWhere((j) => j.transfers == 1);
      expect(viaTransfer.rides.map((r) => r.route.id), ['A', 'B']);
      expect(viaTransfer.legs.whereType<WalkLeg>().where((w) => w.fromStop != null && w.toStop != null),
          hasLength(1), reason: 'walk between a3 and b1');
      expect(viaTransfer.fare, 24 + 24); // both rides under 5 km
      expect(viaTransfer.hasRoughStop, isTrue);
      // The historical direct route is also offered but flagged.
      final historical = journeys.firstWhere((j) => j.transfers == 0);
      expect(historical.weakestStatus, RouteStatus.historical);
      expect(historical.allVerified, isFalse);
    });

    test('no transfers when disabled', () {
      final journeys = planner.plan(nearA1, nearB3, noon, maxTransfers: 0);
      expect(journeys.every((j) => j.transfers == 0), isTrue);
    });

    test('route service hours are respected', () {
      final night = planner.plan(nearA1, nearA3, ktm(2026, 10, 1, 21));
      expect(night.single.rides.single.route.id, 'N');
      expect(planner.plan(nearA1, nearA3, noon).map((j) => j.rides.first.route.id), isNot(contains('N')));
    });

    test('rush hour makes rides slower', () {
      final calm = planner.plan(nearA1, nearA3, noon).first.rides.single.rideMinutes;
      final rush = planner.plan(nearA1, nearA3, ktm(2026, 10, 1, 9)).first.rides.single.rideMinutes;
      expect(rush, greaterThan(calm));
    });

    test('nothing when no stop is reachable', () {
      expect(planner.plan(const GeoPoint(27.60, 85.20), nearA3, noon), isEmpty);
    });
  });

  group('bundled data pack', () {
    final network = loadBundledNetwork();
    final planner = JourneyPlanner(network);
    const koteshwor = GeoPoint(27.6780, 85.3490);
    const airport = GeoPoint(27.6966, 85.3591);
    const nagarkot = GeoPoint(27.7156, 85.5203);

    test('Thamel to Koteshwor has a direct bus from the Ratnapark area', () {
      final best = planner.plan(thamel, koteshwor, noon).first;
      expect(best.transfers, 0);
      expect(best.rides.single.alight.name, 'Koteshwor');
      expect(best.fare, network.bus.fareForKm(best.rides.single.km));
    });

    test('Airport to Patan uses verified Sajha routes with one change', () {
      final best = planner.plan(airport, patan, noon).first;
      expect(best.transfers, 1);
      expect(best.allVerified, isTrue);
      expect(best.rides.first.route.id, startsWith('SAJ-05'));
    });

    test('Thamel to Nagarkot changes at Kamalbinayak', () {
      final best = planner.plan(thamel, nagarkot, noon).first;
      expect(best.rides.last.route.id, 'BKT-05');
      expect(best.rides.first.alight.name, 'Kamalbinayak');
    });

    test('journeys on the same stops are grouped', () {
      final groups = JourneyGroup.group(planner.plan(thamel, const GeoPoint(27.70550, 85.31850), noon, maxResults: 8));
      final multi = groups.firstWhere((g) => g.journeys.length > 1);
      expect(multi.routeIdsPerRide.single.length, multi.journeys.length);
      expect(multi.journeys.map((j) => j.stopSignature).toSet(), hasLength(1));
      expect(groups.map((g) => g.best.stopSignature).toSet(), hasLength(groups.length));
    });

    test('fares use the April 2026 slabs', () {
      expect(network.bus.fareSlabs.map((s) => s.fare), [24, 33, 39, 44, 50]);
    });
  });
}
