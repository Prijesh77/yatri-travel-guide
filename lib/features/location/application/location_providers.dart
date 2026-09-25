import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo_point.dart';
import '../data/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) => const GeolocatorLocationService());

/// Raw device location (may be anywhere in the world).
final deviceLocationProvider = FutureProvider<GeoPoint?>((ref) {
  return ref.watch(locationServiceProvider).currentLocation();
});

/// Device location only when inside the valley; used for distance scoring.
final userLocationProvider = Provider<GeoPoint?>((ref) {
  final here = ref.watch(deviceLocationProvider).value;
  return here != null && ValleyBounds.contains(here) ? here : null;
});
