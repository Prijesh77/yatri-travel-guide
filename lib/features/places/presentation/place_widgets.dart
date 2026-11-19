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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = dark ? Color.lerp(category.color, Colors.white, 0.35)! : category.color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.22), c.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(size / 3.2),
      ),
      child: Icon(category.icon, color: c, size: size * 0.5),
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
    final color = positive ? context.yatri.success : scheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(positive ? Icons.check_circle : Icons.info_outline, size: 15, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface, height: 1.3),
          ),
        ),
      ],
    );
  }
}

/// Small rounded fee label ("NPR 400", "Free").
class FeeTag extends StatelessWidget {
  const FeeTag(this.text, {super.key, this.free = false});
  final String text;
  final bool free;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final y = context.yatri;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: free ? y.eventContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: free ? y.event : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
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
                CategoryAvatar(place.category, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(place.displayName(l10n.localeName),
                                style: theme.textTheme.titleMedium?.copyWith(height: 1.25)),
                          ),
                          const SizedBox(width: 8),
                          FeeTag(l10n.fee(visitorFee), free: visitorFee == 0),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(meta, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      if (reasonText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ReasonLine(text: reasonText, positive: scored.isAvailable),
                      ],
                      if (warning != null) ...[
                        const SizedBox(height: 4),
                        ReasonLine(text: l10n.reason(warning), positive: false, maxLines: 1),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Large card for the best-scoring place on Home.
class FeaturedPlaceCard extends StatelessWidget {
  const FeaturedPlaceCard({super.key, required this.scored, required this.visitorFee, this.onTap});

  final ScoredPlace scored;
  final int visitorFee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final place = scored.place;
    final c = place.category.color;
    final reasonText = l10n.cardReason(scored);
    final meta = [
      l10n.cityName(place.city.name),
      l10n.categoryName(place.category.name),
      if (scored.distanceKm != null) l10n.distance(scored.distanceKm!),
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 112,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c, Color.lerp(c, Colors.black, 0.35)!],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    bottom: -26,
                    child: Icon(place.category.icon, size: 150, color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(scored.suitability.icon, size: 14, color: scored.suitability.color(theme.colorScheme)),
                          const SizedBox(width: 5),
                          Text(
                            l10n.suitability(scored.suitability.name),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Text(
                      place.displayName(l10n.localeName),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(meta,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                      FeeTag(l10n.fee(visitorFee), free: visitorFee == 0),
                    ],
                  ),
                  if (reasonText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ReasonLine(text: reasonText, positive: scored.isAvailable),
                  ],
                ],
              ),
            ),
          ],
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
