import 'dart:convert';

import '../../../core/data/key_value_store.dart';
import '../domain/fare_report.dart';

/// Crowdsourced fare reports. Stored on this device in v1; a backend can
/// implement the same interface to aggregate reports from everyone.
abstract interface class FareReportsRepository {
  List<FareReport> all();
  List<FareReport> forTrip(String from, String to, {FareMode? mode});
  Future<FareReport> add({
    required String from,
    required String to,
    required FareMode mode,
    required int fareNpr,
    required DateTime now,
    String routeLabel = '',
  });
  Future<void> loadSamples(DateTime now);
}

class LocalFareReportsRepository implements FareReportsRepository {
  LocalFareReportsRepository(this.store);
  final KeyValueStore store;

  static const _key = 'community.fares.v1';

  @override
  List<FareReport> all() {
    final raw = store.getString(_key);
    if (raw == null) return [];
    try {
      return [for (final r in jsonDecode(raw) as List) FareReport.fromJson(r as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  @override
  List<FareReport> forTrip(String from, String to, {FareMode? mode}) => [
        for (final r in all())
          if (r.matches(from, to) && (mode == null || r.mode == mode)) r,
      ];

  @override
  Future<FareReport> add({
    required String from,
    required String to,
    required FareMode mode,
    required int fareNpr,
    required DateTime now,
    String routeLabel = '',
  }) async {
    if (fareNpr <= 0) throw ArgumentError.value(fareNpr, 'fareNpr', 'must be positive');
    final report = FareReport(
      id: 'fare-${now.microsecondsSinceEpoch}',
      from: from.trim(),
      to: to.trim(),
      mode: mode,
      fareNpr: fareNpr,
      routeLabel: routeLabel,
      reportedAt: now,
    );
    await _save([...all(), report]);
    return report;
  }

  @override
  Future<void> loadSamples(DateTime now) async {
    var n = 0;
    FareReport sample(String from, String to, FareMode mode, int fare, [String route = '']) => FareReport(
          id: 'sample-fare-${n++}',
          from: from,
          to: to,
          mode: mode,
          fareNpr: fare,
          routeLabel: route,
          reportedAt: now.subtract(Duration(days: n)),
          isSample: true,
        );
    final samples = [
      for (final f in [33, 33, 35, 30, 33, 40, 33]) sample('Ratnapark', 'Koteshwor', FareMode.bus, f),
      for (final f in [35, 35, 40, 33]) sample('Ratnapark', 'Koteshwor', FareMode.microbus, f),
      for (final f in [39, 44, 44, 45, 50]) sample('Ratnapark', 'Kamalbinayak', FareMode.bus, f),
      for (final f in [33, 33, 35]) sample('Lagankhel', 'Ratnapark', FareMode.bus, f, 'SAJ-03'),
      for (final f in [500, 600, 700, 550]) sample('Tribhuvan International Airport', 'Thamel', FareMode.taxi, f),
    ];
    await _save([...all().where((r) => !r.isSample), ...samples]);
  }

  Future<void> _save(List<FareReport> reports) =>
      store.setString(_key, jsonEncode([for (final r in reports) r.toJson()]));
}
