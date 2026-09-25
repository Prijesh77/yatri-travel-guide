import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/json_source.dart';
import '../../../core/providers/core_providers.dart';
import '../data/routes_repository.dart';
import '../domain/fare_estimator.dart';
import '../domain/route_network.dart';

final routesRepositoryProvider = Provider<RoutesRepository>((ref) {
  return JsonRoutesRepository(OfflineFirstJsonLoader(
    cacheKey: 'cache.routes',
    bundled: AssetJsonSource('assets/data/routes.json'),
    store: ref.watch(keyValueStoreProvider),
  ));
});

final routeNetworkProvider = FutureProvider<RouteNetwork>((ref) {
  return ref.watch(routesRepositoryProvider).getNetwork();
});

final fareEstimatorProvider = FutureProvider<FareEstimator>((ref) async {
  return FareEstimator(await ref.watch(routeNetworkProvider.future));
});
