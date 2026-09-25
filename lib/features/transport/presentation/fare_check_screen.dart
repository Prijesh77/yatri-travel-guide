import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../location/presentation/location_picker.dart';
import '../application/fare_reports_providers.dart';
import '../application/transport_providers.dart';
import '../domain/fare_estimator.dart';
import '../domain/fare_report.dart';
import '../domain/transport_option.dart';

/// "Fare check": what a trip should cost (official slab / meter) and what
/// people actually paid (crowdsourced reports on this device).
class FareCheckScreen extends ConsumerStatefulWidget {
  const FareCheckScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FareCheckScreen()));

  @override
  ConsumerState<FareCheckScreen> createState() => _FareCheckScreenState();
}

class _FareCheckScreenState extends ConsumerState<FareCheckScreen> {
  LocationChoice? _from;
  LocationChoice? _to;
  FareMode _mode = FareMode.bus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allReports = ref.watch(fareReportsProvider);
    final estimator = ref.watch(fareEstimatorProvider).value;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ScreenHeader(
            icon: Icons.confirmation_number_outlined,
            title: l10n.fareCheck,
            color: AppTheme.eventColor,
            background: AppTheme.eventBackground,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                PickerField(
                  value: _from?.label,
                  hint: l10n.fareFromHint,
                  icon: Icons.trip_origin,
                  onTap: () async {
                    final c = await showLocationPicker(context, title: l10n.fareFromHint);
                    if (c != null) setState(() => _from = c);
                  },
                ),
                const SizedBox(height: 8),
                PickerField(
                  value: _to?.label,
                  hint: l10n.fareToHint,
                  icon: Icons.place_outlined,
                  onTap: () async {
                    final c = await showLocationPicker(context, title: l10n.fareToHint);
                    if (c != null) setState(() => _to = c);
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final m in FareMode.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(l10n.fareMode(m.name)),
                            selected: _mode == m,
                            onSelected: (_) => setState(() => _mode = m),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_from != null && _to != null && estimator != null)
            _FareResult(from: _from!, to: _to!, mode: _mode, estimator: estimator)
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.fareCheckIntro, style: Theme.of(context).textTheme.bodyMedium),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.submitFareReport),
              onPressed: () => _submitReport(context),
            ),
          ),
          if (allReports.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextButton(
                onPressed: () => ref.read(fareReportsProvider.notifier).loadSamples(),
                child: Text(l10n.loadSampleFares),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitReport(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showModalBottomSheet<(LocationChoice, LocationChoice, FareMode, int)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FareReportSheet(from: _from, to: _to, mode: _mode),
    );
    if (result == null || !context.mounted) return;
    final (from, to, mode, fare) = result;
    await ref.read(fareReportsProvider.notifier).submit(from: from.label, to: to.label, mode: mode, fareNpr: fare);
    setState(() {
      _from = from;
      _to = to;
      _mode = mode;
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fareReportThanks)));
    }
  }
}

class _FareResult extends ConsumerWidget {
  const _FareResult({required this.from, required this.to, required this.mode, required this.estimator});
  final LocationChoice from;
  final LocationChoice to;
  final FareMode mode;
  final FareEstimator estimator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    ref.watch(fareReportsProvider);
    final reports = ref.read(fareReportsRepositoryProvider).forTrip(from.label, to.label, mode: mode);
    final stats = FareStats.of(reports.map((r) => r.fareNpr));
    final now = ref.watch(nowProvider);

    // Official reference: distance slab for public vehicles, meter for taxis.
    String? official;
    String? routeLine;
    switch (mode) {
      case FareMode.bus || FareMode.microbus || FareMode.tempo:
        final journeys = estimator.journeys.plan(from.point, to.point, now, maxResults: 1);
        if (journeys.isNotEmpty) {
          final j = journeys.first;
          official = l10n.officialFare(l10n.npr(l10n.amount(j.fare)), l10n.distance(j.rideKm));
          routeLine = j.rides.map((r) => r.route.id).join(' → ');
        } else {
          final km = estimator.roadKm(from.point, to.point);
          official = l10n.officialFare(l10n.npr(l10n.amount(estimator.network.bus.fareForKm(km))), l10n.distance(km));
        }
      case FareMode.taxi || FareMode.bikeTaxi:
        final km = estimator.roadKm(from.point, to.point);
        final option = estimator.hailedOption(
            mode == FareMode.taxi ? TransportMode.taxi : TransportMode.bikeTaxi, km, now);
        official = mode == FareMode.taxi
            ? l10n.meterFare(l10n.fare(option.fare), l10n.distance(km))
            : l10n.appEstimate(l10n.fare(option.fare), l10n.distance(km));
    }

