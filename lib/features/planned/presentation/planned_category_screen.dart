import 'package:flutter/material.dart';

import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/theme/app_theme.dart';

/// Categories that are wireframe-level only in Phase 1 (screens 8-11).
enum PlannedCategory {
  education(Icons.school_outlined),
  fitness(Icons.fitness_center),
  adventure(Icons.terrain),
  health(Icons.medical_services_outlined);

  const PlannedCategory(this.icon);
  final IconData icon;
}

class PlannedCategoryScreen extends StatelessWidget {
  const PlannedCategoryScreen({super.key, required this.category});
  final PlannedCategory category;

  static Future<void> open(BuildContext context, PlannedCategory category) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => PlannedCategoryScreen(category: category)));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = category.name;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          ScreenHeader(
            icon: category.icon,
            title: l10n.plannedCategory(name),
            color: AppTheme.plannedColor,
            background: AppTheme.plannedBackground,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              enabled: false,
              decoration: InputDecoration(hintText: l10n.plannedSearchHint(name), prefixIcon: const Icon(Icons.search)),
            ),
          ),
          const SizedBox(height: 12),
          for (final (i, label) in [l10n.plannedItemA(name), l10n.plannedItemB(name)].indexed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SoftCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.plannedBackground,
                      child: Icon(category.icon, color: AppTheme.plannedColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${l10n.plannedCategory(name)} ${String.fromCharCode(65 + i)}',
                              style: Theme.of(context).textTheme.titleSmall),
                          Text(label),
                          Text(l10n.detailsComingSoon, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.plannedNote, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
