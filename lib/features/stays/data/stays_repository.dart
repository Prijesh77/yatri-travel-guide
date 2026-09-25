import '../../../core/data/json_source.dart';
import '../domain/stay.dart';

/// Stays (hotels, guesthouses). Bundled JSON in v1; swap for a booking API.
abstract interface class StaysRepository {
  Future<StayCatalog> getCatalog();
}

class JsonStaysRepository implements StaysRepository {
  JsonStaysRepository(this._loader);
  final OfflineFirstJsonLoader _loader;
  StayCatalog? _cache;

  @override
  Future<StayCatalog> getCatalog() async {
    if (_cache case final cached?) return cached;
    return _cache = StayCatalog.fromJson((await _loader.load()).json);
  }
}
