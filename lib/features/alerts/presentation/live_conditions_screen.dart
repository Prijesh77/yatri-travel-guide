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
    final disruptions = [
      for (final a in alerts)
        if (a.type.isDisruption) a,
    ];
    final events = [
      for (final a in alerts)
        if (a.isEvent) a,
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ScreenHeader(
              icon: Icons.warning_amber_rounded,
              title: l10n.liveConditions,
              color: context.yatri.alert,
              background: context.yatri.alertContainer,
              action: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                icon: const Icon(Icons.add),
                label: Text(l10n.report),
                onPressed: () => showReportSheet(context),
              ),
            ),
            if (alerts.isEmpty)
              _EmptyState(onLoadSamples: () => ref.read(communityReportsProvider.notifier).loadSamples())
            else ...[
              SectionLabel(l10n.disruptions, trailing: _CountBadge(disruptions.length, color: context.yatri.alert)),
              if (disruptions.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.noDisruptions)),
              for (final a in disruptions) _AlertCard(alert: a),
              SectionLabel(l10n.events, trailing: _CountBadge(events.length, color: context.yatri.ai)),
              if (events.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.noEvents)),
              for (final a in events) _AlertCard(alert: a),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phone_android, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.reportsOnDevice,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
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
    final theme = Theme.of(context);
    final y = context.yatri;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: y.eventContainer, shape: BoxShape.circle),
            child: Icon(Icons.verified_outlined, size: 44, color: y.event),
          ),
          const SizedBox(height: 16),
          Text(l10n.allClear, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            l10n.allClearBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.report),
            onPressed: () => showReportSheet(context),
          ),
          const SizedBox(height: 4),
          TextButton(onPressed: onLoadSamples, child: Text(l10n.loadSampleReports)),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count, {required this.color});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
      child: Text('$count', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
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
    final accent = alert.isEvent ? context.yatri.ai : context.yatri.alert;
    final accentContainer = alert.isEvent ? context.yatri.aiContainer : context.yatri.alertContainer;
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
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alert.location == null ? null : () => MapScreen.open(context, focus: [alert.location!]),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accent, width: 4)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: accentContainer, borderRadius: BorderRadius.circular(9)),
                      child: Icon(
                        alert.isEvent ? Icons.celebration_outlined : Icons.warning_amber_rounded,
                        size: 17,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(alert.title, style: theme.textTheme.titleSmall),
                      ),
                    ),
                    if (alert.location != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, right: 4),
                        child: Icon(Icons.map_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  meta.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (alert.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(alert.description, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TagChip(
                          l10n.alertSource(alert.source.name),
                          color: theme.colorScheme.onSurfaceVariant,
                          background: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    if (isCrowd)
                      Flexible(
                        flex: 2,
                        child: TextButton.icon(
                          onPressed: confirmed
                              ? null
                              : () async {
                                  await controller.confirm(alert.id);
                                },
                          icon: Icon(confirmed ? Icons.thumb_up : Icons.thumb_up_outlined, size: 18),
                          label: Text(confirmed ? l10n.confirmed : l10n.stillThere, overflow: TextOverflow.ellipsis),
                        ),
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
        ),
      ),
    );
  }
}
