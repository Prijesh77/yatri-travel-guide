import '../../../core/geo/geo_point.dart';

/// Well-known starting points for the planner when GPS is off or the
/// traveller is planning ahead. Labels are l10n keys resolved in the UI.
enum StartPreset {
  thamel(GeoPoint(27.7154, 85.3123)),
  patan(GeoPoint(27.67275, 85.3253)),
  bhaktapur(GeoPoint(27.6722, 85.4281)),
  boudha(GeoPoint(27.7215, 85.3620)),
  airport(GeoPoint(27.6966, 85.3591));

  const StartPreset(this.location);
  final GeoPoint location;
}
