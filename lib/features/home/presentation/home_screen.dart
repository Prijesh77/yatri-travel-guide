import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/l10n.dart';
import '../../../core/providers/core_providers.dart';
import '../../alerts/presentation/alerts_banner.dart';
import '../../location/application/location_providers.dart';
import '../../places/presentation/category_filter_bar.dart';
import '../../places/presentation/place_detail_screen.dart';
import '../../places/presentation/place_widgets.dart';
import '../../profile/application/preferences_controller.dart';
import '../../profile/presentation/preferences_sheet.dart';
import '../../recommendations/application/recommendation_providers.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/presentation/weather_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _collapsedCount = 12;
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(l10n.appTitle),
              actions: [
                IconButton(
                  tooltip: l10n.preferences,
                  icon: const Icon(Icons.tune),
                  onPressed: () => showPreferencesSheet(context),
                ),
              ],
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Column(children: [WeatherCard(), AlertsBanner(), _LocationHint()]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(l10n.goodForToday, style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
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
    );
  }
}

class _LocationHint extends ConsumerWidget {
  const _LocationHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceLocationProvider);
    if (device.isLoading) return const SizedBox.shrink();
    final l10n = context.l10n;
    final String? message = switch (device.value) {
      null => l10n.locationOff,
      _ when ref.watch(userLocationProvider) == null => l10n.locationOutside,
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.location_off, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
          if (device.value == null)
            TextButton(onPressed: () => ref.invalidate(deviceLocationProvider), child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
