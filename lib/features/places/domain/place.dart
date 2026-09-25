import '../../../core/geo/geo_point.dart';
import 'opening_hours.dart';
import 'place_category.dart';

class EntryFee {
  const EntryFee({required this.foreigner, required this.saarc, required this.nepali});

  const EntryFee.free()
      : foreigner = 0,
        saarc = 0,
        nepali = 0;

  /// Prices in NPR.
  final int foreigner;
  final int saarc;
  final int nepali;

  int forVisitor(VisitorType type) => switch (type) {
        VisitorType.foreigner => foreigner,
        VisitorType.saarc => saarc,
        VisitorType.nepali => nepali,
      };

  bool get isFree => foreigner == 0 && saarc == 0 && nepali == 0;

  factory EntryFee.fromJson(Map<String, dynamic> json) => EntryFee(
        foreigner: (json['foreigner'] as num).toInt(),
        saarc: (json['saarc'] as num).toInt(),
        nepali: (json['nepali'] as num).toInt(),
      );
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.location,
    required this.visitMinutes,
    required this.entryFee,
    required this.openingHours,
    required this.setting,
    required this.description,
    this.secondaryCategories = const [],
    this.bestTimes = const [],
    this.popularity = 3,
    this.imageUrl,
    this.localizedNames = const {},
  });

  final String id;
  final String name;
  final City city;
  final PlaceCategory category;
  final List<PlaceCategory> secondaryCategories;
  final GeoPoint location;

  /// Typical time spent at the place.
  final int visitMinutes;
  final EntryFee entryFee;
  final OpeningHours openingHours;
  final Setting setting;

  /// Names of [DayPart]s when the place is at its best.
  final List<String> bestTimes;

  /// 1 (hidden gem) to 5 (must-see).
  final int popularity;
  final String description;
  final String? imageUrl;

  /// Language code -> name, e.g. `{'ne': 'स्वयम्भूनाथ'}`.
  final Map<String, String> localizedNames;

  Iterable<PlaceCategory> get allCategories => [category, ...secondaryCategories];

  bool get isIndoor => setting == Setting.indoor;
  bool get isOutdoor => setting == Setting.outdoor;

  bool hasCategory(PlaceCategory c) => category == c || secondaryCategories.contains(c);

  String displayName(String languageCode) => localizedNames[languageCode] ?? name;

  factory Place.fromJson(Map<String, dynamic> json) {
    final i18n = (json['i18n'] as Map<String, dynamic>?) ?? const {};
    final popularity = (json['popularity'] as num?)?.toInt() ?? 3;
    if (popularity < 1 || popularity > 5) {
      throw FormatException('popularity must be 1-5 for ${json['id']}');
    }
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      city: City.parse(json['city'] as String),
      category: PlaceCategory.parse(json['category'] as String),
      secondaryCategories: [
        for (final c in (json['secondaryCategories'] as List? ?? const [])) PlaceCategory.parse(c as String),
      ],
      location: GeoPoint((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble()),
      visitMinutes: (json['visitMinutes'] as num).toInt(),
      entryFee: json['entryFeeNpr'] == null
          ? const EntryFee.free()
          : EntryFee.fromJson(json['entryFeeNpr'] as Map<String, dynamic>),
      openingHours: OpeningHours.fromJson(json['openingHours'] as Map<String, dynamic>),
      setting: Setting.parse(json['setting'] as String),
      bestTimes: [for (final t in (json['bestTimes'] as List? ?? const [])) t as String],
      popularity: popularity,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      localizedNames: {
        for (final e in i18n.entries)
          if ((e.value as Map<String, dynamic>)['name'] case final String n) e.key: n,
      },
    );
  }

  @override
  bool operator ==(Object other) => other is Place && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Place($id)';
}
