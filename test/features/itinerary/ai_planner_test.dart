import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yatri/core/data/key_value_store.dart';
import 'package:yatri/core/providers/core_providers.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/alerts/application/alerts_providers.dart';
import 'package:yatri/features/alerts/data/alerts_repository.dart';
import 'package:yatri/features/alerts/domain/condition_alert.dart';
import 'package:yatri/features/itinerary/application/itinerary_controller.dart';
import 'package:yatri/features/itinerary/data/ai_itinerary_service.dart';
import 'package:yatri/features/itinerary/data/gemini_client.dart';
import 'package:yatri/features/itinerary/domain/ai_plan.dart';
import 'package:yatri/features/itinerary/domain/itinerary.dart';
import 'package:yatri/features/itinerary/domain/itinerary_planner.dart';
import 'package:yatri/features/places/application/places_providers.dart';
import 'package:yatri/features/places/data/places_repository.dart';
import 'package:yatri/features/places/domain/place.dart';
import 'package:yatri/features/places/domain/place_category.dart';
import 'package:yatri/features/recommendations/domain/recommendation_engine.dart';
import 'package:yatri/features/transport/application/transport_providers.dart';
import 'package:yatri/features/transport/data/routes_repository.dart';
import 'package:yatri/features/transport/domain/fare_estimator.dart';
import 'package:yatri/features/weather/application/weather_providers.dart';
import 'package:yatri/features/weather/data/weather_repository.dart';
import 'package:yatri/features/weather/domain/weather.dart';

import '../../helpers/fixtures.dart';

String geminiResponse(Map<String, dynamic> plan) => jsonEncode({
      'candidates': [
        {
          'content': {
            'role': 'model',
            'parts': [
              {'text': jsonEncode(plan)},
            ],
          },
        },
      ],
    });

