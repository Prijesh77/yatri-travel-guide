import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/data/key_value_store.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/transport/data/fare_reports_repository.dart';
import 'package:yatri/features/transport/domain/fare_report.dart';

void main() {
  final now = ktm(2026, 10, 1, 14);

  group('FareStats', () {
    test('empty input has no stats', () {
      expect(FareStats.of([]), isNull);
      expect(FareStats.of([0, -5]), isNull);
    });

    test('single report', () {
      final s = FareStats.of([33])!;
      expect((s.count, s.low, s.typical, s.high), (1, 33, 33, 33));
      expect(s.position(33), 0.5);
    });

    test('percentiles ignore one outlier', () {
      final s = FareStats.of([30, 33, 33, 33, 35, 33, 33, 34, 32, 120])!;
      expect(s.count, 10);
      expect(s.typical, 33);
      expect(s.low, 32); // 10th percentile
      expect(s.high, lessThan(120));
      expect(s.isHigh(120), isTrue);
      expect(s.isHigh(34), isFalse);
    });

    test('position is clamped to the range', () {
      final s = FareStats.of([20, 30])!;
      expect(s.position(10), 0);
      expect(s.position(100), 1);
    });
  });

  group('LocalFareReportsRepository', () {
    test('matches trips in either direction, ignoring case and spaces', () async {
      final repo = LocalFareReportsRepository(MemoryStore());
      await repo.add(from: 'Ratnapark', to: 'Koteshwor', mode: FareMode.bus, fareNpr: 33, now: now);
      await repo.add(from: 'koteshwor ', to: 'RATNAPARK', mode: FareMode.bus, fareNpr: 35, now: now);
      await repo.add(from: 'Ratnapark', to: 'Koteshwor', mode: FareMode.taxi, fareNpr: 400, now: now);
      expect(repo.forTrip('Ratnapark', 'Koteshwor', mode: FareMode.bus), hasLength(2));
      expect(repo.forTrip('Koteshwor', 'Ratnapark'), hasLength(3));
      expect(repo.forTrip('Ratnapark', 'Boudha'), isEmpty);
    });

    test('rejects non-positive fares', () async {
      final repo = LocalFareReportsRepository(MemoryStore());
      expect(() => repo.add(from: 'a', to: 'b', mode: FareMode.bus, fareNpr: 0, now: now), throwsArgumentError);
    });

    test('samples are flagged and replace earlier samples', () async {
      final store = MemoryStore();
      final repo = LocalFareReportsRepository(store);
      await repo.add(from: 'a', to: 'b', mode: FareMode.tempo, fareNpr: 20, now: now);
      await repo.loadSamples(now);
      final count = repo.all().length;
      await repo.loadSamples(now);
      expect(repo.all(), hasLength(count));
      expect(repo.all().where((r) => !r.isSample), hasLength(1));
      expect(LocalFareReportsRepository(store).forTrip('Ratnapark', 'Koteshwor', mode: FareMode.bus), isNotEmpty);
    });
  });
}
