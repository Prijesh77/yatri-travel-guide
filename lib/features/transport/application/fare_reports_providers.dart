import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/fare_reports_repository.dart';
import '../domain/fare_report.dart';

final fareReportsRepositoryProvider = Provider<FareReportsRepository>((ref) {
  return LocalFareReportsRepository(ref.watch(keyValueStoreProvider));
});

final fareReportsProvider = NotifierProvider<FareReportsController, List<FareReport>>(FareReportsController.new);

class FareReportsController extends Notifier<List<FareReport>> {
  FareReportsRepository get _repo => ref.read(fareReportsRepositoryProvider);

  @override
  List<FareReport> build() => ref.watch(fareReportsRepositoryProvider).all();

  Future<void> submit({
    required String from,
    required String to,
    required FareMode mode,
    required int fareNpr,
    String routeLabel = '',
  }) async {
    await _repo.add(
      from: from,
      to: to,
      mode: mode,
      fareNpr: fareNpr,
      routeLabel: routeLabel,
      now: ref.read(clockProvider).now(),
    );
    state = _repo.all();
  }

  Future<void> loadSamples() async {
    await _repo.loadSamples(ref.read(clockProvider).now());
    state = _repo.all();
  }
}
