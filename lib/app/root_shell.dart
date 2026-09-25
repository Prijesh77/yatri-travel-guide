import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presentation/l10n.dart';
import '../features/alerts/application/alerts_providers.dart';
import '../features/alerts/presentation/live_conditions_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/itinerary/presentation/plan_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/transport/presentation/transit_screen.dart';
import 'navigation.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  /// Tabs are built on first visit and then kept alive.
  final _visited = <RootTab>{RootTab.home};

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(rootTabProvider);
    _visited.add(tab);
    final l10n = context.l10n;
    final disruptions = ref.watch(activeAlertsProvider).where((a) => a.type.isDisruption).length;

    Widget page(RootTab t, Widget child) => _visited.contains(t) ? child : const SizedBox.shrink();

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: [
          page(RootTab.home, const HomeScreen()),
          page(RootTab.transit, const TransitScreen()),
          page(RootTab.alerts, const LiveConditionsScreen()),
          page(RootTab.plan, const PlanScreen()),
          page(RootTab.profile, const ProfileScreen()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) => ref.read(rootTabProvider.notifier).select(RootTab.values[i]),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.tabHome),
          NavigationDestination(icon: const Icon(Icons.route_outlined), selectedIcon: const Icon(Icons.route), label: l10n.tabTransit),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: disruptions > 0,
              label: Text('$disruptions'),
              child: const Icon(Icons.warning_amber_outlined),
            ),
            selectedIcon: const Icon(Icons.warning_amber),
            label: l10n.tabAlerts,
          ),
          NavigationDestination(icon: const Icon(Icons.auto_awesome_outlined), selectedIcon: const Icon(Icons.auto_awesome), label: l10n.tabPlan),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.tabProfile),
        ],
      ),
    );
  }
}
