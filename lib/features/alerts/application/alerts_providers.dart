import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/json_source.dart';
import '../../../core/providers/core_providers.dart';
import '../data/alerts_repository.dart';
import '../domain/condition_alert.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return JsonAlertsRepository(OfflineFirstJsonLoader(
    cacheKey: 'cache.alerts',
    bundled: AssetJsonSource('assets/data/alerts.json'),
    store: ref.watch(keyValueStoreProvider),
  ));
});

final alertsProvider = FutureProvider<List<ConditionAlert>>((ref) {
  return ref.watch(alertsRepositoryProvider).getAlerts();
});

/// Alerts in effect now or later today.
final activeAlertsProvider = Provider<List<ConditionAlert>>((ref) {
  final now = ref.watch(nowProvider);
  final endOfDay = DateTime.utc(now.year, now.month, now.day + 1);
  final alerts = ref.watch(alertsProvider).value ?? const [];
  return [
    for (final a in alerts)
      if (a.end.isAfter(now) && a.start.isBefore(endOfDay)) a,
  ];
});
