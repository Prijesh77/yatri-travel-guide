import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/weather_repository.dart';
import '../domain/weather.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return OpenMeteoWeatherRepository(
    store: ref.watch(keyValueStoreProvider),
    clock: ref.watch(clockProvider),
  );
});

/// No automatic retry: the repository already falls back to the cached
/// result, and the user can pull to refresh or tap "Retry".
final weatherProvider = FutureProvider<WeatherReport>(
  (ref) => ref.watch(weatherRepositoryProvider).getWeather(),
  retry: (_, _) => null,
);

/// Latest weather if available, without waiting. Screens use this so that
/// recommendations appear immediately and improve when weather arrives.
final weatherOrNullProvider = Provider<WeatherReport?>((ref) {
  return ref.watch(weatherProvider).value;
});
