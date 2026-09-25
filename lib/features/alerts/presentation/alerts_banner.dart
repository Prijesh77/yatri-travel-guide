import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/alerts_providers.dart';
import '../domain/condition_alert.dart';

/// Festivals, closures and bandhs affecting today.
class AlertsBanner extends ConsumerWidget {
  const AlertsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(activeAlertsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final a in alerts)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Card(
              color: a.type == AlertType.bandh ? scheme.errorContainer : scheme.tertiaryContainer,
              child: ListTile(
                leading: Icon(switch (a.type) {
                  AlertType.festival => Icons.celebration,
                  AlertType.closure => Icons.block,
                  AlertType.roadClosure => Icons.remove_road,
                  AlertType.bandh => Icons.front_hand,
                }),
                title: Text(a.title),
                subtitle: a.description.isEmpty ? null : Text(a.description),
              ),
            ),
          ),
      ],
    );
  }
}
