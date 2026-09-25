import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/time/kathmandu_time.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../location/application/location_providers.dart';
import '../../location/domain/start_presets.dart';
import '../../places/application/places_providers.dart';
import '../../places/domain/place.dart';
import '../../profile/application/preferences_controller.dart';
import '../../recommendations/application/recommendation_providers.dart';
import '../../transport/application/transport_providers.dart';
import '../../weather/application/weather_providers.dart';
import '../data/ai_itinerary_service.dart';
import '../data/gemini_client.dart';
import '../domain/itinerary.dart';
import '../domain/itinerary_planner.dart';

final itineraryPlannerProvider = FutureProvider<ItineraryPlanner>((ref) async {
  return ItineraryPlanner(
    engine: ref.watch(recommendationEngineProvider),
    estimator: await ref.watch(fareEstimatorProvider.future),
  );
});

final aiConfigProvider = Provider<AiConfig>((ref) => AiConfig.fromEnvironment);

/// Null when no API key is configured (AI planning off).
final aiItineraryServiceProvider = FutureProvider<AiItineraryService?>((ref) async {
  final config = ref.watch(aiConfigProvider);
  if (!config.isEnabled) return null;
  return GeminiItineraryService(
    client: GeminiClient(apiKey: config.apiKey, model: config.model),
    planner: await ref.watch(itineraryPlannerProvider.future),
    engine: ref.watch(recommendationEngineProvider),
  );
});

final itineraryControllerProvider =
    AsyncNotifierProvider<ItineraryController, Itinerary?>(ItineraryController.new);

enum AddResult { added, alreadyPresent }

/// Holds the user's day plan. The request, ordered place ids and AI notes are
/// persisted; times, legs and warnings are recomputed on load so they always
/// reflect the latest weather, alerts and data.
class ItineraryController extends AsyncNotifier<Itinerary?> {
  static const _storageKey = 'itinerary.v2';

  @override
  Future<Itinerary?> build() async {
    final weather = ref.watch(weatherOrNullProvider);
    final alerts = ref.watch(alertsProvider);
    final placesFuture = ref.watch(placesProvider.future);
    final plannerFuture = ref.watch(itineraryPlannerProvider.future);

    final stored = _load();
    if (stored == null) return null;
    final byId = {for (final p in await placesFuture) p.id: p};
    final ordered = [for (final id in stored.placeIds) ?byId[id]];
    return (await plannerFuture).schedule(
      stored.request,
      ordered,
      weather: weather,
      alerts: alerts,
      notes: stored.notes,
      source: stored.source,
      summary: stored.summary,
    );
  }

  /// Plans a day: with the AI planner when configured, otherwise (or if it
  /// fails) with the on-device planner.
  Future<void> plan(ItineraryRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final planner = await ref.read(itineraryPlannerProvider.future);
      final places = await ref.read(placesProvider.future);
      final weather = ref.read(weatherOrNullProvider);
      final alerts = ref.read(alertsProvider);

      final ai = await ref.read(aiItineraryServiceProvider.future);
      Itinerary? itinerary;
      if (ai != null) {
        try {
          itinerary = await ai.plan(
            request: request,
            places: places,
            visitor: ref.read(preferencesProvider).visitorType,
            weather: weather,
            alerts: alerts,
          );
        } on Exception catch (_) {
          itinerary = null;
        } on StateError catch (_) {
          itinerary = null;
        }
      }
      itinerary ??= _withSource(
        planner.plan(request, places, weather: weather, alerts: alerts),
        ai == null ? PlanSource.local : PlanSource.localFallback,
      );
      _save(itinerary);
      return itinerary;
    });
  }

  Future<void> removeAt(int index) async {
    final current = state.value;
    if (current == null) return;
    await _reschedule(current, [...current.places]..removeAt(index));
  }

  Future<void> insertAt(int index, Place place) async {
    final current = state.value;
    if (current == null) return;
    final places = [...current.places]..insert(index.clamp(0, current.places.length), place);
    await _reschedule(current, places);
  }

  /// Moves the stop at [from] so it ends up at index [to].
  Future<void> move(int from, int to) async {
    final current = state.value;
    if (current == null) return;
    final places = [...current.places];
    places.insert(to, places.removeAt(from));
    await _reschedule(current, places);
  }

  Future<void> optimize() async {
    final current = state.value;
    if (current == null) return;
    final planner = await ref.read(itineraryPlannerProvider.future);
    await _reschedule(current, planner.optimizeOrder(current.request.start.location, current.places));
  }

  /// Appends [place]; starts a plan for the rest of today if there is none.
  Future<AddResult> add(Place place) async {
    final current = state.value;
    if (current != null && current.places.contains(place)) return AddResult.alreadyPresent;
    final base = current ?? Itinerary(request: _defaultRequest(), stops: const []);
    await _reschedule(base, [...base.places, place]);
    return AddResult.added;
  }

  Future<void> clear() async {
    await ref.read(keyValueStoreProvider).remove(_storageKey);
    state = const AsyncData(null);
  }

  Future<void> _reschedule(Itinerary base, List<Place> places) async {
    final planner = await ref.read(itineraryPlannerProvider.future);
    final itinerary = planner.schedule(
      base.request,
      places,
      weather: ref.read(weatherOrNullProvider),
      alerts: ref.read(alertsProvider),
      notes: {for (final s in base.stops) if (s.note != null) s.place.id: s.note!},
      source: base.source,
      summary: base.summary,
    );
    _save(itinerary);
    state = AsyncData(itinerary);
  }

  static Itinerary _withSource(Itinerary it, PlanSource source) =>
      Itinerary(request: it.request, stops: it.stops, source: source, summary: it.summary);

  ItineraryRequest _defaultRequest() {
    final now = ref.read(nowProvider);
    final start = now.add(Duration(minutes: 15 - now.minute % 15));
    final endOfDay = atMinuteOfDay(now, 20 * 60);
    final minutes = endOfDay.difference(start).inMinutes;
    final prefs = ref.read(preferencesProvider);
    final here = ref.read(userLocationProvider);
    return ItineraryRequest(
      startTime: start,
      availableMinutes: minutes < 120 ? 240 : minutes,
      start: here != null ? StartPoint('', here) : StartPoint(StartPreset.thamel.name, StartPreset.thamel.location),
      interests: prefs.interests,
      travelStyle: prefs.travelStyle,
    );
  }

  _Stored? _load() {
    final raw = ref.read(keyValueStoreProvider).getString(_storageKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _Stored(
        request: ItineraryRequest.fromJson(json['request'] as Map<String, dynamic>),
        placeIds: [for (final id in json['placeIds'] as List) id as String],
        notes: {
          for (final e in ((json['notes'] as Map<String, dynamic>?) ?? const {}).entries) e.key: e.value as String,
        },
        source: PlanSource.values.asNameMap()[json['source']] ?? PlanSource.local,
        summary: json['summary'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  void _save(Itinerary it) {
    ref.read(keyValueStoreProvider).setString(
          _storageKey,
          jsonEncode({
            'request': it.request.toJson(),
            'placeIds': [for (final p in it.places) p.id],
            'notes': {for (final s in it.stops) if (s.note != null) s.place.id: s.note},
            'source': it.source.name,
            'summary': ?it.summary,
          }),
        );
  }
}

class _Stored {
  const _Stored({
    required this.request,
    required this.placeIds,
    required this.notes,
    required this.source,
    this.summary,
  });

  final ItineraryRequest request;
  final List<String> placeIds;
  final Map<String, String> notes;
  final PlanSource source;
  final String? summary;
}
