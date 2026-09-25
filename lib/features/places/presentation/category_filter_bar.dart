import 'package:flutter/material.dart';

import '../../../core/presentation/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/place_category.dart';

/// Horizontal "All / Heritage / Temples / ..." chips.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({super.key, required this.selected, required this.onSelected});

  final PlaceCategory? selected;
  final ValueChanged<PlaceCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(l10n.allCategories),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final c in PlaceCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(c.icon, size: 18, color: selected == c ? null : c.color),
                label: Text(l10n.categoryName(c.name)),
                selected: selected == c,
                onSelected: (on) => onSelected(on ? c : null),
              ),
            ),
        ],
      ),
    );
  }
}
