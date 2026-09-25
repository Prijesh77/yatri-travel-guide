import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/geo/geo_point.dart';
import 'package:yatri/features/alerts/domain/condition_alert.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/itinerary/domain/itinerary.dart';
import 'package:yatri/features/itinerary/domain/itinerary_planner.dart';
import 'package:yatri/features/places/domain/place.dart';
import 'package:yatri/features/places/domain/place_category.dart';
import 'package:yatri/features/recommendations/domain/recommendation_engine.dart';
import 'package:yatri/features/transport/domain/fare_estimator.dart';
import 'package:yatri/features/transport/domain/transport_option.dart';

import '../../helpers/fixtures.dart';

void main() {
  final planner = ItineraryPlanner(
    engine: const RecommendationEngine(),
    estimator: FareEstimator(loadBundledNetwork()),
  );
  final places = loadBundledPlaces();
  Place byId(String id) => places.firstWhere((p) => p.id == id);

  ItineraryRequest request({
    DateTime? start,
    int minutes = 8 * 60,
    GeoPoint from = thamel,
    Set<PlaceCategory> interests = const {},
    TravelStyle style = TravelStyle.balanced,
    int maxStops = 6,
  }) =>
      ItineraryRequest(
        startTime: start ?? ktm(2026, 10, 1, 9),
        availableMinutes: minutes,
        start: StartPoint('Start', from),
        interests: interests,
        travelStyle: style,
        maxStops: maxStops,
      );

  void expectConsistentTimes(Itinerary it) {
    var t = it.request.startTime;
    for (final s in it.stops) {
      expect(s.arrival, t.add(Duration(minutes: s.leg.minutes)), reason: s.place.id);
      expect(s.visitStart.isBefore(s.arrival), isFalse, reason: s.place.id);
      expect(s.departure, s.visitStart.add(Duration(minutes: s.place.visitMinutes)), reason: s.place.id);
      t = s.departure;
    }
  }

  group('plan', () {
    test('fits within the time available and max stops', () {
      final req = request(minutes: 5 * 60, maxStops: 4);
      final it = planner.plan(req, places);
      expect(it.stops, isNotEmpty);
      expect(it.stops.length, lessThanOrEqualTo(4));
      expect(it.endTime.isAfter(req.endTime), isFalse);
      expect(it.hasWarnings, isFalse);
      expectConsistentTimes(it);
    });

    test('every stop is open for the whole visit', () {
      final it = planner.plan(request(start: ktm(2026, 9, 29, 10)), places); // Tuesday
      for (final s in it.stops) {
        expect(s.place.openingHours.isOpenFor(s.visitStart, s.place.visitMinutes), isTrue, reason: s.place.id);
      }
      // National Museum and the Bhaktapur art gallery close on Tuesdays.
      expect(it.places.map((p) => p.id), isNot(contains('national-museum')));
    });

    test('does not repeat places', () {
      final it = planner.plan(request(minutes: 12 * 60, maxStops: 10), places);
      expect(it.places.toSet().length, it.places.length);
    });

    test('follows interests', () {
      final it = planner.plan(request(interests: {PlaceCategory.temple}), places);
      final temples = it.places.where((p) => p.hasCategory(PlaceCategory.temple));
      expect(temples.length, greaterThanOrEqualTo(it.stops.length ~/ 2));
    });

    test('rainy day plans mostly indoor stops', () {
      final day = ktm(2026, 10, 1);
      final it = planner.plan(request(), places, weather: reportOf(rainy, day));
      final outdoor = it.places.where((p) => p.setting == Setting.outdoor);
      expect(outdoor.length, lessThan(it.stops.length / 2));
    });

    test('plans at most one meal unless food is an interest', () {
      final day = ktm(2026, 10, 1);
      final rain = reportOf(rainy, day);
      int meals(Itinerary it) => it.places.where((p) => p.category == PlaceCategory.food).length;
      final plain = planner.plan(request(minutes: 11 * 60, maxStops: 8), places, weather: rain);
      final foodie = planner.plan(
        request(minutes: 11 * 60, maxStops: 8, interests: {PlaceCategory.food}),
        places,
        weather: rain,
      );
      expect(meals(plain), lessThanOrEqualTo(1));
      expect(meals(foodie), inInclusiveRange(1, 2));
      final foodStops = foodie.stops.where((s) => s.place.category == PlaceCategory.food).toList();
      if (foodStops.length == 2) {
        expect(foodStops[1].visitStart.difference(foodStops[0].visitStart).inMinutes,
            greaterThanOrEqualTo(planner.minMinutesBetweenMeals));
      }
    });

    test('starting in Bhaktapur keeps the first stops nearby', () {
      const bhaktapur = GeoPoint(27.6722, 85.4281);
      final it = planner.plan(request(from: bhaktapur, minutes: 4 * 60), places);
      expect(it.places.first.city, City.bhaktapur);
    });

    test('an empty day yields an empty plan', () {
      final it = planner.plan(request(start: ktm(2026, 10, 1, 23), minutes: 30), places);
      expect(it.isEmpty, isTrue);
      expect(it.endTime, it.request.startTime);
    });
  });

  group('schedule after edits', () {
    final req = request();
    final ordered = [byId('garden-of-dreams'), byId('patan-durbar-square'), byId('swayambhunath')];

    test('keeps the given order and chains times and legs', () {
      final it = planner.schedule(req, ordered);
      expect(it.places, ordered);
      expectConsistentTimes(it);
      expect(it.stops.first.leg.from, req.start.location);
      expect(it.stops[1].leg.from, ordered[0].location);
      expect(it.stops[1].leg.options, isNotEmpty);
    });

    test('removing a stop re-times the rest', () {
      final full = planner.schedule(req, ordered);
      final removed = planner.schedule(req, [ordered[0], ordered[2]]);
      expect(removed.stops.length, 2);
      expect(removed.stops[1].leg.from, ordered[0].location);
      expect(removed.endTime.isBefore(full.endTime), isTrue);
      expectConsistentTimes(removed);
    });

    test('reordering changes the timings', () {
      final reordered = planner.schedule(req, ordered.reversed.toList());
      expect(reordered.places.first.id, 'swayambhunath');
      expectConsistentTimes(reordered);
    });

    test('waits for a place that opens shortly', () {
      // Narayanhiti opens at 11:00; arrive around 10:40 from Thamel.
      final it = planner.schedule(request(start: ktm(2026, 10, 1, 10, 30)), [byId('narayanhiti-palace-museum')]);
      final stop = it.stops.single;
      expect(stop.visitStart, ktm(2026, 10, 1, 11));
      expect(stop.waitMinutes, greaterThan(0));
      expect(stop.warnings, isEmpty);
    });

    test('flags stops that are closed, closing or past the end time', () {
      final it = planner.schedule(
        request(start: ktm(2026, 9, 29, 15), minutes: 60), // Tuesday
        [byId('national-museum'), byId('patan-museum'), byId('nagarkot')],
      );
      expect(it.stops[0].warnings, contains(StopWarning.closedOnArrival));
      expect(it.stops.last.warnings, contains(StopWarning.pastEndTime));
    });

    test('totals add up', () {
      final it = planner.schedule(req, ordered);
      expect(it.totalTravelMinutes, it.stops.fold<int>(0, (s, x) => s + x.leg.minutes));
      expect(it.entryFees(VisitorType.foreigner), 400 + 1000 + 200);
      expect(it.entryFees(VisitorType.nepali), 200);
    });
  });

  group('optimizeOrder', () {
    test('shortens a zig-zag route', () {
      final zigzag = [
        byId('bhaktapur-durbar-square'),
        byId('garden-of-dreams'),
        byId('changu-narayan'),
        byId('kathmandu-durbar-square'),
        byId('nagarkot'),
      ];
      final optimized = planner.optimizeOrder(thamel, zigzag);
      expect(optimized.toSet(), zigzag.toSet());
      expect(ItineraryPlanner.pathKm(thamel, optimized), lessThan(ItineraryPlanner.pathKm(thamel, zigzag)));
      // Central Kathmandu stops come before the eastern ones.
      expect(optimized.take(2).map((p) => p.city), everyElement(City.kathmandu));
    });

    test('handles tiny inputs', () {
      expect(planner.optimizeOrder(thamel, []), isEmpty);
      final two = [byId('nagarkot'), byId('garden-of-dreams')];
      expect(planner.optimizeOrder(thamel, two).first.id, 'garden-of-dreams');
    });
  });

  group('advisories', () {
    final req = request(start: ktm(2026, 10, 1, 10), style: TravelStyle.comfort);
    // Garden of Dreams (Thamel) -> Patan Durbar Square passes Tripureshwor.
    final ordered = [byId('garden-of-dreams'), byId('patan-durbar-square')];

    test('a leg through a reported road closure is rerouted and slower', () {
      final closure = ConditionAlert(
        id: 'rc',
        type: AlertType.roadClosure,
        title: 'Tripureshwor closed',
        start: ktm(2026, 10, 1),
        end: ktm(2026, 10, 2),
        location: const GeoPoint(27.6945, 85.3140),
        radiusKm: 0.5,
      );
      final normal = planner.schedule(req, ordered);
      final rerouted = planner.schedule(req, ordered, alerts: [closure]);
      final leg = rerouted.stops[1].leg;
      expect(leg.isRerouted, isTrue);
      expect(leg.avoiding!.id, 'rc');
      expect(leg.chosen!.notes, contains(TransportNote.rerouted));
      expect(leg.minutes, normal.stops[1].leg.minutes + ItineraryPlanner.detourMinutes(AlertType.roadClosure));
      expect(rerouted.stops.first.leg.isRerouted, isFalse, reason: 'first leg is a short walk');
    });

    test('closures elsewhere or outside their time do not reroute', () {
      final elsewhere = ConditionAlert(
        id: 'x',
        type: AlertType.roadClosure,
        title: 'Far away',
        start: ktm(2026, 10, 1),
        end: ktm(2026, 10, 2),
        location: const GeoPoint(27.7156, 85.5203),
      );
      final yesterday = ConditionAlert(
        id: 'y',
        type: AlertType.roadClosure,
        title: 'Over',
        start: ktm(2026, 9, 30),
        end: ktm(2026, 9, 30, 23),
        location: const GeoPoint(27.6945, 85.3140),
      );
      final it = planner.schedule(req, ordered, alerts: [elsewhere, yesterday]);
      expect(it.stops.any((s) => s.leg.isRerouted), isFalse);
    });

    test('events near a stop during the visit are attached', () {
      final jatra = ConditionAlert(
        id: 'ev',
        type: AlertType.festival,
        title: 'Procession',
        start: ktm(2026, 10, 1, 9),
        end: ktm(2026, 10, 1, 18),
        location: const GeoPoint(27.6730, 85.3250),
        radiusKm: 0.5,
      );
      final it = planner.schedule(req, ordered, alerts: [jatra]);
      expect(it.stops[1].nearbyEvents.single.id, 'ev');
      expect(it.stops[0].nearbyEvents, isEmpty);
    });

    test('notes and source are carried through', () {
      final it = planner.schedule(req, ordered,
          notes: {'garden-of-dreams': 'Quiet morning walk'}, source: PlanSource.ai, summary: 'A calm day');
      expect(it.stops.first.note, 'Quiet morning walk');
      expect(it.stops[1].note, isNull);
      expect(it.source, PlanSource.ai);
      expect(it.summary, 'A calm day');
    });
  });

  test('request survives a JSON round trip', () {
    final req = request(interests: {PlaceCategory.food, PlaceCategory.temple}, style: TravelStyle.budget);
    final back = ItineraryRequest.fromJson(req.toJson());
    expect(back.startTime, req.startTime);
    expect(back.availableMinutes, req.availableMinutes);
    expect(back.start.location, req.start.location);
    expect(back.interests, req.interests);
    expect(back.travelStyle, TravelStyle.budget);
  });
}
