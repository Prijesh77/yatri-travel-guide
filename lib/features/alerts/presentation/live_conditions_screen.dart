import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../map/presentation/map_screen.dart';
import '../application/alerts_providers.dart';
import '../domain/condition_alert.dart';
import 'report_sheet.dart';

/// "Live conditions": disruptions and events, with crowdsourced reports.
class LiveConditionsScreen extends ConsumerWidget {
  const LiveConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final alerts = ref.watch(activeAlertsProvider);
    final disruptions = [for (final a in alerts) if (a.type.isDisruption) a];
    final events = [for (final a in alerts) if (a.isEvent) a];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ScreenHeader(
              icon: Icons.warning_amber_rounded,
              title: l10n.liveConditions,
              color: AppTheme.alertColor,
              background: AppTheme.alertBackground,
              action: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.report),
                onPressed: () => showReportSheet(context),
              ),
            ),
            if (alerts.isEmpty)
              _EmptyState(onLoadSamples: () => ref.read(communityReportsProvider.notifier).loadSamples())
            else ...[
              SectionLabel(l10n.disruptions),
              if (disruptions.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.noDisruptions)),
              for (final a in disruptions) _AlertCard(alert: a),
              SectionLabel(l10n.events),
              if (events.isEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.noEvents)),
              for (final a in events) _AlertCard(alert: a),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(l10n.reportsOnDevice, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLoadSamples});
  final VoidCallback onLoadSamples;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: AppTheme.eventColor),
          const SizedBox(height: 12),
          Text(l10n.allClear, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.allClearBody, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.report),
                onPressed: () => showReportSheet(context),
              ),
              TextButton(onPressed: onLoadSamples, child: Text(l10n.loadSampleReports)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  const _AlertCard({required this.alert});
  final ConditionAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = ref.watch(nowProvider);
    final controller = ref.read(communityReportsProvider.notifier);
    ref.watch(communityReportsProvider);
    final isCrowd = alert.source != AlertSource.official;
    final confirmed = isCrowd && controller.hasConfirmed(alert.id);

    final meta = <String>[
      l10n.alertType(alert.type.name),
      if (alert.isEvent)
        l10n.eventWhen(l10n.relativeDay(alert.start, now), l10n.time(alert.start))
      else if (alert.reportedAt != null)
        l10n.ago(alert.reportedAt!, now),
      if (alert.locationLabel.isNotEmpty && alert.isEvent) alert.locationLabel,
      if (isCrowd) l10n.confirms(alert.confirmations),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SoftCard(
        onTap: alert.location == null ? null : () => MapScreen.open(context, focus: [alert.location!]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(alert.isEvent ? Icons.event : Icons.warning_amber_rounded,
                    size: 18, color: alert.isEvent ? AppTheme.eventColor : AppTheme.alertColor),
                const SizedBox(width: 6),
                Expanded(child: Text(alert.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 4),
            Text(meta.join(' · '), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (alert.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(alert.description, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TagChip(
                  l10n.alertSource(alert.source.name),
                  color: theme.colorScheme.onSurfaceVariant,
                  background: theme.colorScheme.surfaceContainerHighest,
                ),
                const Spacer(),
                if (isCrowd)
                  TextButton.icon(
                    onPressed: confirmed
                        ? null
                        : () async {
                            await controller.confirm(alert.id);
                          },
                    icon: Icon(confirmed ? Icons.thumb_up : Icons.thumb_up_outlined, size: 18),
                    label: Text(confirmed ? l10n.confirmed : l10n.stillThere),
                  ),
                if (alert.source == AlertSource.community || alert.source == AlertSource.sample)
                  IconButton(
                    tooltip: l10n.removeReport,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => controller.remove(alert.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
