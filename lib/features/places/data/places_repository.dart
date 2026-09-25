import '../../../core/data/json_source.dart';
import '../domain/place.dart';

/// Source of attractions. v1 reads bundled JSON; a backend implementation can
/// replace [JsonPlacesRepository] without touching the UI or domain.
abstract interface class PlacesRepository {
  Future<List<Place>> getPlaces();
}

class JsonPlacesRepository implements PlacesRepository {
  JsonPlacesRepository(this._loader);
  final OfflineFirstJsonLoader _loader;

  List<Place>? _cache;

  @override
  Future<List<Place>> getPlaces() async {
    if (_cache case final cached?) return cached;
    final loaded = await _loader.load();
    return _cache = parsePlaces(loaded.json);
  }

  static List<Place> parsePlaces(Map<String, dynamic> json) {
    final list = json['places'] as List;
    final places = <Place>[];
    final ids = <String>{};
    for (final raw in list) {
      final place = Place.fromJson(raw as Map<String, dynamic>);
      if (!ids.add(place.id)) {
        throw FormatException('Duplicate place id "${place.id}"');
      }
      places.add(place);
    }
    return List.unmodifiable(places);
  }
}
