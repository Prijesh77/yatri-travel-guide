import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../location/application/location_providers.dart';
import '../../places/domain/place_category.dart';
import '../application/stays_providers.dart';
import '../domain/stay.dart';
import 'stay_detail_screen.dart';

class StaysScreen extends ConsumerStatefulWidget {
  const StaysScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StaysScreen()));

  @override
  ConsumerState<StaysScreen> createState() => _StaysScreenState();
}

class _StaysScreenState extends ConsumerState<StaysScreen> {
  String _query = '';
  City? _city;
  PriceBand? _band;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(staysProvider).value;
    final here = ref.watch(userLocationProvider);
    final q = _query.trim().toLowerCase();
    final stays = [
      for (final s in catalog?.stays ?? const <Stay>[])
        if ((q.isEmpty || s.name.toLowerCase().contains(q) || s.area.toLowerCase().contains(q)) &&
            (_city == null || s.city == _city) &&
            (_band == null || s.priceBand == _band))
          s,
    ];
    if (here != null) {
      stays.sort((a, b) => a.location.distanceKmTo(here).compareTo(b.location.distanceKmTo(here)));
    }

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ScreenHeader(
            icon: Icons.bed_outlined,
            title: l10n.catStays,
            color: AppTheme.seed,
            background: AppTheme.transitBackground,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(hintText: l10n.staysSearchHint, prefixIcon: const Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                for (final c in City.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.cityName(c.name)),
                      selected: _city == c,
                      onSelected: (on) => setState(() => _city = on ? c : null),
                    ),
                  ),
                for (final b in PriceBand.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.priceBand(b.name)),
                      selected: _band == b,
                      onSelected: (on) => setState(() => _band = on ? b : null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (catalog == null)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (stays.isEmpty)
            Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noResults))
          else
            for (final s in stays)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SoftCard(
                  onTap: () => StayDetailScreen.open(context, s.id),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            TagChip(l10n.stayType(s.type.name), color: AppTheme.seed, background: AppTheme.transitBackground),
                            const SizedBox(height: 4),
                            Text(
                              <String>{
                                s.area,
                                l10n.cityName(s.city.name),
                                if (here != null) l10n.distance(s.location.distanceKmTo(here)),
                              }.join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        l10n.priceRangeShort(catalog.priceRanges[s.priceBand]!),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.staysDisclaimer, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
