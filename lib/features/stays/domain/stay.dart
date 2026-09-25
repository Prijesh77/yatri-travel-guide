import '../../../core/geo/geo_point.dart';
import '../../places/domain/place_category.dart';

enum StayType { heritage, boutique, hotel, resort, guesthouse, hostel }

/// Price level with an approximate nightly range (NPR) from `stays.json`.
enum PriceBand { budget, mid, upscale, luxury }

class Stay {
  const Stay({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.area,
    required this.location,
    required this.priceBand,
    required this.description,
  });

  final String id;
  final String name;
  final StayType type;
  final City city;
  final String area;
  final GeoPoint location;
  final PriceBand priceBand;
  final String description;

  factory Stay.fromJson(Map<String, dynamic> json) => Stay(
        id: json['id'] as String,
        name: json['name'] as String,
        type: StayType.values.byName(json['type'] as String),
        city: City.parse(json['city'] as String),
        area: json['area'] as String,
        location: GeoPoint.fromJson(json),
        priceBand: PriceBand.values.byName(json['priceBand'] as String),
        description: json['description'] as String,
      );
}

class StayCatalog {
  const StayCatalog({required this.stays, required this.priceRanges});
  final List<Stay> stays;

  /// band -> (min, max) NPR per night.
  final Map<PriceBand, (int, int)> priceRanges;

  factory StayCatalog.fromJson(Map<String, dynamic> json) {
    final bands = json['priceBands'] as Map<String, dynamic>;
    return StayCatalog(
      stays: [for (final s in json['stays'] as List) Stay.fromJson(s as Map<String, dynamic>)],
      priceRanges: {
        for (final e in bands.entries)
          PriceBand.values.byName(e.key): ((e.value as List)[0] as int, (e.value as List)[1] as int),
      },
    );
  }
}
