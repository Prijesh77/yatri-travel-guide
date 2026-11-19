import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/kathmandu_time.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../location/application/location_providers.dart';
import '../../places/application/places_providers.dart';
import '../../places/presentation/category_filter_bar.dart';
import '../../places/presentation/place_detail_screen.dart';
import '../../places/presentation/place_widgets.dart';
import '../../planned/presentation/planned_category_screen.dart';
import '../../profile/application/preferences_controller.dart';
import '../../places/domain/place_category.dart';
import '../../recommendations/domain/scored_place.dart';
import '../../recommendations/application/recommendation_providers.dart';
import '../../search/presentation/search_screen.dart';
import '../../stays/presentation/stays_screen.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/presentation/weather_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _collapsedCount = 8;
  bool _showAll = false;

  Future<void> _refresh() async {
    ref.read(nowProvider.notifier).refresh();
    ref.invalidate(weatherProvider);
    ref.invalidate(deviceLocationProvider);
    try {
      await ref.read(weatherProvider.future);
    } catch (_) {
      // The weather card shows the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recommendations = ref.watch(homeRecommendationsProvider);
    final category = ref.watch(selectedCategoryProvider);
    final visitor = ref.watch(preferencesProvider.select((p) => p.visitorType));
    final alerts = ref.watch(activeAlertsProvider);
    final disruptions = alerts.where((a) => a.type.isDisruption).length;
    final events = alerts.where((a) => a.isEvent).length;
    void goTo(RootTab tab) => ref.read(rootTabProvider.notifier).select(tab);

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Hero(locationLabel: _locationLabel(context))),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _AiCta(onTap: () => goTo(RootTab.plan))),
              ),
              SliverToBoxAdapter(child: SectionLabel(l10n.rightNow)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatusTile(
                            icon: disruptions == 0 ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                            label: l10n.disruptionsCount(disruptions),
                            color: disruptions == 0 ? context.yatri.event : context.yatri.alert,
                            background: disruptions == 0 ? context.yatri.eventContainer : context.yatri.alertContainer,
                            onTap: () => goTo(RootTab.alerts),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatusTile(
                            icon: Icons.celebration_outlined,
                            label: l10n.eventsToday(events),
                            color: events == 0 ? context.yatri.planned : context.yatri.ai,
                            background: events == 0 ? context.yatri.plannedContainer : context.yatri.aiContainer,
                            onTap: () => goTo(RootTab.alerts),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SectionLabel(l10n.explore)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _ExploreTile(
                          icon: Icons.directions_bus_filled_outlined,
                          label: l10n.catTransport,
                          hint: l10n.catTransportHint,
                          onTap: () => goTo(RootTab.transit),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ExploreTile(
                          icon: Icons.bed_outlined,
                          label: l10n.catStays,
                          hint: l10n.catStaysHint,
                          onTap: () => StaysScreen.open(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (final c in PlannedCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              height: 40,
                              child: _SoonChip(
                                icon: c.icon,
                                label: l10n.plannedCategory(c.name),
                                onTap: () => PlannedCategoryScreen.open(context, c),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SectionLabel(l10n.goodForToday)),
              SliverToBoxAdapter(
                child: CategoryFilterBar(
                  selected: category,
                  onSelected: (c) {
                    ref.read(selectedCategoryProvider.notifier).select(c);
                    setState(() => _showAll = false);
                  },
                ),
              ),
              ...switch (recommendations) {
                AsyncValue(:final value?) when value.isEmpty => [
                    SliverToBoxAdapter(
                      child: _EmptyState(icon: Icons.search_off, text: l10n.noPlacesMatch),
                    ),
                  ],
                AsyncValue(:final value?) => _placeSlivers(context, value, visitor),
                AsyncError(:final error) => [
                    SliverToBoxAdapter(
                      child: _EmptyState(icon: Icons.error_outline, text: '${l10n.errorLoading}\n$error'),
                    ),
                  ],
                _ => [
                    const SliverToBoxAdapter(
                      child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                    ),
                  ],
              },
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _placeSlivers(BuildContext context, List<ScoredPlace> value, VisitorType visitor) {
    final l10n = context.l10n;
    // Feature the best place only when it can actually be visited now.
    final featured = value.first.isAvailable ? value.first : null;
    final rest = featured == null ? value : value.sublist(1);
    final shown = _showAll ? rest.length : rest.length.clamp(0, _collapsedCount);
    return [
      if (featured != null)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FeaturedPlaceCard(
                  scored: featured,
                  visitorFee: featured.place.entryFee.forVisitor(visitor),
                  onTap: () => PlaceDetailScreen.open(context, featured.place.id),
                ),
                if (rest.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 2),
                    child: Text(l10n.moreForToday,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList.separated(
          itemCount: shown,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => PlaceCard(
            scored: rest[i],
            visitorFee: rest[i].place.entryFee.forVisitor(visitor),
            onTap: () => PlaceDetailScreen.open(context, rest[i].place.id),
          ),
        ),
      ),
      if (rest.length > _collapsedCount)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showAll = !_showAll),
              icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
              label: Text(_showAll ? l10n.showFewer : l10n.showAll(value.length)),
            ),
          ),
        ),
    ];
  }

  /// City of the nearest attraction to the user, else the valley.
  String _locationLabel(BuildContext context) {
    final l10n = context.l10n;
    final here = ref.watch(userLocationProvider);
    final places = ref.watch(placesProvider).value;
    if (here == null || places == null || places.isEmpty) return l10n.weatherValley;
    final nearest = places.reduce((a, b) => a.location.distanceKmTo(here) <= b.location.distanceKmTo(here) ? a : b);
    return l10n.cityName(nearest.city.name);
  }
}

/// Gradient header: brand, greeting, location, weather and search.
class _Hero extends ConsumerWidget {
  const _Hero({required this.locationLabel});
  final String locationLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final y = context.yatri;
    final now = ref.watch(nowProvider);
    final muted = Colors.white.withValues(alpha: 0.8);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [y.heroStart, y.heroEnd],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Faint mountain silhouette, a nod to the valley skyline.
          Positioned(
            right: -30,
            top: 10,
            child: Icon(Icons.landscape, size: 200, color: Colors.white.withValues(alpha: 0.06)),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.explore, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.appTitle,
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(
                        tooltip: l10n.search,
                        color: Colors.white,
                        icon: const Icon(Icons.search),
                        onPressed: () => SearchScreen.open(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.greeting(DayPart.of(now).name),
                            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 15, color: muted),
                            const SizedBox(width: 4),
                            Text(locationLabel, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const HeroWeather(),
                        const SizedBox(height: 16),
                        Material(
                          color: theme.colorScheme.surfaceContainerLowest,
                          shape: const StadiumBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => SearchScreen.open(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.searchHint,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _AiCta extends StatelessWidget {
  const _AiCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final y = context.yatri;
    return Material(
      color: y.aiContainer,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: y.ai, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.auto_awesome, color: y.aiContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.planTripWithAi, style: theme.textTheme.titleMedium?.copyWith(color: y.ai)),
                    const SizedBox(height: 2),
                    Text(l10n.budgetConditionAware,
                        style: theme.textTheme.bodySmall?.copyWith(color: y.ai.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: y.ai),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({required this.icon, required this.label, required this.hint, required this.onTap});
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final y = context.yatri;
    return Material(
      color: y.transitContainer,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: y.transit),
              ),
              const SizedBox(height: 12),
              Text(label, style: theme.textTheme.titleMedium?.copyWith(color: y.transit)),
              const SizedBox(height: 2),
              Text(hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: y.transit.withValues(alpha: 0.8))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact chip for categories that are not built yet.
class _SoonChip extends StatelessWidget {
  const _SoonChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final y = context.yatri;
    return Material(
      color: y.plannedContainer,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: y.planned),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.labelLarge?.copyWith(color: y.planned)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(context.l10n.soon,
                    style: theme.textTheme.labelSmall?.copyWith(color: y.planned, fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
