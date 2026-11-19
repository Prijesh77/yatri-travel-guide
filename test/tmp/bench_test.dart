import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/itinerary/domain/itinerary.dart';
import 'package:yatri/features/itinerary/domain/itinerary_planner.dart';
import 'package:yatri/features/recommendations/domain/recommendation_engine.dart';
import 'package:yatri/features/recommendations/domain/recommendation_context.dart';
import 'package:yatri/features/transport/domain/fare_estimator.dart';
import 'package:yatri/features/transport/domain/transport_option.dart';
import '../helpers/fixtures.dart';

void main() {
  test('bench', () {
    final network = loadBundledNetwork();
    var sw = Stopwatch()..start();
    final estimator = FareEstimator(network);
    print('estimator build ${sw.elapsedMilliseconds} ms');
    final places = loadBundledPlaces();
    final t = ktm(2026, 11, 19, 10);
    sw = Stopwatch()..start();
    for (final p in places) {
      estimator.optionsFor(thamel, p.location, t);
    }
    print('optionsFor x${places.length}: ${sw.elapsedMilliseconds} ms');
    sw = Stopwatch()..start();
    for (final p in places) {
      estimator.journeys.plan(thamel, p.location, t, maxResults: 8);
    }
    print('journeys.plan x${places.length}: ${sw.elapsedMilliseconds} ms');
    final planner = ItineraryPlanner(engine: const RecommendationEngine(), estimator: estimator);
    sw = Stopwatch()..start();
    final it = planner.plan(
        ItineraryRequest(startTime: t, availableMinutes: 9 * 60, start: StartPoint('Thamel', thamel), travelStyle: TravelStyle.balanced),
        places, weather: reportOf(sunny, t));
    print('planner.plan: ${sw.elapsedMilliseconds} ms (${it.stops.length} stops)');
    sw = Stopwatch()..start();
    const engine = RecommendationEngine();
    for (var i = 0; i < 10; i++) {
      engine.rank(places, RecommendationContext(time: t, weather: reportOf(sunny, t).at(t)));
    }
    print('rank x10: ${sw.elapsedMilliseconds} ms');
  });
}
