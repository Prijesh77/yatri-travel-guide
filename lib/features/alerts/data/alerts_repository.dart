import '../../../core/data/json_source.dart';
import '../domain/condition_alert.dart';

/// Festivals, closures, road works and bandhs. Swap the JSON implementation
/// for a live feed when one is available.
abstract interface class AlertsRepository {
  Future<List<ConditionAlert>> getAlerts();
}

class JsonAlertsRepository implements AlertsRepository {
  JsonAlertsRepository(this._loader);
  final OfflineFirstJsonLoader _loader;

  @override
  Future<List<ConditionAlert>> getAlerts() async {
    final loaded = await _loader.load();
    return [
      for (final a in (loaded.json['alerts'] as List? ?? const []))
        ConditionAlert.fromJson(a as Map<String, dynamic>),
    ];
  }
}
