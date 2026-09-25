import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/json_source.dart';
import '../../../core/providers/core_providers.dart';
import '../data/alerts_repository.dart';
import '../data/community_reports_repository.dart';
import '../domain/condition_alert.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return JsonAlertsRepository(OfflineFirstJsonLoader(
    cacheKey: 'cache.alerts',
    bundled: AssetJsonSource('assets/data/alerts.json'),
    store: ref.watch(keyValueStoreProvider),
  ));
});

/// Curated alerts (festival calendar, planned closures).
final officialAlertsProvider = FutureProvider<List<ConditionAlert>>((ref) {
  return ref.watch(alertsRepositoryProvider).getAlerts();
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return LocalReportsRepository(ref.watch(keyValueStoreProvider));
});

/// Community reports, kept in sync with the repository.
final communityReportsProvider =
    NotifierProvider<CommunityReportsController, List<ConditionAlert>>(CommunityReportsController.new);

class CommunityReportsController extends Notifier<List<ConditionAlert>> {
  ReportsRepository get _repo => ref.read(reportsRepositoryProvider);

  @override
  List<ConditionAlert> build() {
    final repo = ref.watch(reportsRepositoryProvider);
    final now = ref.read(clockProvider).now();
    repo.prune(now);
    return [for (final a in repo.all()) if (!a.isExpiredAt(now)) a];
  }

  Future<ConditionAlert> report(NewReport report) async {
    final alert = await _repo.add(report, ref.read(clockProvider).now());
    state = _repo.all();
    return alert;
  }

  Future<bool> confirm(String id) async {
    final ok = await _repo.confirm(id);
    state = _repo.all();
    return ok;
  }

  bool hasConfirmed(String id) => _repo.hasConfirmed(id);

  Future<void> remove(String id) async {
    await _repo.remove(id);
    state = _repo.all();
  }

  Future<void> loadSamples() async {
    await _repo.loadSamples(ref.read(clockProvider).now());
    state = _repo.all();
  }
}

/// Every alert the app knows about: official + community.
final alertsProvider = Provider<List<ConditionAlert>>((ref) {
  return [
    ...?ref.watch(officialAlertsProvider).value,
    ...ref.watch(communityReportsProvider),
  ];
});

/// Alerts in effect now or later today, disruptions first, newest first.
final activeAlertsProvider = Provider<List<ConditionAlert>>((ref) {
  final now = ref.watch(nowProvider);
  final alerts = [for (final a in ref.watch(alertsProvider)) if (a.isRelevantOn(now)) a];
  alerts.sort((a, b) {
    if (a.isEvent != b.isEvent) return a.isEvent ? 1 : -1;
    return (b.reportedAt ?? b.start).compareTo(a.reportedAt ?? a.start);
  });
  return alerts;
});
