import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo_point.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../location/application/location_providers.dart';
import '../../location/domain/start_presets.dart';
import '../../location/presentation/location_picker.dart';
import '../../map/presentation/map_screen.dart';
import '../../profile/application/preferences_controller.dart';
import '../application/transport_providers.dart';
import '../domain/journey_planner.dart';
import '../domain/transport_option.dart';
import 'fare_check_screen.dart';
import 'journey_card.dart';
import 'transport_options_list.dart';

/// Destination set from elsewhere (search, a place page) before switching
/// to the Transit tab.
final transitDestinationProvider = NotifierProvider<TransitDestination, LocationChoice?>(TransitDestination.new);

class TransitDestination extends Notifier<LocationChoice?> {
  @override
  LocationChoice? build() => null;

  void set(LocationChoice? choice) => state = choice;
}

class TransitScreen extends ConsumerStatefulWidget {
  const TransitScreen({super.key});

  @override
  ConsumerState<TransitScreen> createState() => _TransitScreenState();
}

class _TransitScreenState extends ConsumerState<TransitScreen> {
  LocationChoice? _from;

  LocationChoice _defaultFrom() {
    final here = ref.read(userLocationProvider);
    if (here != null) return LocationChoice(context.l10n.myLocation, here, LocationKind.myLocation);
    return LocationChoice(context.l10n.presetThamel, StartPreset.thamel.location, LocationKind.hub);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final from = _from ?? _defaultFrom();
    final to = ref.watch(transitDestinationProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ScreenHeader(
              icon: Icons.route,
              title: l10n.findYourRoute,
              color: AppTheme.seed,
              background: AppTheme.transitBackground,
              action: IconButton(
                tooltip: l10n.fareCheck,
                icon: const Icon(Icons.confirmation_number_outlined),
                onPressed: () => FareCheckScreen.open(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        PickerField(
                          value: from.label,
                          hint: l10n.fromHint,
                          dotColor: const Color(0xFF5B9A2E),
                          onTap: () async {
                            final c = await showLocationPicker(context, title: l10n.fromHint);
                            if (c != null) setState(() => _from = c);
                          },
                        ),
                        const SizedBox(height: 8),
                        PickerField(
                          value: to?.label,
                          hint: l10n.whereTo,
                          dotColor: const Color(0xFFE0483C),
                          onTap: () async {
                            final c = await showLocationPicker(context, title: l10n.whereTo);
                            if (c != null) ref.read(transitDestinationProvider.notifier).set(c);
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.swap,
                    icon: const Icon(Icons.swap_vert),
                    onPressed: to == null
                        ? null
                        : () {
                            setState(() => _from = to);
                            ref.read(transitDestinationProvider.notifier).set(from);
                          },
                  ),
                ],
              ),
            ),
            if (to == null) const _Suggestions() else _Results(from: from, to: to),
          ],
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.from, required this.to});
  final LocationChoice from;
  final LocationChoice to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final estimator = ref.watch(fareEstimatorProvider).value;
    if (estimator == null) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    final now = ref.watch(nowProvider);
    final alerts = ref.watch(alertsProvider);
    final style = ref.watch(preferencesProvider.select((p) => p.travelStyle));

    final groups = JourneyGroup.group(estimator.journeys.plan(from.point, to.point, now, maxResults: 8)).take(3).toList();
    final journeys = [for (final g in groups) g.best];
    final others = [
      for (final o in estimator.optionsFor(from.point, to.point, now, alerts: alerts))
        if (o.mode != TransportMode.bus || o.journey == null) o,
    ];
    final onPath = [
      for (final a in alerts)
        if (a.type.affectsRoads && a.isActiveAt(now) && a.liesOnPath(from.point, to.point)) a,
    ];

    void showMap([int index = 0]) => MapScreen.open(
          context,
          from: from.point,
          to: to.point,
          journey: journeys.isEmpty ? null : journeys[index],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in onPath)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SoftCard(
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppTheme.alertColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.disruptionOnRoute(a.title))),
                ],
              ),
            ),
          ),
        if (journeys.isNotEmpty) ...[
          SectionLabel(l10n.bestOption,
              trailing: TextButton.icon(
                  onPressed: showMap, icon: const Icon(Icons.map_outlined, size: 18), label: Text(l10n.tabMap))),
          for (final (i, g) in groups.indexed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: JourneyCard(journey: g.best, group: g, isBest: i == 0, onShowMap: () => showMap(i)),
            ),
        ] else
          Padding(padding: const EdgeInsets.all(16), child: Text(l10n.noBusRoute)),
        SectionLabel(l10n.otherWays),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TransportOptionsList(options: others, suggested: estimator.recommend(others, style)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(l10n.transitDisclaimer, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final network = ref.watch(routeNetworkProvider).value;
    if (network == null) return const SizedBox.shrink();
    final hubs = [for (final h in network.hubs) if (h.stop != null) h];
    final seen = <String>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l10n.popularHubs),
        for (final h in hubs)
          if (seen.add(h.stop!.id))
            ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: Text(h.name),
              subtitle: Text(h.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => ref
                  .read(transitDestinationProvider.notifier)
                  .set(LocationChoice(h.stop!.name, h.stop!.location, LocationKind.hub)),
            ),
        SectionLabel(l10n.rideHailing),
        for (final o in network.operators)
          ListTile(
            dense: true,
            leading: Icon(o.modes.toLowerCase().contains('bike') ? Icons.two_wheeler : Icons.local_taxi),
            title: Text(o.name),
            subtitle: Text([o.modes, o.pricing, if (o.fareInfo != '—') o.fareInfo].join(' · ')),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(l10n.networkSource(network.routes.length, network.stops.length),
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

/// Helper for other screens: set a destination and switch to Transit.
LocationChoice destinationFor(String label, GeoPoint point) => LocationChoice(label, point, LocationKind.place);