void main() {
  final places = loadBundledPlaces();
  final planner = ItineraryPlanner(engine: const RecommendationEngine(), estimator: FareEstimator(loadBundledNetwork()));
  final request = ItineraryRequest(
    startTime: ktm(2026, 10, 1, 9),
    availableMinutes: 8 * 60,
    start: const StartPoint('thamel', thamel),
    interests: {PlaceCategory.heritage},
  );

  group('GeminiClient', () {
    test('sends a structured-output request and returns the text', () async {
      late http.Request sent;
      final client = GeminiClient(
        apiKey: 'test-key',
        model: 'gemini-3.1-flash-lite',
        client: MockClient((req) async {
          sent = req;
          return http.Response(geminiResponse({'summary': 's', 'stops': []}), 200);
        }),
      );
      final text = await client.generateJson(system: 'sys', prompt: 'hello', schema: {'type': 'OBJECT'});
      expect(jsonDecode(text), {'summary': 's', 'stops': []});
      expect(sent.url.toString(),
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent');
      expect(sent.headers['x-goog-api-key'], 'test-key');
      expect(sent.url.queryParameters, isEmpty, reason: 'key must not be in the URL');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['systemInstruction']['parts'][0]['text'], 'sys');
      expect(body['contents'][0]['parts'][0]['text'], 'hello');
      expect(body['generationConfig']['responseMimeType'], 'application/json');
      expect(body['generationConfig']['responseSchema'], {'type': 'OBJECT'});
    });

    test('surfaces API errors (e.g. quota)', () async {
      final client = GeminiClient(
        apiKey: 'k',
        model: 'm',
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'error': {'code': 429, 'message': 'Resource has been exhausted'},
            }),
            429)),
      );
      expect(
        client.generateJson(system: '', prompt: '', schema: const {}),
        throwsA(isA<GeminiException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having((e) => e.message, 'message', contains('exhausted'))),
      );
    });

    test('blocked prompts and empty answers are errors', () async {
      GeminiClient withBody(Map<String, dynamic> body) =>
          GeminiClient(apiKey: 'k', model: 'm', client: MockClient((_) async => http.Response(jsonEncode(body), 200)));
      expect(withBody({'promptFeedback': {'blockReason': 'SAFETY'}}).generateJson(system: '', prompt: '', schema: const {}),
          throwsA(isA<GeminiException>()));
      expect(withBody({'candidates': []}).generateJson(system: '', prompt: '', schema: const {}),
          throwsA(isA<GeminiException>()));
    });
  });

  group('AiPlanParser', () {
    final known = {'a', 'b', 'c'};

    test('keeps known ids in order, drops unknown and repeated ones', () {
      final s = AiPlanParser.parse(
        jsonEncode({
          'summary': ' Nice day ',
          'stops': [
            {'placeId': 'b', 'note': 'first'},
            {'placeId': 'zzz', 'note': 'invented'},
            {'placeId': 'b', 'note': 'again'},
            {'placeId': 'a', 'note': 'second'},
          ],
        }),
        known,
      );
      expect(s.summary, 'Nice day');
      expect(s.stops.map((x) => x.placeId), ['b', 'a']);
      expect(s.stops.first.note, 'first');
    });

    test('accepts a fenced JSON block and caps the number of stops', () {
      final text = '```json\n${jsonEncode({
        'summary': '',
        'stops': [for (final id in known) {'placeId': id, 'note': ''}],
      })}\n```';
      expect(AiPlanParser.parse(text, known, maxStops: 2).stops, hasLength(2));
    });

    test('rejects garbage or empty plans', () {
      expect(() => AiPlanParser.parse('not json', known), throwsFormatException);
      expect(() => AiPlanParser.parse('[]', known), throwsFormatException);
      expect(() => AiPlanParser.parse(jsonEncode({'stops': [{'placeId': 'zzz'}]}), known), throwsFormatException);
    });
  });

  group('AiPlanPrompt', () {
    test('includes conditions, alerts and only candidate ids in the schema', () {
      final engine = const RecommendationEngine();
      final candidates = engine.rank(places.take(5), RecommendationContextFixture.at(request.startTime)).toList();
      final prompt = AiPlanPrompt.prompt(
        request: request,
        visitor: VisitorType.saarc,
        candidates: candidates,
        forecast: DailyForecast(date: ktm(2026, 10, 1), condition: WeatherCondition.rain, maxC: 24, minC: 16, precipitationProbability: 80),
        alerts: [
          ConditionAlert(
            id: 'x',
            type: AlertType.roadClosure,
            title: 'Naxal closed',
            start: ktm(2026, 10, 1, 8),
            end: ktm(2026, 10, 1, 12),
            locationLabel: 'Naxal',
          ),
        ],
      );
      final data = jsonDecode(prompt.substring(prompt.indexOf('{'))) as Map<String, dynamic>;
      expect(data['weekday'], 'Thursday');
      expect(data['weather']['condition'], 'rain');
      expect(data['weather']['rainChancePercent'], 80);
      expect(data['alerts'][0]['where'], 'Naxal');
      expect(data['visitor'], 'saarc');
      expect((data['candidates'] as List).map((c) => c['id']), candidates.map((c) => c.place.id));
      final schema = AiPlanPrompt.schema(['x', 'y']);
      expect(schema['properties']['stops']['items']['properties']['placeId']['enum'], ['x', 'y']);
      expect(AiPlanPrompt.systemFor(request), contains('and ${request.maxStops} stops'));
    });
  });

  group('GeminiItineraryService', () {
    GeminiItineraryService serviceReturning(Map<String, dynamic> plan, {void Function(Map<String, dynamic>)? onBody}) =>
        GeminiItineraryService(
          client: GeminiClient(
            apiKey: 'k',
            model: 'm',
            client: MockClient((req) async {
              onBody?.call(jsonDecode(req.body) as Map<String, dynamic>);
              return http.Response(geminiResponse(plan), 200);
            }),
          ),
          planner: planner,
          engine: const RecommendationEngine(),
        );

    test('schedules the chosen places with notes and summary', () async {
      final it = await serviceReturning({
        'summary': 'Heritage morning, museum when it rains',
        'stops': [
          {'placeId': 'kathmandu-durbar-square', 'note': 'Go early before the crowds'},
          {'placeId': 'patan-museum', 'note': 'Bronzes'},
        ],
      }).plan(request: request, places: places, visitor: VisitorType.foreigner);
      expect(it.source, PlanSource.ai);
      expect(it.summary, 'Heritage morning, museum when it rains');
      expect(it.places.map((p) => p.id), ['kathmandu-durbar-square', 'patan-museum']);
      expect(it.stops.first.note, 'Go early before the crowds');
      expect(it.stops.first.leg.options, isNotEmpty, reason: 'timed on device');
    });

    test('drops stops that would be closed', () async {
      // National Museum is closed on Tuesdays.
      final tuesdayRequest = ItineraryRequest(
        startTime: ktm(2026, 9, 29, 10),
        availableMinutes: 8 * 60,
        start: const StartPoint('thamel', thamel),
      );
      final service = serviceReturning({
        'summary': '',
        'stops': [
          {'placeId': 'national-museum', 'note': ''},
          {'placeId': 'swayambhunath', 'note': ''},
        ],
      });
      // National Museum is not even offered as a candidate on its closing day.
      final candidates = service.selectCandidates(tuesdayRequest, places, null, const []);
      expect(candidates.map((c) => c.place.id), isNot(contains('national-museum')));
      final it = await service.plan(request: tuesdayRequest, places: places, visitor: VisitorType.foreigner);
      expect(it.places.map((p) => p.id), ['swayambhunath']);
    });

    test('the request only offers open candidates, capped', () async {
      Map<String, dynamic>? body;
      await serviceReturning({
        'summary': '',
        'stops': [
          {'placeId': 'swayambhunath', 'note': ''},
        ],
      }, onBody: (b) => body = b).plan(request: request, places: places, visitor: VisitorType.foreigner);
      final ids = body!['generationConfig']['responseSchema']['properties']['stops']['items']['properties']['placeId']['enum'] as List;
      expect(ids.length, lessThanOrEqualTo(GeminiItineraryService.candidateCount));
      expect(ids, contains('swayambhunath'));
    });
  });

  group('ItineraryController', () {
    ProviderContainer container(AiItineraryService? ai) {
      OfflineFirstJsonLoaderFixture loader(String name) => OfflineFirstJsonLoaderFixture(name);
      final c = ProviderContainer(overrides: [
        keyValueStoreProvider.overrideWithValue(MemoryStore()),
        clockProvider.overrideWithValue(FixedClock(ktm(2026, 10, 1, 8))),
        placesRepositoryProvider.overrideWithValue(JsonPlacesRepository(loader('places.json').loader)),
        routesRepositoryProvider.overrideWithValue(JsonRoutesRepository(loader('routes.json').loader)),
        alertsRepositoryProvider.overrideWithValue(JsonAlertsRepository(loader('alerts.json').loader)),
        weatherRepositoryProvider.overrideWithValue(_NoWeather()),
        aiItineraryServiceProvider.overrideWith((ref) async => ai),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('uses the on-device planner when AI is off', () async {
      final c = container(null);
      await c.read(itineraryControllerProvider.future);
      await c.read(itineraryControllerProvider.notifier).plan(request);
      final it = c.read(itineraryControllerProvider).value!;
      expect(it.source, PlanSource.local);
      expect(it.stops, isNotEmpty);
    });

    test('falls back to the on-device planner when AI fails', () async {
      final c = container(_FailingAi());
      await c.read(itineraryControllerProvider.future);
      await c.read(itineraryControllerProvider.notifier).plan(request);
      final it = c.read(itineraryControllerProvider).value!;
      expect(it.source, PlanSource.localFallback);
      expect(it.stops, isNotEmpty);
    });

    test('keeps AI notes after an edit', () async {
      final ai = GeminiItineraryService(
        client: GeminiClient(
          apiKey: 'k',
          model: 'm',
          client: MockClient((_) async => http.Response(
              geminiResponse({
                'summary': 'S',
                'stops': [
                  {'placeId': 'kathmandu-durbar-square', 'note': 'N1'},
                  {'placeId': 'patan-durbar-square', 'note': 'N2'},
                  {'placeId': 'patan-museum', 'note': 'N3'},
                ],
              }),
              200)),
        ),
        planner: planner,
        engine: const RecommendationEngine(),
      );
      final c = container(ai);
      await c.read(itineraryControllerProvider.future);
      final ctrl = c.read(itineraryControllerProvider.notifier);
      await ctrl.plan(request);
      await ctrl.removeAt(0);
      final it = c.read(itineraryControllerProvider).value!;
      expect(it.source, PlanSource.ai);
      expect(it.summary, 'S');
      expect(it.stops.map((s) => s.note), ['N2', 'N3']);
    });
  });
}

class _FailingAi implements AiItineraryService {
  @override
  Future<Itinerary> plan({
    required ItineraryRequest request,
    required List<Place> places,
    required VisitorType visitor,
    WeatherReport? weather,
    List<ConditionAlert> alerts = const [],
  }) async =>
      throw GeminiException('offline');
}

class _NoWeather implements WeatherRepository {
  @override
  Future<WeatherReport> getWeather() async => throw Exception('offline');
}
