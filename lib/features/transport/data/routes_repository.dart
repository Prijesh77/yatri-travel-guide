import '../../../core/data/json_source.dart';
import '../domain/route_network.dart';

/// Transport fare models and routes. Replace with an API-backed
/// implementation once real route data is available.
abstract interface class RoutesRepository {
  Future<RouteNetwork> getNetwork();
}

class JsonRoutesRepository implements RoutesRepository {
  JsonRoutesRepository(this._loader);
  final OfflineFirstJsonLoader _loader;
  RouteNetwork? _cache;

  @override
  Future<RouteNetwork> getNetwork() async {
    if (_cache case final cached?) return cached;
    final loaded = await _loader.load();
    return _cache = RouteNetwork.fromJson(loaded.json);
  }
}
