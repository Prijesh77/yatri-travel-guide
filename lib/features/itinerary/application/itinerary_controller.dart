import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../domain/itinerary.dart';
import '../domain/itinerary_planner.dart';

final itineraryPlannerProvider = FutureProvider<ItineraryPlanner>((ref) async {
  return ItineraryPlanner(
    engine: ref.watch(recommendationEngineProvider),
    estimator: await ref.watch(fareEstimatorProvider.future),
  );
});

final itineraryControllerProvider =
    AsyncNotifierProvider<ItineraryController, Itinerary?>(ItineraryController.new);

enum AddResult { added, alreadyPresent }

/// Holds the user's day plan. Only the request and the ordered place ids are
/// persisted; times, legs and warnings are recomputed on load so they always
/// reflect the latest weather, alerts and data.
class ItineraryController extends AsyncNotifier<Itinerary?> {
  static const _storageKey = 'itinerary.v1';

  @override
  Future<Itinerary?> build() async {
    final weather = ref.watch(weatherOrNullProvider);
    final alerts = ref.watch(alertsProvider).value ?? const [];
    final placesFuture = ref.watch(placesProvider.future);
    final plannerFuture = ref.watch(itineraryPlannerProvider.future);

    final stored = _load();
    if (stored == null) return null;
    final (request, ids) = stored;
    final byId = {for (final p in await placesFuture) p.id: p};
    final ordered = [for (final id in ids) ?byId[id]];
    return (await plannerFuture).schedule(request, ordered, weather: weather, alerts: alerts);
  }

  Future<void> plan(ItineraryRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final planner = await ref.read(itineraryPlannerProvider.future);
      final places = await ref.read(placesProvider.future);
      final itinerary = planner.plan(
        request,
        places,
        weather: ref.read(weatherOrNullProvider),
        alerts: ref.read(alertsProvider).value ?? const [],
      );
      _save(request, itinerary.places);
      return itinerary;
    });
  }

  Future<void> removeAt(int index) async {
    final current = state.value;
    if (current == null) return;
    await _reschedule(current.request, [...current.places]..removeAt(index));
  }

  Future<void> insertAt(int index, Place place) async {
    final current = state.value;
    if (current == null) return;
    final places = [...current.places]..insert(index.clamp(0, current.places.length), place);
    await _reschedule(current.request, places);
  }

  /// Moves the stop at [from] so it ends up at index [to].
  Future<void> move(int from, int to) async {
    final current = state.value;
    if (current == null) return;
    final places = [...current.places];
    places.insert(to, places.removeAt(from));
    await _reschedule(current.request, places);
  }

  Future<void> optimize() async {
    final current = state.value;
    if (current == null) return;
    final planner = await ref.read(itineraryPlannerProvider.future);
    await _reschedule(current.request, planner.optimizeOrder(current.request.start.location, current.places));
  }

  /// Appends [place]; starts a plan for the rest of today if there is none.
  Future<AddResult> add(Place place) async {
    final current = state.value;
    if (current != null && current.places.contains(place)) return AddResult.alreadyPresent;
    final request = current?.request ?? _defaultRequest();
    await _reschedule(request, [...?current?.places, place]);
    return AddResult.added;
  }

  Future<void> clear() async {
    await ref.read(keyValueStoreProvider).remove(_storageKey);
    state = const AsyncData(null);
  }

  Future<void> _reschedule(ItineraryRequest request, List<Place> places) async {
    final planner = await ref.read(itineraryPlannerProvider.future);
    _save(request, places);
    state = AsyncData(planner.schedule(
      request,
      places,
      weather: ref.read(weatherOrNullProvider),
      alerts: ref.read(alertsProvider).value ?? const [],
    ));
  }

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

  (ItineraryRequest, List<String>)? _load() {
    final raw = ref.read(keyValueStoreProvider).getString(_storageKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        ItineraryRequest.fromJson(json['request'] as Map<String, dynamic>),
        [for (final id in json['placeIds'] as List) id as String],
      );
    } catch (_) {
      return null;
    }
  }

  void _save(ItineraryRequest request, List<Place> places) {
    ref.read(keyValueStoreProvider).setString(
          _storageKey,
          jsonEncode({'request': request.toJson(), 'placeIds': [for (final p in places) p.id]}),
        );
  }
}
