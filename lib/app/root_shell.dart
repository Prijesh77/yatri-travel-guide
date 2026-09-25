import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presentation/l10n.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/itinerary/presentation/plan_screen.dart';
import '../features/map/presentation/map_screen.dart';
import 'navigation.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  /// Tabs are built on first visit and then kept alive, so the map does not
  /// download tiles until the user opens it.
  final _visited = <RootTab>{RootTab.explore};

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(rootTabProvider);
    _visited.add(tab);
    final l10n = context.l10n;

    Widget page(RootTab t, Widget child) => _visited.contains(t) ? child : const SizedBox.shrink();

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: [
          page(RootTab.explore, const HomeScreen()),
          page(RootTab.plan, const PlanScreen()),
          page(RootTab.map, const MapScreen()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) => ref.read(rootTabProvider.notifier).select(RootTab.values[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: l10n.tabExplore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note),
            label: l10n.tabPlan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.tabMap,
          ),
        ],
      ),
    );
  }
}
