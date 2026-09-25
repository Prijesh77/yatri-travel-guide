import 'package:flutter/material.dart';

import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../recommendations/domain/scored_place.dart';
import '../domain/place_category.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar(this.category, {super.key, this.size = 44});
  final PlaceCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size / 3.5),
      ),
      child: Icon(category.icon, color: category.color, size: size * 0.55),
    );
  }
}

/// Icon + text line explaining a score, coloured by whether it helps.
class ReasonLine extends StatelessWidget {
  const ReasonLine({super.key, required this.text, required this.positive, this.maxLines = 2});
  final String text;
  final bool positive;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = positive ? const Color(0xFF2E7D32) : scheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(positive ? Icons.check_circle_outline : Icons.info_outline, size: 16, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface),
          ),
        ),
      ],
    );
  }
}

class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.scored, required this.visitorFee, this.onTap});

  final ScoredPlace scored;
  final int visitorFee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final place = scored.place;
    final meta = [
      l10n.cityName(place.city.name),
      l10n.categoryName(place.category.name),
      if (scored.distanceKm != null) l10n.distance(scored.distanceKm!),
    ].join(' · ');
    final reasonText = l10n.cardReason(scored);
    final warning = scored.isAvailable ? scored.warning : null;

    return Opacity(
      opacity: scored.isAvailable ? 1 : 0.6,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryAvatar(place.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.displayName(l10n.localeName), style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(meta, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      if (reasonText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ReasonLine(text: reasonText, positive: scored.isAvailable),
                      ],
                      if (warning != null) ...[
                        const SizedBox(height: 4),
                        ReasonLine(text: l10n.reason(warning), positive: false, maxLines: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(l10n.fee(visitorFee), style: theme.textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SuitabilityBadge extends StatelessWidget {
  const SuitabilityBadge({super.key, required this.suitability, required this.label});
  final Suitability suitability;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = suitability.color(Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(suitability.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color)),
        ],
      ),
    );
  }
}
