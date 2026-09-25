import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/json_source.dart';
import '../../../core/providers/core_providers.dart';
import '../data/places_repository.dart';
import '../domain/place.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return JsonPlacesRepository(OfflineFirstJsonLoader(
    cacheKey: 'cache.places',
    bundled: AssetJsonSource('assets/data/places.json'),
    store: ref.watch(keyValueStoreProvider),
    // remote: HttpJsonSource(Uri.parse('https://api.example.com/places')),
  ));
});

final placesProvider = FutureProvider<List<Place>>((ref) {
  return ref.watch(placesRepositoryProvider).getPlaces();
});

final placeByIdProvider = Provider.family<Place?, String>((ref, id) {
  final places = ref.watch(placesProvider).value ?? const [];
  for (final p in places) {
    if (p.id == id) return p;
  }
  return null;
});
