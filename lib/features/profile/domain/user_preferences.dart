import '../../places/domain/place_category.dart';
import '../../transport/domain/transport_option.dart';

class UserPreferences {
  const UserPreferences({
    this.interests = const {},
    this.visitorType = VisitorType.foreigner,
    this.travelStyle = TravelStyle.balanced,
    this.notifications = true,
  });

  final Set<PlaceCategory> interests;
  final VisitorType visitorType;
  final TravelStyle travelStyle;

  /// Alerts about disruptions near saved places (delivery comes with the
  /// backend; the preference is stored now).
  final bool notifications;

  UserPreferences copyWith({
    Set<PlaceCategory>? interests,
    VisitorType? visitorType,
    TravelStyle? travelStyle,
    bool? notifications,
  }) =>
      UserPreferences(
        interests: interests ?? this.interests,
        visitorType: visitorType ?? this.visitorType,
        travelStyle: travelStyle ?? this.travelStyle,
        notifications: notifications ?? this.notifications,
      );

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        interests: {
          for (final c in (json['interests'] as List? ?? const [])) ?PlaceCategory.values.asNameMap()[c],
        },
        visitorType: VisitorType.values.asNameMap()[json['visitorType']] ?? VisitorType.foreigner,
        travelStyle: TravelStyle.values.asNameMap()[json['travelStyle']] ?? TravelStyle.balanced,
        notifications: json['notifications'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'interests': [for (final c in interests) c.name],
        'visitorType': visitorType.name,
        'travelStyle': travelStyle.name,
        'notifications': notifications,
      };
}
