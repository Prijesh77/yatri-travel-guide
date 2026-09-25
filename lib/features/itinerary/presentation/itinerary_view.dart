import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/navigation.dart';
import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../places/presentation/place_detail_screen.dart';
import '../../places/presentation/place_widgets.dart';
import '../../profile/application/preferences_controller.dart';
import '../../transport/presentation/transport_options_list.dart';
import '../../weather/application/weather_providers.dart';
import '../application/itinerary_controller.dart';
import '../domain/itinerary.dart';

class ItineraryView extends ConsumerWidget {
  const ItineraryView({super.key, required this.itinerary});
  final Itinerary itinerary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(itineraryControllerProvider.notifier);

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      buildDefaultDragHandles: false,
      header: _Header(itinerary: itinerary),
      footer: itinerary.isEmpty
          ? Padding(padding: const EdgeInsets.all(24), child: Text(l10n.emptyItinerary, textAlign: TextAlign.center))
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.transportDisclaimer, style: Theme.of(context).textTheme.bodySmall),
            ),
      itemCount: itinerary.stops.length,
      onReorderItem: controller.move,
      itemBuilder: (context, i) {
        final stop = itinerary.stops[i];
        return Padding(
          key: ValueKey(stop.place.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: _StopCard(
            index: i,
            stop: stop,
            previousLabel: i == 0 ? l10n.startLabel(itinerary.request.start) : itinerary.stops[i - 1].place.name,
            onRemove: () {
              controller.removeAt(i);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(l10n.stopRemoved(stop.place.name)),
                  action: SnackBarAction(label: l10n.undo, onPressed: () => controller.insertAt(i, stop.place)),
                ));
            },
          ),
        );
      },
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.itinerary});
  final Itinerary itinerary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visitor = ref.watch(preferencesProvider.select((p) => p.visitorType));
    final day = ref.watch(weatherOrNullProvider)?.dayOf(itinerary.request.startTime);
    final controller = ref.read(itineraryControllerProvider.notifier);
    final r = itinerary.request;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat.MMMMEEEEd(l10n.localeName).format(r.startTime), style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(l10n.itinerarySummary(itinerary.stops.length, l10n.time(r.startTime), l10n.time(itinerary.endTime))),
              Text(l10n.startPoint(l10n.startLabel(r.start)), style: theme.textTheme.bodySmall),
              if (!itinerary.isEmpty) ...[
                const SizedBox(height: 8),
                Text(l10n.travelTime(l10n.duration(itinerary.totalTravelMinutes))),
                Text(l10n.itineraryCosts(l10n.fare(itinerary.transportCost), l10n.fee(itinerary.entryFees(visitor)))),
              ],
              if (day != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(day.condition.icon(), size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(l10n.dayForecast(
                          l10n.weatherCondition(day.condition.name), day.minC.round(), day.maxC.round())),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (itinerary.stops.length > 2)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.route),
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
                      icon: const Icon(Icons.map_outlined),
                      label: Text(l10n.showRouteOnMap),
                      onPressed: () => ref.read(mapFocusProvider.notifier).focus(MapFocusRequest(
                            [r.start.location, for (final s in itinerary.stops) s.place.location],
                            showPlan: true,
                          )),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.clearPlan),
                    onPressed: controller.clear,
                  ),
                ],
              ),
              if (itinerary.stops.length > 1) ...[
                const SizedBox(height: 4),
                Text(l10n.reorderHint, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.index, required this.stop, required this.previousLabel, required this.onRemove});

  final int index;
  final ItineraryStop stop;
  final String previousLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final place = stop.place;
    final leg = stop.leg.chosen;
    final reasonText = l10n.cardReason(stop.scored);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leg != null)
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                dense: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Icon(leg.mode.icon, size: 20),
                title: Text(
                  '${l10n.transportMode(leg.mode.name)} · ${l10n.duration(leg.durationMinutes)} · ${l10n.fare(leg.fare)}',
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: Text(l10n.fromPlace(previousLabel), maxLines: 1, overflow: TextOverflow.ellipsis),
                children: [TransportOptionsList(options: stop.leg.options, suggested: leg, dense: true)],
              ),
            ),
          const Divider(height: 1),
          InkWell(
            onTap: () => PlaceDetailScreen.open(context, place.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: place.category.color,
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.displayName(l10n.localeName), style: theme.textTheme.titleMedium),
                        Text(
                          '${l10n.visitWindow(l10n.time(stop.visitStart), l10n.time(stop.departure))} · '
                          '${l10n.duration(place.visitMinutes)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (stop.waitMinutes > 0)
                          Text(l10n.waitForOpening(stop.waitMinutes), style: theme.textTheme.bodySmall),
                        if (reasonText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ReasonLine(text: reasonText, positive: stop.scored.isAvailable),
                        ],
                        for (final w in stop.warnings) ...[
                          const SizedBox(height: 4),
                          ReasonLine(text: l10n.stopWarning(w), positive: false),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        tooltip: l10n.removeStop,
                        icon: const Icon(Icons.close),
                        onPressed: onRemove,
                      ),
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
        ],
      ),
    );
  }
}
