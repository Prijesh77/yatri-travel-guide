import '../../places/domain/place_category.dart';
import '../../transport/domain/transport_option.dart';

class UserPreferences {
  const UserPreferences({
    this.interests = const {},
    this.visitorType = VisitorType.foreigner,
    this.travelStyle = TravelStyle.balanced,
  });

  final Set<PlaceCategory> interests;
  final VisitorType visitorType;
  final TravelStyle travelStyle;

  UserPreferences copyWith({
    Set<PlaceCategory>? interests,
    VisitorType? visitorType,
    TravelStyle? travelStyle,
  }) =>
      UserPreferences(
        interests: interests ?? this.interests,
        visitorType: visitorType ?? this.visitorType,
        travelStyle: travelStyle ?? this.travelStyle,
      );

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        interests: {
          for (final c in (json['interests'] as List? ?? const [])) ?PlaceCategory.values.asNameMap()[c],
        },
        visitorType: VisitorType.values.asNameMap()[json['visitorType']] ?? VisitorType.foreigner,
        travelStyle: TravelStyle.values.asNameMap()[json['travelStyle']] ?? TravelStyle.balanced,
      );

  Map<String, dynamic> toJson() => {
        'interests': [for (final c in interests) c.name],
        'visitorType': visitorType.name,
        'travelStyle': travelStyle.name,
      };
}
