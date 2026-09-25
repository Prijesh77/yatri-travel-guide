import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation.dart';
import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../location/application/location_providers.dart';
import '../../location/domain/start_presets.dart';
import '../../location/presentation/location_picker.dart';
import '../../map/presentation/map_screen.dart';
import '../../profile/application/preferences_controller.dart';
import '../../profile/application/saved_controller.dart';
import '../../transport/application/transport_providers.dart';
import '../../transport/presentation/transit_screen.dart';
import '../../transport/presentation/transport_options_list.dart';
import '../application/stays_providers.dart';

class StayDetailScreen extends ConsumerWidget {
  const StayDetailScreen({super.key, required this.stayId});
  final String stayId;

  static Future<void> open(BuildContext context, String id) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => StayDetailScreen(stayId: id)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stay = ref.watch(stayByIdProvider(stayId));
    final catalog = ref.watch(staysProvider).value;
    if (stay == null || catalog == null) return Scaffold(appBar: AppBar(), body: Center(child: Text(l10n.errorLoading)));
    final item = SavedItem(SavedKind.stay, stay.id);
    final saved = ref.watch(savedProvider).contains(item);

    final estimator = ref.watch(fareEstimatorProvider).value;
    final here = ref.watch(userLocationProvider);
    final from = here ?? StartPreset.thamel.location;
    final options = estimator?.optionsFor(from, stay.location, ref.watch(nowProvider));
    final style = ref.watch(preferencesProvider.select((p) => p.travelStyle));

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: saved ? l10n.unsave : l10n.save,
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => ref.read(savedProvider.notifier).toggle(item),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(stay.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            TagChip(l10n.stayType(stay.type.name), color: AppTheme.seed, background: AppTheme.transitBackground),
            TagChip(l10n.priceBand(stay.priceBand.name),
                color: theme.colorScheme.onSurfaceVariant, background: theme.colorScheme.surfaceContainerHighest),
          ]),
          const SizedBox(height: 12),
          Text(stay.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: Text('${stay.area} · ${l10n.cityName(stay.city.name)}'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.payments_outlined),
            title: Text(l10n.pricePerNight(catalog.priceRanges[stay.priceBand]!)),
            subtitle: Text(l10n.staysDisclaimer),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.showOnMap),
                onPressed: () => MapScreen.open(context, focus: [stay.location]),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.route),
                label: Text(l10n.routeHere),
                onPressed: () {
                  ref.read(transitDestinationProvider.notifier).set(
                        LocationChoice(stay.name, stay.location, LocationKind.place),
                      );
                  ref.read(rootTabProvider.notifier).select(RootTab.transit);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          ),
          if (options != null) ...[
            const SizedBox(height: 16),
            Text(l10n.gettingThere, style: theme.textTheme.titleMedium),
            Text(here != null ? l10n.fromYourLocation : l10n.fromPlace(l10n.presetThamel), style: theme.textTheme.bodySmall),
            TransportOptionsList(options: options, suggested: estimator!.recommend(options, style)),
          ],
        ],
      ),
    );
  }
}
