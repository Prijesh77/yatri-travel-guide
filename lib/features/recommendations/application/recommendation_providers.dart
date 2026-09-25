import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../location/application/location_providers.dart';
import '../../places/application/places_providers.dart';
import '../../places/domain/place_category.dart';
import '../../profile/application/preferences_controller.dart';
import '../../weather/application/weather_providers.dart';
import '../domain/recommendation_context.dart';
import '../domain/recommendation_engine.dart';
import '../domain/scored_place.dart';

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) => const RecommendationEngine());

/// Conditions right now: time, weather, location, interests and alerts.
final currentContextProvider = Provider<RecommendationContext>((ref) {
  final now = ref.watch(nowProvider);
  return RecommendationContext(
    time: now,
    weather: ref.watch(weatherOrNullProvider)?.at(now),
    userLocation: ref.watch(userLocationProvider),
    interests: ref.watch(preferencesProvider.select((p) => p.interests)),
    alerts: ref.watch(alertsProvider).value ?? const [],
  );
});

/// All places ranked for current conditions.
final rankedPlacesProvider = FutureProvider<List<ScoredPlace>>((ref) async {
  final context = ref.watch(currentContextProvider);
  final engine = ref.watch(recommendationEngineProvider);
  final places = await ref.watch(placesProvider.future);
  return engine.rank(places, context);
});

final selectedCategoryProvider = NotifierProvider<SelectedCategory, PlaceCategory?>(SelectedCategory.new);

class SelectedCategory extends Notifier<PlaceCategory?> {
  @override
  PlaceCategory? build() => null;

  void select(PlaceCategory? category) => state = category;
}

/// Home-screen list: ranked, filtered by the selected category, closed places
/// last. The unfiltered list is diversified so one category does not crowd
/// out the rest.
final homeRecommendationsProvider = FutureProvider<List<ScoredPlace>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  final ranked = await ref.watch(rankedPlacesProvider.future);
  if (category == null) return ref.watch(recommendationEngineProvider).diversify(ranked);
  return [
    for (final s in ranked)
      if (s.place.hasCategory(category)) s,
  ];
});

final scoredPlaceProvider = Provider.family<ScoredPlace?, String>((ref, id) {
  final ranked = ref.watch(rankedPlacesProvider).value;
  if (ranked == null) return null;
  for (final s in ranked) {
    if (s.place.id == id) return s;
  }
  return null;
});
