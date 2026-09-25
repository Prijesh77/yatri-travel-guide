import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation.dart';
import '../../location/presentation/location_picker.dart';
import '../../map/presentation/map_screen.dart';
import '../../profile/application/saved_controller.dart';
import '../../transport/presentation/transit_screen.dart';
import '../../../core/geo/geo_point.dart';
import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../itinerary/application/itinerary_controller.dart';
import '../../location/application/location_providers.dart';
import '../../location/domain/start_presets.dart';
import '../../profile/application/preferences_controller.dart';
import '../../recommendations/application/recommendation_providers.dart';
import '../../recommendations/domain/scored_place.dart';
import '../../transport/application/transport_providers.dart';
import '../../transport/presentation/transport_options_list.dart';
import '../application/places_providers.dart';
import '../domain/opening_hours.dart';
import '../domain/place.dart';
import '../domain/place_category.dart';
import 'place_widgets.dart';

class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({super.key, required this.placeId});

  final String placeId;

  static Future<void> open(BuildContext context, String placeId) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(placeId: placeId)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(placeByIdProvider(placeId));
    final scored = ref.watch(scoredPlaceProvider(placeId));
    final l10n = context.l10n;
    if (place == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(l10n.errorLoading)));
    }

    final savedItem = SavedItem(SavedKind.place, place.id);
    final saved = ref.watch(savedProvider).contains(savedItem);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            actions: [
              IconButton(
                tooltip: saved ? l10n.unsave : l10n.save,
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () => ref.read(savedProvider.notifier).toggle(savedItem),
              ),
            ],
            expandedHeight: 220,
            // Category colour when collapsed too, so the white title and
            // back button stay readable.
            backgroundColor: Color.lerp(place.category.color, Colors.black, 0.3),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                place.displayName(l10n.localeName),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 6, color: Colors.black45)]),
              ),
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16, end: 16),
              background: _PhotoPlaceholder(place: place),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(avatar: const Icon(Icons.place, size: 18), label: Text(l10n.cityName(place.city.name))),
                    Chip(
                      avatar: Icon(place.category.icon, size: 18, color: place.category.color),
                      label: Text(l10n.categoryName(place.category.name)),
                    ),
                    Chip(
                      avatar: Icon(place.isIndoor ? Icons.roofing : Icons.wb_sunny_outlined, size: 18),
                      label: Text(l10n.settingName(place.setting.name)),
                    ),
                  ],
                ),
                if (scored != null) ...[const SizedBox(height: 16), _SuitabilityCard(scored: scored)],
                const SizedBox(height: 20),
                _SectionTitle(l10n.aboutSection),
                Text(place.description, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 20),
                _InfoSection(place: place),
                const SizedBox(height: 20),
                _GettingThere(place: place),
                const SizedBox(height: 88),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: l10n.showOnMap,
                icon: const Icon(Icons.map_outlined),
                onPressed: () => MapScreen.open(context, focus: [place.location]),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.route),
                label: Text(l10n.routeHere),
                onPressed: () {
                  ref
                      .read(transitDestinationProvider.notifier)
                      .set(LocationChoice(place.name, place.location, LocationKind.place));
                  ref.read(rootTabProvider.notifier).select(RootTab.transit);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.playlist_add),
                  label: Text(l10n.addToItinerary),
                  onPressed: () => _addToItinerary(context, ref, place),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToItinerary(BuildContext context, WidgetRef ref, Place place) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await ref.read(itineraryControllerProvider.notifier).add(place);
    messenger.showSnackBar(SnackBar(
      content: Text(result == AddResult.added ? l10n.addedToItinerary : l10n.alreadyInItinerary),
      action: SnackBarAction(
        label: l10n.viewPlan,
        onPressed: () {
          ref.read(rootTabProvider.notifier).select(RootTab.plan);
          navigator.popUntil((r) => r.isFirst);
        },
      ),
    ));
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final color = place.category.color;
    // TODO(images): show place.imageUrl with caching once photos are sourced.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.45)!],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 20,
            child: Icon(place.category.icon, size: 180, color: Colors.white.withValues(alpha: 0.15)),
          ),
          Positioned(
            right: 16,
            top: 56,
            child: Row(
              children: [
                const Icon(Icons.photo_camera_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(context.l10n.photosComingSoon, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _SuitabilityCard extends StatelessWidget {
  const _SuitabilityCard({required this.scored});
  final ScoredPlace scored;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SuitabilityBadge(suitability: scored.suitability, label: l10n.suitability(scored.suitability.name)),
            const SizedBox(height: 12),
            for (final r in scored.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ReasonLine(text: l10n.reason(r), positive: r.isPositive),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends ConsumerWidget {
  const _InfoSection({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = ref.watch(nowProvider);
    final visitor = ref.watch(preferencesProvider.select((p) => p.visitorType));
    final hours = place.openingHours;
    final status = hours.statusAt(now);

    final statusText = switch (status.state) {
      OpenState.open when hours.alwaysOpen => l10n.openNow,
      OpenState.open => l10n.openNowClosesAt(l10n.minuteOfDayTime(status.closesAt!)),
      OpenState.opensLater => l10n.opensAtToday(l10n.minuteOfDayTime(status.opensAt!)),
      OpenState.closedForDay => l10n.closedNowStatus,
      OpenState.closedToday => l10n.closedTodayStatus,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.openingHoursLabel),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hours.alwaysOpen
                      ? l10n.openAllDay
                      : l10n.hoursRange(l10n.minuteOfDayTime(hours.openMinute), l10n.minuteOfDayTime(hours.closeMinute))),
                  if (hours.closedWeekdays.isNotEmpty) Text(l10n.closedOnDays(l10n.weekdays(hours.closedWeekdays))),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: status.isOpen ? const Color(0xFF2E7D32) : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: Text(l10n.typicalVisit),
              subtitle: Text(l10n.duration(place.visitMinutes)),
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number_outlined),
              title: Text(l10n.entryFee),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final v in VisitorType.values)
                    Text(
                      '${l10n.visitorFee(v.name)}: ${l10n.fee(place.entryFee.forVisitor(v))}',
                      style: v == visitor ? const TextStyle(fontWeight: FontWeight.w700) : null,
                    ),
                  const SizedBox(height: 4),
                  Text(l10n.feesApproximate, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GettingThere extends ConsumerWidget {
  const _GettingThere({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final estimator = ref.watch(fareEstimatorProvider).value;
    if (estimator == null) return const SizedBox.shrink();
    final here = ref.watch(userLocationProvider);
    final style = ref.watch(preferencesProvider.select((p) => p.travelStyle));
    final now = ref.watch(nowProvider);
    final GeoPoint from = here ?? StartPreset.thamel.location;
    final options = estimator.optionsFor(from, place.location, now);
    final suggested = estimator.recommend(options, style);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.gettingThere),
        Text(
          here != null ? l10n.fromYourLocation : l10n.fromPlace(l10n.preset(StartPreset.thamel)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TransportOptionsList(options: options, suggested: suggested),
        Text(l10n.transportDisclaimer, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
