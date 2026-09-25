import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../map/presentation/map_screen.dart';
import '../../places/presentation/place_detail_screen.dart';
import '../../places/presentation/place_widgets.dart';
import '../../profile/application/preferences_controller.dart';
import '../../transport/domain/transport_option.dart';
import '../../transport/presentation/transport_options_list.dart';
import '../../weather/application/weather_providers.dart';
import '../application/itinerary_controller.dart';
import '../domain/itinerary.dart';

/// The suggested itinerary as a vertical timeline (wireframe 05): a travel
/// entry ("9:00 am · Depart via SAJ-03", tagged "rerouted") before each stop
/// ("10:30 am · Patan Durbar Square", tagged "event"). Stops can be dragged
/// to reorder or removed.
class PlanTimeline extends ConsumerWidget {
  const PlanTimeline({super.key, required this.itinerary, required this.header});

  final Itinerary itinerary;
  final Widget header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(itineraryControllerProvider.notifier);

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      buildDefaultDragHandles: false,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, _Summary(itinerary: itinerary)],
      ),
      footer: itinerary.isEmpty
          ? Padding(padding: const EdgeInsets.all(24), child: Text(l10n.emptyItinerary, textAlign: TextAlign.center))
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(l10n.transportDisclaimer, style: Theme.of(context).textTheme.bodySmall),
            ),
      itemCount: itinerary.stops.length,
      onReorderItem: controller.move,
      itemBuilder: (context, i) {
        final stop = itinerary.stops[i];
        return _TimelineItem(
          key: ValueKey(stop.place.id),
          index: i,
          stop: stop,
          isLast: i == itinerary.stops.length - 1,
          onRemove: () {
            controller.removeAt(i);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(l10n.stopRemoved(stop.place.name)),
                action: SnackBarAction(label: l10n.undo, onPressed: () => controller.insertAt(i, stop.place)),
              ));
          },
        );
      },
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.itinerary});
  final Itinerary itinerary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visitor = ref.watch(preferencesProvider.select((p) => p.visitorType));
    final day = ref.watch(weatherOrNullProvider)?.dayOf(itinerary.request.startTime);
    final controller = ref.read(itineraryControllerProvider.notifier);
    final r = itinerary.request;

    final (sourceIcon, sourceText, sourceColor) = switch (itinerary.source) {
      PlanSource.ai => (Icons.auto_awesome, l10n.plannedWithAi, AppTheme.aiColor),
      PlanSource.local => (Icons.memory, l10n.plannedOnDevice, theme.colorScheme.onSurfaceVariant),
      PlanSource.localFallback => (Icons.cloud_off, l10n.aiUnavailableFallback, AppTheme.alertColor),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.suggestedItinerary, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(sourceIcon, size: 16, color: sourceColor),
              const SizedBox(width: 6),
              Expanded(child: Text(sourceText, style: theme.textTheme.bodySmall?.copyWith(color: sourceColor))),
            ],
          ),
          if (itinerary.summary != null) ...[
            const SizedBox(height: 6),
            Text(itinerary.summary!, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 8),
          Text(
            '${DateFormat.MMMMEEEEd(l10n.localeName).format(r.startTime)} · '
            '${l10n.itinerarySummary(itinerary.stops.length, l10n.time(r.startTime), l10n.time(itinerary.endTime))}',
            style: theme.textTheme.bodySmall,
          ),
          if (!itinerary.isEmpty)
            Text(
              '${l10n.travelTime(l10n.duration(itinerary.totalTravelMinutes))} · '
              '${l10n.itineraryCosts(l10n.fare(itinerary.transportCost), l10n.fee(itinerary.entryFees(visitor)))}',
              style: theme.textTheme.bodySmall,
            ),
          if (day != null)
            Text(l10n.dayForecast(l10n.weatherCondition(day.condition.name), day.minC.round(), day.maxC.round()),
                style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (itinerary.stops.length > 2)
                OutlinedButton.icon(
                  icon: const Icon(Icons.route, size: 18),
                  label: Text(l10n.optimizeOrder),
                  onPressed: () async {
                    await controller.optimize();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.orderOptimized)));
                    }
                  },
                ),
              if (!itinerary.isEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(l10n.showRouteOnMap),
                  onPressed: () => MapScreen.open(context, showPlan: true),
                ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.clearPlan),
                onPressed: controller.clear,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    super.key,
    required this.index,
    required this.stop,
    required this.isLast,
    required this.onRemove,
  });

  final int index;
  final ItineraryStop stop;
  final bool isLast;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final leg = stop.leg.chosen;
    final place = stop.place;
    final reason = l10n.cardReason(stop.scored);
    final departAt = stop.arrival.subtract(Duration(minutes: stop.leg.minutes));

    String travelTitle() {
      if (leg == null) return '';
      final journey = leg.journey;
      final via = switch (leg.mode) {
        TransportMode.bus when journey != null => l10n.departVia(journey.rides.map((r) => r.route.id).join(' → ')),
        TransportMode.walk => l10n.walkFor(l10n.duration(leg.durationMinutes)),
        _ => '${l10n.transportMode(leg.mode.name)} · ${l10n.duration(leg.durationMinutes)}',
      };
      return '${l10n.time(departAt)} · $via';
    }

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline rail.
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    Expanded(child: Container(width: 2, color: theme.colorScheme.outlineVariant)),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: place.category.color,
                      child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Colors.white)),
                    ),
                    Expanded(
                        child: Container(width: 2, color: isLast ? Colors.transparent : theme.colorScheme.outlineVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (leg != null) ...[
                        InkWell(
                          onTap: () => _showLegOptions(context),
                          child: Text(travelTitle(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          [
                            if (stop.leg.avoiding != null) l10n.avoids(stop.leg.avoiding!.title),
                            if (leg.mode != TransportMode.walk) l10n.fare(leg.fare),
                          ].join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (stop.leg.isRerouted)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TagChip(l10n.tagRerouted,
                                color: AppTheme.alertColor, background: AppTheme.alertBackground),
                          ),
                        const SizedBox(height: 10),
                      ],
                      InkWell(
                        onTap: () => PlaceDetailScreen.open(context, place.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${l10n.time(stop.visitStart)} · ${place.displayName(l10n.localeName)}',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            Text(
                              [
                                l10n.visitWindow(l10n.time(stop.visitStart), l10n.time(stop.departure)),
                                if (stop.waitMinutes > 0) l10n.waitForOpening(stop.waitMinutes),
                              ].join(' · '),
                              style: theme.textTheme.bodySmall,
                            ),
                            if (stop.note != null && stop.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(stop.note!, style: theme.textTheme.bodyMedium),
                              ),
                            for (final e in stop.nearbyEvents)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(l10n.optionalEventNearby(e.title), style: theme.textTheme.bodySmall),
                              ),
                            if (reason.isNotEmpty && stop.note == null) ...[
                              const SizedBox(height: 4),
                              ReasonLine(text: reason, positive: stop.scored.isAvailable),
                            ],
                            for (final w in stop.warnings) ...[
                              const SizedBox(height: 4),
                              ReasonLine(text: l10n.stopWarning(w), positive: false),
                            ],
                            if (stop.nearbyEvents.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: TagChip(l10n.tagEvent,
                                    color: AppTheme.eventColor, background: AppTheme.eventBackground),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(tooltip: l10n.removeStop, icon: const Icon(Icons.close, size: 20), onPressed: onRemove),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.drag_handle)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLegOptions(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.gettingThere, style: Theme.of(context).textTheme.titleMedium),
              Text(l10n.fromPlaceTo(stop.place.name), style: Theme.of(context).textTheme.bodySmall),
              TransportOptionsList(options: stop.leg.options, suggested: stop.leg.chosen),
            ],
          ),
        ),
      ),
    );
  }
}
