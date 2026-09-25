import 'dart:math' as math;

import '../../../core/time/kathmandu_time.dart';

/// Vehicle types people report fares for. Microbuses and tempos are the
/// least documented modes in the valley, so they get their own entries.
enum FareMode { bus, microbus, tempo, taxi, bikeTaxi }

/// A fare someone actually paid.
class FareReport {
  const FareReport({
    required this.id,
    required this.from,
    required this.to,
    required this.mode,
    required this.fareNpr,
    required this.reportedAt,
    this.routeLabel = '',
    this.isSample = false,
  });

  final String id;

  /// Free-text stop / place names, matched case-insensitively.
  final String from;
  final String to;
  final FareMode mode;
  final int fareNpr;
  final String routeLabel;
  final DateTime reportedAt;
  final bool isSample;

  /// Same trip in either direction.
  bool matches(String a, String b) {
    final x = _norm(from), y = _norm(to), p = _norm(a), q = _norm(b);
    return (x == p && y == q) || (x == q && y == p);
  }

  static String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  factory FareReport.fromJson(Map<String, dynamic> json) => FareReport(
        id: json['id'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        mode: FareMode.values.byName(json['mode'] as String),
        fareNpr: (json['fareNpr'] as num).toInt(),
        routeLabel: json['routeLabel'] as String? ?? '',
        reportedAt: parseKtmLocal(json['reportedAt'] as String),
        isSample: json['isSample'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'to': to,
        'mode': mode.name,
        'fareNpr': fareNpr,
        if (routeLabel.isNotEmpty) 'routeLabel': routeLabel,
        'reportedAt': reportedAt.toIso8601String().replaceAll('Z', ''),
        if (isSample) 'isSample': true,
      };
}

/// Low / typical / high summary of reported fares.
class FareStats {
  const FareStats({required this.count, required this.low, required this.typical, required this.high});

  final int count;

  /// 10th percentile, median and 90th percentile (so one odd report does not
  /// stretch the range).
  final int low;
  final int typical;
  final int high;

  static FareStats? of(Iterable<int> fares) {
    final sorted = fares.where((f) => f > 0).toList()..sort();
    if (sorted.isEmpty) return null;
    int pct(double p) {
      final pos = p * (sorted.length - 1);
      final lo = pos.floor(), hi = pos.ceil();
      return (sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo)).round();
    }

    return FareStats(count: sorted.length, low: pct(0.1), typical: pct(0.5), high: pct(0.9));
  }

  /// Where [fare] sits between [low] and [high], 0..1 (for the range bar).
  double position(int fare) => high == low ? 0.5 : ((fare - low) / (high - low)).clamp(0.0, 1.0);

  /// True when [fare] is well above what people usually pay.
  bool isHigh(int fare) => fare > math.max(high, typical * 1.25);
}
