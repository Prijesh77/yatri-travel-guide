import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../location/application/location_providers.dart';
import '../../places/application/places_providers.dart';
import '../../places/presentation/category_filter_bar.dart';
import '../../places/presentation/place_detail_screen.dart';
import '../../places/presentation/place_widgets.dart';
import '../../planned/presentation/planned_category_screen.dart';
import '../../profile/application/preferences_controller.dart';
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
    final theme = Theme.of(context);
    final recommendations = ref.watch(homeRecommendationsProvider);
    final category = ref.watch(selectedCategoryProvider);
    final visitor = ref.watch(preferencesProvider.select((p) => p.visitorType));
    final alerts = ref.watch(activeAlertsProvider);
    final disruptions = alerts.where((a) => a.type.isDisruption).length;
    final events = alerts.where((a) => a.isEvent).length;
    void goTo(RootTab tab) => ref.read(rootTabProvider.notifier).select(tab);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.appTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 16),
                                const SizedBox(width: 4),
                                Text(_locationLabel(context), style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.search,
                        icon: const Icon(Icons.search),
                        onPressed: () => SearchScreen.open(context),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverList.list(
                  children: [
                    InkWell(
                      onTap: () => SearchScreen.open(context),
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Text(l10n.searchHint,
                            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: AppTheme.aiBackground,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        leading: const Icon(Icons.auto_awesome, color: AppTheme.aiColor),
                        title: Text(l10n.planTripWithAi,
                            style: const TextStyle(color: AppTheme.aiColor, fontWeight: FontWeight.w700)),
                        subtitle: Text(l10n.budgetConditionAware, style: const TextStyle(color: AppTheme.aiColor)),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.aiColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onTap: () => goTo(RootTab.plan),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: SectionLabel(l10n.categories)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.3,
                  children: [
                    _CategoryTile(icon: Icons.route, label: l10n.catTransport, active: true, onTap: () => goTo(RootTab.transit)),
                    _CategoryTile(icon: Icons.bed_outlined, label: l10n.catStays, active: true, onTap: () => StaysScreen.open(context)),
                    for (final c in PlannedCategory.values)
                      _CategoryTile(
                        icon: c.icon,
                        label: l10n.plannedCategory(c.name),
                        active: false,
                        onTap: () => PlannedCategoryScreen.open(context, c),
                      ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: SectionLabel(l10n.rightNow)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.alertColor),
                        backgroundColor: AppTheme.alertBackground,
                        side: BorderSide.none,
                        label: Text(l10n.disruptionsCount(disruptions), style: const TextStyle(color: AppTheme.alertColor)),
                        onPressed: () => goTo(RootTab.alerts),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.event, size: 16, color: AppTheme.eventColor),
                        backgroundColor: AppTheme.eventBackground,
                        side: BorderSide.none,
                        label: Text(l10n.eventsToday(events), style: const TextStyle(color: AppTheme.eventColor)),
                        onPressed: () => goTo(RootTab.alerts),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: WeatherCard()),
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
                      child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noPlacesMatch)),
                    ),
                  ],
                AsyncValue(:final value?) => [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverList.separated(
                        itemCount: _showAll ? value.length : value.length.clamp(0, _collapsedCount),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => PlaceCard(
                          scored: value[i],
                          visitorFee: value[i].place.entryFee.forVisitor(visitor),
                          onTap: () => PlaceDetailScreen.open(context, value[i].place.id),
                        ),
                      ),
                    ),
                    if (value.length > _collapsedCount)
                      SliverToBoxAdapter(
                        child: Center(
                          child: TextButton(
                            onPressed: () => setState(() => _showAll = !_showAll),
                            child: Text(_showAll ? l10n.showFewer : l10n.showAll(value.length)),
                          ),
                        ),
                      ),
                  ],
                AsyncError(:final error) => [
                    SliverToBoxAdapter(
                      child: Padding(padding: const EdgeInsets.all(24), child: Text('${l10n.errorLoading}\n$error')),
                    ),
                  ],
                _ => [
                    const SliverToBoxAdapter(
                      child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                    ),
                  ],
              },
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.seed : AppTheme.plannedColor;
    return Material(
      color: active ? AppTheme.transitBackground : AppTheme.plannedBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
