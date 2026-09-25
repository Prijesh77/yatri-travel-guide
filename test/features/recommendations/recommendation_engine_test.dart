import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/geo/geo_point.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/alerts/domain/condition_alert.dart';
import 'package:yatri/features/places/domain/place_category.dart';
import 'package:yatri/features/recommendations/domain/recommendation_context.dart';
import 'package:yatri/features/recommendations/domain/recommendation_engine.dart';
import 'package:yatri/features/recommendations/domain/scored_place.dart';
import 'package:yatri/features/weather/domain/weather.dart';

import '../../helpers/fixtures.dart';

void main() {
  const engine = RecommendationEngine();
  final afternoon = ktm(2026, 10, 1, 14); // Thursday 14:00

  RecommendationContext ctx({
    DateTime? time,
    WeatherSnapshot? weather,
    GeoPoint? here,
    Set<PlaceCategory> interests = const {},
    List<ConditionAlert> alerts = const [],
  }) =>
      RecommendationContext(
        time: time ?? afternoon,
        weather: weather,
        userLocation: here,
        interests: interests,
        alerts: alerts,
      );

  List<ReasonKind> kinds(ScoredPlace s) => [for (final r in s.reasons) r.kind];

  group('weather', () {
    final museum = testPlace(id: 'museum', setting: Setting.indoor);
    final square = testPlace(id: 'square', setting: Setting.outdoor);

    test('rain favours indoor places over outdoor ones', () {
      final ranked = engine.rank([square, museum], ctx(weather: rainy(afternoon)));
      expect(ranked.first.place, museum);
      expect(ranked.first.highlights.first.kind, ReasonKind.indoorInRain);
      expect(ranked.first.highlights.first.dayPart, DayPart.afternoon);
      expect(kinds(ranked.last), contains(ReasonKind.outdoorInRain));
    });

    test('clear weather favours outdoor places', () {
      final ranked = engine.rank([museum, square], ctx(weather: sunny(afternoon)));
      expect(ranked.first.place, square);
      expect(kinds(ranked.first), contains(ReasonKind.pleasantOutdoors));
    });

    test('viewpoints are penalised when clouds hide the views', () {
      final view = testPlace(id: 'view', category: PlaceCategory.viewpoint);
      final cloudy = WeatherSnapshot(time: afternoon, temperatureC: 20, condition: WeatherCondition.cloudy);
      final clear = engine.score(view, ctx(weather: sunny(afternoon)));
      final overcast = engine.score(view, ctx(weather: cloudy));
      expect(kinds(overcast), contains(ReasonKind.noViews));
      expect(kinds(clear), contains(ReasonKind.clearViews));
      expect(clear.score, greaterThan(overcast.score));
    });

    test('unhealthy air pushes people indoors', () {
      final smog = sunny(afternoon, aqi: 180);
      final ranked = engine.rank([square, museum], ctx(weather: smog));
      expect(ranked.first.place, museum);
      expect(kinds(ranked.first), contains(ReasonKind.indoorPoorAir));
      expect(ranked.last.reasons.firstWhere((r) => r.kind == ReasonKind.poorAirOutdoor).aqi, 180);
    });

    test('no weather data means no weather reasons', () {
      final s = engine.score(square, ctx());
      expect(s.reasons.where((r) => r.kind.name.contains('Rain')), isEmpty);
    });
  });

  group('time of day and opening hours', () {
    test('places closed on their weekly closing day are unavailable', () {
      final museum = testPlace(id: 'm', hours: hours('10:00', '17:00', closed: {DateTime.tuesday}));
      final s = engine.score(museum, ctx(time: tuesday.add(const Duration(hours: 12))));
      expect(s.isAvailable, isFalse);
      expect(s.suitability, Suitability.unavailable);
      expect(kinds(s), contains(ReasonKind.closedToday));
    });

    test('closed places rank below open ones', () {
      final open = testPlace(id: 'open', popularity: 1);
      final closed = testPlace(id: 'closed', popularity: 5, hours: hours('06:00', '10:00'));
      final ranked = engine.rank([closed, open], ctx());
      expect(ranked.first.place, open);
      expect(ranked.last.isAvailable, isFalse);
    });

    test('closing before the visit ends is flagged', () {
      final p = testPlace(visitMinutes: 90, hours: hours('09:00', '14:40'));
      final s = engine.score(p, ctx());
      final r = s.reasons.firstWhere((r) => r.kind == ReasonKind.closesSoon);
      expect(r.minutes, 40);
      expect(s.isAvailable, isTrue);
    });

    test('opening soon is a small penalty, opening much later a big one', () {
      final soon = engine.score(testPlace(hours: hours('14:30', '18:00')), ctx());
      final later = engine.score(testPlace(hours: hours('17:00', '20:00')), ctx());
      expect(soon.score, greaterThan(later.score));
      expect(soon.reasons.firstWhere((r) => r.kind == ReasonKind.opensLater).minutes, parseHhMm('14:30'));
    });

    test('best time of day adds a reason', () {
      final nagarkot = testPlace(category: PlaceCategory.viewpoint, bestTimes: ['earlyMorning', 'evening']);
      final dawn = engine.score(nagarkot, ctx(time: ktm(2026, 10, 1, 5, 30)));
      final noon = engine.score(nagarkot, ctx(time: ktm(2026, 10, 1, 12)));
      expect(kinds(dawn), contains(ReasonKind.bestTimeNow));
      expect(kinds(noon), isNot(contains(ReasonKind.bestTimeNow)));
    });

    test('food relies on meal times, not best times', () {
      final cafe = testPlace(category: PlaceCategory.food, setting: Setting.indoor, bestTimes: ['afternoon']);
      final s = engine.score(cafe, ctx(time: ktm(2026, 10, 1, 12, 30)));
      expect(kinds(s), contains(ReasonKind.mealTime));
      expect(kinds(s), isNot(contains(ReasonKind.bestTimeNow)));
    });

    test('food scores higher at meal times', () {
      final cafe = testPlace(category: PlaceCategory.food, setting: Setting.indoor);
      final lunch = engine.score(cafe, ctx(time: ktm(2026, 10, 1, 12, 30)));
      final midAfternoon = engine.score(cafe, ctx(time: ktm(2026, 10, 1, 15, 30)));
      expect(lunch.score, greaterThan(midAfternoon.score));
      expect(kinds(lunch), contains(ReasonKind.mealTime));
    });

    test('outdoor nature is discouraged after dark', () {
      final park = testPlace(category: PlaceCategory.nature);
      final s = engine.score(park, ctx(time: ktm(2026, 10, 1, 21)));
      expect(kinds(s), contains(ReasonKind.afterDark));
    });
  });

  group('distance and interests', () {
    final near = testPlace(id: 'near', location: const GeoPoint(27.7160, 85.3130));
    final far = testPlace(id: 'far', location: const GeoPoint(27.7156, 85.5203)); // Nagarkot

    test('nearby places rank above distant ones', () {
      final ranked = engine.rank([far, near], ctx(here: thamel));
      expect(ranked.first.place, near);
      expect(kinds(ranked.first), contains(ReasonKind.nearby));
      expect(kinds(ranked.last), contains(ReasonKind.far));
      expect(ranked.last.distanceKm, greaterThan(15));
    });

    test('distance is ignored without a user location', () {
      final s = engine.score(far, ctx());
      expect(s.distanceKm, isNull);
      expect(kinds(s), isNot(contains(ReasonKind.far)));
    });

    test('primary interest counts more than a secondary one', () {
      final temple = testPlace(id: 'temple', category: PlaceCategory.temple);
      final square = testPlace(id: 'square', category: PlaceCategory.heritage, secondary: [PlaceCategory.temple]);
      final other = testPlace(id: 'zoo', category: PlaceCategory.nature);
      final ranked = engine.rank([other, square, temple], ctx(interests: {PlaceCategory.temple}));
      expect(ranked.map((s) => s.place.id), ['temple', 'square', 'zoo']);
      expect(ranked[1].reasons.firstWhere((r) => r.kind == ReasonKind.matchesInterest).category,
          PlaceCategory.temple);
    });
  });

  group('alerts', () {
    ConditionAlert alert(AlertType type, {Set<String> placeIds = const {}, Set<City> cities = const {}}) =>
        ConditionAlert(
          id: type.name,
          type: type,
          title: type.name,
          start: ktm(2026, 10, 1),
          end: ktm(2026, 10, 2),
          placeIds: placeIds,
          cities: cities,
        );

    test('a closure alert blocks only the listed place', () {
      final closed = testPlace(id: 'closed');
      final other = testPlace(id: 'other');
      final a = alert(AlertType.closure, placeIds: {'closed'});
      expect(engine.score(closed, ctx(alerts: [a])).isAvailable, isFalse);
      expect(engine.score(other, ctx(alerts: [a])).isAvailable, isTrue);
    });

    test('alerts outside their time window are ignored', () {
      final p = testPlace();
      final s = engine.score(p, ctx(time: ktm(2026, 10, 3, 12), alerts: [alert(AlertType.festival)]));
      expect(kinds(s), isNot(contains(ReasonKind.festival)));
    });

    test('festival in a city warns about crowds there only', () {
      final ktmPlace = testPlace(id: 'k');
      final bktPlace = testPlace(id: 'b', city: City.bhaktapur);
      final a = alert(AlertType.festival, cities: {City.bhaktapur});
      expect(kinds(engine.score(bktPlace, ctx(alerts: [a]))), contains(ReasonKind.festival));
      expect(kinds(engine.score(ktmPlace, ctx(alerts: [a]))), isNot(contains(ReasonKind.festival)));
    });

    test('during a bandh walkable places win', () {
      final near = testPlace(id: 'near', location: const GeoPoint(27.7160, 85.3130));
      final mid = testPlace(id: 'mid', location: patan, popularity: 5);
      final ranked = engine.rank([mid, near], ctx(here: thamel, alerts: [alert(AlertType.bandh)]));
      expect(ranked.first.place, near);
      expect(kinds(ranked.first), contains(ReasonKind.bandhWalkable));
      expect(kinds(ranked.last), contains(ReasonKind.bandhTransport));
    });
  });

  test('ranking of the bundled data on a rainy afternoon puts indoor places first', () {
    final places = loadBundledPlaces();
    final ranked = engine.rank(places, ctx(weather: rainy(afternoon), here: thamel));
    final top5 = ranked.take(5).map((s) => s.place.setting);
    expect(top5, everyElement(isNot(Setting.outdoor)));
  });

  test('diversify spreads categories without dropping places', () {
    final places = [
      for (var i = 0; i < 4; i++) testPlace(id: 'food$i', category: PlaceCategory.food, popularity: 5),
      testPlace(id: 'temple', category: PlaceCategory.temple, popularity: 4),
      testPlace(id: 'closed', hours: hours('01:00', '02:00'), popularity: 5),
    ];
    final ranked = engine.rank(places, ctx(time: ktm(2026, 10, 1, 15, 30))); // not a meal time
    final diverse = engine.diversify(ranked);
    expect(ranked.take(4).every((s) => s.place.category == PlaceCategory.food), isTrue);
    expect(diverse.take(3).map((s) => s.place.id), contains('temple'));
    expect(diverse.toSet(), ranked.toSet());
    expect(diverse.last.place.id, 'closed');
  });

  test('reasons are sorted by absolute impact', () {
    final s = engine.score(
      testPlace(setting: Setting.indoor, popularity: 5),
      ctx(weather: rainy(afternoon), interests: {PlaceCategory.heritage}),
    );
    final impacts = [for (final r in s.reasons) r.impact.abs()];
    expect(impacts, orderedEquals([...impacts]..sort((a, b) => b.compareTo(a))));
  });
}