    final headline = [?routeLine, l10n.fareMode(mode.name), '${from.label} → ${to.label}'].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            if (stats != null) ...[
              Text(
                stats.low == stats.high
                    ? l10n.npr(l10n.amount(stats.typical))
                    : l10n.nprRange(l10n.amount(stats.low), l10n.amount(stats.high)),
                style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.eventColor, fontWeight: FontWeight.w700),
              ),
              Text(
                l10n.basedOnReports(stats.count) +
                    (reports.any((r) => r.isSample) ? ' · ${l10n.includesSamples}' : ''),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              _RangeBar(stats: stats),
            ] else
              Text(l10n.noFareReports, style: theme.textTheme.bodyMedium),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.gavel, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(official, style: theme.textTheme.bodySmall)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.stats});
  final FareStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final typicalPos = stats.position(stats.typical);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Container(height: 10, decoration: BoxDecoration(color: AppTheme.eventBackground, borderRadius: BorderRadius.circular(5))),
              Positioned(
                left: c.maxWidth * 0.15,
                width: c.maxWidth * 0.7,
                child: Container(height: 10, decoration: BoxDecoration(color: const Color(0xFF6A9E2C), borderRadius: BorderRadius.circular(5))),
              ),
              Positioned(
                left: (c.maxWidth * (0.15 + 0.7 * typicalPos) - 2).clamp(0, c.maxWidth - 4),
                child: Container(width: 4, height: 10, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('${l10n.fareLow} ${l10n.amount(stats.low)}', style: theme.textTheme.labelSmall),
            const Spacer(),
            Text('${l10n.fareTypical} ${l10n.amount(stats.typical)}', style: theme.textTheme.labelSmall),
            const Spacer(),
            Text('${l10n.fareHigh} ${l10n.amount(stats.high)}', style: theme.textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _FareReportSheet extends StatefulWidget {
  const _FareReportSheet({this.from, this.to, required this.mode});
  final LocationChoice? from;
  final LocationChoice? to;
  final FareMode mode;

  @override
  State<_FareReportSheet> createState() => _FareReportSheetState();
}

class _FareReportSheetState extends State<_FareReportSheet> {
  late LocationChoice? _from = widget.from;
  late LocationChoice? _to = widget.to;
  late FareMode _mode = widget.mode;
  final _fare = TextEditingController();

  @override
  void dispose() {
    _fare.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fare = int.tryParse(_fare.text);
    final valid = _from != null && _to != null && fare != null && fare > 0 && fare < 100000;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.submitFareReport, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          PickerField(
            value: _from?.label,
            hint: l10n.fareFromHint,
            icon: Icons.trip_origin,
            onTap: () async {
              final c = await showLocationPicker(context, title: l10n.fareFromHint);
              if (c != null) setState(() => _from = c);
            },
          ),
          const SizedBox(height: 8),
          PickerField(
            value: _to?.label,
            hint: l10n.fareToHint,
            icon: Icons.place_outlined,
            onTap: () async {
              final c = await showLocationPicker(context, title: l10n.fareToHint);
              if (c != null) setState(() => _to = c);
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m in FareMode.values)
                ChoiceChip(
                  label: Text(l10n.fareMode(m.name)),
                  selected: _mode == m,
                  onSelected: (_) => setState(() => _mode = m),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fare,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.farePaid, prefixText: 'Rs '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: valid ? () => Navigator.pop(context, (_from!, _to!, _mode, fare)) : null,
            child: Text(l10n.submit),
          ),
          const SizedBox(height: 4),
          Text(l10n.reportsOnDevice, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
