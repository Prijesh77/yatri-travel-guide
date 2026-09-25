import 'package:flutter/material.dart';

import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/journey_planner.dart';
import '../domain/route_network.dart';

/// Route option card from the Transit wireframe: route + vehicle, where to
/// board, frequency, total time and fare. Expands to step-by-step legs.
class JourneyCard extends StatefulWidget {
  const JourneyCard({super.key, required this.journey, this.group, this.isBest = false, this.onShowMap});

  final Journey journey;

  /// Other routes serving the same stops, shown as alternatives.
  final JourneyGroup? group;
  final bool isBest;
  final VoidCallback? onShowMap;

  @override
  State<JourneyCard> createState() => _JourneyCardState();
}

class _JourneyCardState extends State<JourneyCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final j = widget.journey;
    final first = j.rides.first;
    final firstWalk = j.legs.first is WalkLeg ? (j.legs.first as WalkLeg).minutes : 0;
    final title = (widget.group?.routeIdsPerRide ?? [for (final r in j.rides) [r.route.id]])
        .map((ids) => ids.join(' / '))
        .join(' → ');
    final vehicle = first.route.vehicle;
    final freq = first.route.frequencyMinutes;

    return SoftCard(
      highlighted: widget.isBest,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.directions_bus, size: 20, color: widget.isBest ? AppTheme.seed : null),
              const SizedBox(width: 6),
              Expanded(
                child: Text('$title · $vehicle',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: widget.isBest ? AppTheme.seed : null)),
              ),
              if (freq != null)
                Text(l10n.everyMinutes(freq),
                    style: theme.textTheme.labelMedium?.copyWith(color: widget.isBest ? AppTheme.seed : null)),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.boardAt(first.board.name, firstWalk), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            '${l10n.totalTime(l10n.duration(j.totalMinutes))} · ${l10n.npr(l10n.amount(j.fare))}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _statusTag(context, j.weakestStatus),
              if (j.transfers > 0)
                TagChip(l10n.changes(j.transfers),
                    color: theme.colorScheme.onSurfaceVariant, background: theme.colorScheme.surfaceContainerHighest),
              if (j.hasRoughStop)
                TagChip(l10n.roughStop, color: AppTheme.alertColor, background: AppTheme.alertBackground),
            ],
          ),
          if (_expanded) ...[
            const Divider(height: 20),
            for (final leg in j.legs) _LegRow(leg: leg),
            if (widget.onShowMap != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onShowMap,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(l10n.showOnMap),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static Widget _statusTag(BuildContext context, RouteStatus status) {
    final l10n = context.l10n;
    return status.isVerified
        ? TagChip(l10n.routeStatus(status.name),
            icon: Icons.verified, color: AppTheme.eventColor, background: AppTheme.eventBackground)
        : TagChip(l10n.routeStatus(status.name),
            icon: Icons.help_outline, color: AppTheme.alertColor, background: AppTheme.alertBackground);
  }
}

class _LegRow extends StatelessWidget {
  const _LegRow({required this.leg});
  final JourneyLeg leg;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (icon, text, sub) = switch (leg) {
      WalkLeg(:final toStop?, fromStop: null) => (Icons.directions_walk, l10n.walkTo(toStop.name), l10n.duration(leg.minutes)),
      WalkLeg(:final fromStop?, :final toStop?) =>
        (Icons.transfer_within_a_station, l10n.walkBetween(fromStop.name, toStop.name), l10n.duration(leg.minutes)),
      WalkLeg() => (Icons.directions_walk, l10n.walkToDestination, l10n.duration(leg.minutes)),
      RideLeg(
        :final route,
        :final board,
        :final alight,
        :final stopCount,
        :final fare,
        :final rideMinutes,
        :final waitMinutes,
      ) =>
        (
          Icons.directions_bus,
          l10n.rideFromTo(route.name, board.name, alight.name),
          '${l10n.stopsCount(stopCount)} · ${l10n.duration(rideMinutes)} · '
              '${l10n.waitAbout(waitMinutes)} · ${l10n.npr(l10n.amount(fare))}'
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyMedium),
                Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
