import 'dart:convert';

import '../../../core/data/key_value_store.dart';
import '../../../core/geo/geo_point.dart';
import '../domain/condition_alert.dart';

/// What a user fills in on the Report sheet.
class NewReport {
  const NewReport({
    required this.type,
    required this.title,
    required this.location,
    required this.locationLabel,
    this.description = '',
    this.start,
    this.duration,
  });

  final AlertType type;
  final String title;
  final String description;
  final GeoPoint location;
  final String locationLabel;

  /// Defaults to now.
  final DateTime? start;

  /// Defaults per type (see [CommunityReportsRepository.defaultDuration]).
  final Duration? duration;
}

/// Crowdsourced disruption and event reports.
///
/// v1 stores reports on this device only. A backend implementation of the
/// same interface can share them between users later.
abstract interface class ReportsRepository {
  List<ConditionAlert> all();
  Future<ConditionAlert> add(NewReport report, DateTime now);

  /// Adds one confirmation, at most once per device. Returns false if this
  /// device already confirmed the report.
  Future<bool> confirm(String id);
  bool hasConfirmed(String id);
  Future<void> remove(String id);

  /// Drops reports that ended before [now].
  Future<void> prune(DateTime now);

  /// Demo reports around [now], labelled as samples.
  Future<void> loadSamples(DateTime now);
}

class LocalReportsRepository implements ReportsRepository {
  LocalReportsRepository(this.store);
  final KeyValueStore store;

  static const _reportsKey = 'community.reports.v1';
  static const _confirmedKey = 'community.confirmed.v1';

  static Duration defaultDuration(AlertType type) => switch (type) {
        AlertType.traffic => const Duration(hours: 1),
        AlertType.roadClosure => const Duration(hours: 3),
        AlertType.closure => const Duration(hours: 8),
        AlertType.bandh => const Duration(hours: 12),
        AlertType.festival => const Duration(hours: 3),
      };

  @override
  List<ConditionAlert> all() {
    final raw = store.getString(_reportsKey);
    if (raw == null) return [];
    try {
      return [
        for (final r in jsonDecode(raw) as List) ConditionAlert.fromJson(r as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ConditionAlert> add(NewReport report, DateTime now) async {
    final start = report.start ?? now;
    final alert = ConditionAlert(
      id: 'user-${now.microsecondsSinceEpoch}',
      type: report.type,
      title: report.title.trim(),
      description: report.description.trim(),
      start: start,
      end: start.add(report.duration ?? defaultDuration(report.type)),
      location: report.location,
      radiusKm: report.type == AlertType.festival ? 1.0 : 0.5,
      locationLabel: report.locationLabel,
      source: AlertSource.community,
      reportedAt: now,
    );
    await _save([...all(), alert]);
    return alert;
  }

  @override
  bool hasConfirmed(String id) => _confirmed().contains(id);

  @override
  Future<bool> confirm(String id) async {
    final confirmed = _confirmed();
    if (!confirmed.add(id)) return false;
    await store.setString(_confirmedKey, jsonEncode(confirmed.toList()));
    await _save([
      for (final a in all()) a.id == id ? a.copyWith(confirmations: a.confirmations + 1) : a,
    ]);
    return true;
  }

  @override
  Future<void> remove(String id) => _save([for (final a in all()) if (a.id != id) a]);

  @override
  Future<void> prune(DateTime now) => _save([for (final a in all()) if (!a.isExpiredAt(now)) a]);

  @override
  Future<void> loadSamples(DateTime now) async {
    final samples = [
      ConditionAlert(
        id: 'sample-naxal-closure',
        type: AlertType.roadClosure,
        title: 'Road closed – Naxal, near Narayanhiti',
        start: now.subtract(const Duration(minutes: 20)),
        end: now.add(const Duration(hours: 3)),
        location: const GeoPoint(27.7150, 85.3225),
        radiusKm: 0.4,
        locationLabel: 'Naxal',
        source: AlertSource.sample,
        reportedAt: now.subtract(const Duration(minutes: 20)),
        confirmations: 14,
      ),
      ConditionAlert(
        id: 'sample-koteshwor-traffic',
        type: AlertType.traffic,
        title: 'Heavy traffic – Koteshwor junction',
        start: now.subtract(const Duration(minutes: 10)),
        end: now.add(const Duration(hours: 1)),
        location: const GeoPoint(27.6780, 85.3490),
        radiusKm: 0.5,
        locationLabel: 'Koteshwor',
        source: AlertSource.sample,
        reportedAt: now.subtract(const Duration(minutes: 10)),
        confirmations: 5,
      ),
      ConditionAlert(
        id: 'sample-basantapur-procession',
        type: AlertType.festival,
        title: 'Jatra procession – Basantapur',
        description: 'Chariot procession around Kathmandu Durbar Square.',
        start: DateTime.utc(now.year, now.month, now.day, 16),
        end: DateTime.utc(now.year, now.month, now.day, 20),
        location: const GeoPoint(27.7042, 85.3067),
        radiusKm: 1.0,
        locationLabel: 'Durbar Square',
        source: AlertSource.sample,
        reportedAt: now.subtract(const Duration(hours: 2)),
        confirmations: 9,
      ),
    ];
    final ids = {for (final s in samples) s.id};
    await _save([...all().where((a) => !ids.contains(a.id)), ...samples]);
  }

  Set<String> _confirmed() {
    final raw = store.getString(_confirmedKey);
    if (raw == null) return {};
    try {
      return {for (final id in jsonDecode(raw) as List) id as String};
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(List<ConditionAlert> alerts) =>
      store.setString(_reportsKey, jsonEncode([for (final a in alerts) a.toJson()]));
}
