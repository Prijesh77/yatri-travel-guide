import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/geo/geo_point.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/alerts/domain/condition_alert.dart';
import 'package:yatri/features/transport/domain/fare_estimator.dart';
import 'package:yatri/features/transport/domain/route_network.dart';
import 'package:yatri/features/transport/domain/transport_option.dart';

import '../../helpers/fixtures.dart';

void main() {
  final network = loadBundledNetwork();
  final estimator = FareEstimator(network);
  final midday = ktm(2026, 10, 1, 13); // outside rush hours
  const bhaktapurSquare = GeoPoint(27.6722, 85.4281);
  const ratnaPark = GeoPoint(27.7060, 85.3150);

  TransportOption optionOf(List<TransportOption> options, TransportMode mode) =>
      options.firstWhere((o) => o.mode == mode);

  group('taxi and bike taxi fares', () {
    const model = HailedModel(
      speedKmh: 20,
      pickupMinutes: 5,
      baseFare: 100,
      perKm: 50,
      minFare: 250,
      fareSpread: 0.2,
      night: TimeWindow(21 * 60, 6 * 60),
      nightMultiplier: 1.5,
    );

    test('short rides pay the minimum fare', () {
      // 100 + 50 * 1 = 150 < 250 minimum.
      expect(estimator.hailedFare(model, 1), const FareRange(200, 300));
    });

    test('longer rides pay base plus per-km', () {
      // 100 + 50 * 10 = 600, +/- 20%.
      expect(estimator.hailedFare(model, 10), const FareRange(480, 720));
    });

    test('night multiplier applies', () {
      // 600 * 1.5 = 900, +/- 20%.
      expect(estimator.hailedFare(model, 10, night: true), const FareRange(720, 1080));
    });

    test('night window wraps past midnight', () {
      expect(model.night!.contains(ktm(2026, 10, 1, 23)), isTrue);
      expect(model.night!.contains(ktm(2026, 10, 1, 3)), isTrue);
      expect(model.night!.contains(ktm(2026, 10, 1, 12)), isFalse);
    });

    test('taxi at night is flagged and costs more than by day', () {
      final day = estimator.hailedOption(TransportMode.taxi, 8, midday);
      final night = estimator.hailedOption(TransportMode.taxi, 8, ktm(2026, 10, 1, 22));
      expect(night.notes, contains(TransportNote.nightFare));
      expect(night.fare.min, greaterThan(day.fare.min));
    });

    test('rush hour makes road trips slower', () {
      final calm = estimator.hailedOption(TransportMode.taxi, 8, midday);
      final rush = estimator.hailedOption(TransportMode.taxi, 8, ktm(2026, 10, 1, 9));
      expect(rush.durationMinutes, greaterThan(calm.durationMinutes));
      expect(rush.notes, contains(TransportNote.rushHour));
    });

    test('bike taxi is cheaper than a taxi', () {
      final options = estimator.optionsFor(thamel, patan, midday);
      expect(optionOf(options, TransportMode.bikeTaxi).fare.max,
          lessThan(optionOf(options, TransportMode.taxi).fare.min));
    });
  });

  group('bus', () {
    test('fare slabs by distance', () {
      final bus = network.bus;
      expect(bus.fareForKm(3), 20);
      expect(bus.fareForKm(5), 20);
      expect(bus.fareForKm(7.5), 25);
      expect(bus.fareForKm(5000), bus.fareSlabs.last.fare);
    });

    test('finds the direct Ratna Park - Bhaktapur route', () {
      final bus = estimator.busOption(ratnaPark, bhaktapurSquare, midday)!;
      expect(bus.routeName, 'Ratna Park – Bhaktapur');
      expect(bus.boardAt, 'Ratna Park');
      expect(bus.alightAt, 'Bhaktapur Bus Park');
      expect(bus.isEstimate, isFalse);
      expect(bus.available, isTrue);
      expect(bus.fare.isExact, isTrue);
      expect(bus.fare.min, network.bus.fareForKm(bus.distanceKm));
    });

    test('flat fare routes use their flat fare', () {
      const nagarkot = GeoPoint(27.7156, 85.5203);
      final bus = estimator.busOption(bhaktapurSquare, nagarkot, midday)!;
      expect(bus.routeName, 'Bhaktapur – Nagarkot');
      expect(bus.fare, const FareRange.exact(70));
    });

    test('works in either direction', () {
      final there = estimator.busOption(ratnaPark, bhaktapurSquare, midday)!;
      final back = estimator.busOption(bhaktapurSquare, ratnaPark, midday)!;
      expect(back.routeName, there.routeName);
      expect(back.fare, there.fare);
    });

    test('falls back to a flagged estimate when no sample route matches', () {
      const phulchowki = GeoPoint(27.5717, 85.4031);
      final bus = estimator.busOption(thamel, phulchowki, midday)!;
      expect(bus.isEstimate, isTrue);
      expect(bus.routeName, isNull);
    });

    test('not available outside service hours', () {
      final bus = estimator.busOption(ratnaPark, bhaktapurSquare, ktm(2026, 10, 1, 22))!;
      expect(bus.available, isFalse);
      expect(bus.notes, contains(TransportNote.noBusService));
    });

    test('not available during a bandh', () {
      final bandh = ConditionAlert(
        id: 'b',
        type: AlertType.bandh,
        title: 'Bandh',
        start: ktm(2026, 10, 1),
        end: ktm(2026, 10, 2),
      );
      final options = estimator.optionsFor(ratnaPark, bhaktapurSquare, midday, alerts: [bandh]);
      expect(optionOf(options, TransportMode.bus).available, isFalse);
      expect(optionOf(options, TransportMode.taxi).notes, contains(TransportNote.bandh));
    });
  });

  group('options', () {
    test('very short hops offer walking only', () {
      final options = estimator.optionsFor(thamel, const GeoPoint(27.7160, 85.3130), midday);
      expect(options.map((o) => o.mode), [TransportMode.walk]);
      expect(options.single.fare.isFree, isTrue);
    });

    test('long trips do not offer walking', () {
      final options = estimator.optionsFor(thamel, const GeoPoint(27.6722, 85.4281), midday);
      expect(options.map((o) => o.mode), isNot(contains(TransportMode.walk)));
      expect(options.map((o) => o.mode),
          containsAll([TransportMode.taxi, TransportMode.bikeTaxi, TransportMode.bus]));
    });

    test('recommend follows the travel style', () {
      final options = estimator.optionsFor(ratnaPark, bhaktapurSquare, midday);
      expect(estimator.recommend(options, TravelStyle.budget)!.mode, TransportMode.bus);
      expect(estimator.recommend(options, TravelStyle.comfort)!.mode, TransportMode.taxi);
    });

    test('recommend walks short distances whatever the style', () {
      final options = estimator.optionsFor(thamel, const GeoPoint(27.7143, 85.3153), midday);
      for (final style in TravelStyle.values) {
        expect(estimator.recommend(options, style)!.mode, TransportMode.walk);
      }
    });

    test('recommend skips unavailable options', () {
      final options = estimator.optionsFor(ratnaPark, bhaktapurSquare, ktm(2026, 10, 1, 22));
      expect(estimator.recommend(options, TravelStyle.budget)!.mode, isNot(TransportMode.bus));
    });
  });
}
