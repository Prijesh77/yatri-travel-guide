import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../places/domain/place_category.dart';
import '../../transport/domain/transport_option.dart';
import '../application/preferences_controller.dart';

Future<void> showPreferencesSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const PreferencesSheet(),
    );

class PreferencesSheet extends ConsumerWidget {
  const PreferencesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider);
    final controller = ref.read(preferencesProvider.notifier);
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.preferencesTitle, style: text.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.planInterests, style: text.titleSmall),
            Text(l10n.interestsHint, style: text.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in PlaceCategory.values)
                  FilterChip(
                    avatar: Icon(c.icon, size: 18),
                    label: Text(l10n.categoryName(c.name)),
                    selected: prefs.interests.contains(c),
                    onSelected: (_) => controller.toggleInterest(c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.visitorTypeLabel, style: text.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<VisitorType>(
              segments: [
                for (final v in VisitorType.values) ButtonSegment(value: v, label: Text(l10n.visitorFee(v.name))),
              ],
              selected: {prefs.visitorType},
              onSelectionChanged: (s) => controller.setVisitorType(s.single),
            ),
            const SizedBox(height: 20),
            Text(l10n.planTravelStyle, style: text.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TravelStyle>(
              segments: [
                for (final s in TravelStyle.values) ButtonSegment(value: s, label: Text(l10n.travelStyle(s.name))),
              ],
              selected: {prefs.travelStyle},
              onSelectionChanged: (s) => controller.setTravelStyle(s.single),
            ),
            const SizedBox(height: 4),
            Text(l10n.travelStyleHint(prefs.travelStyle.name), style: text.bodySmall),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.done)),
            ),
          ],
        ),
      ),
    );
  }
}
