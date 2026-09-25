import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../location/presentation/location_picker.dart';
import '../../places/application/places_providers.dart';
import '../../places/domain/place.dart';
import '../../stays/domain/stay.dart';
import '../../transport/domain/route_network.dart';
import '../../places/presentation/place_detail_screen.dart';
import '../../stays/application/stays_providers.dart';
import '../../stays/presentation/stay_detail_screen.dart';
import '../../transport/application/transport_providers.dart';
import '../../transport/presentation/transit_screen.dart';

/// One search box for places, stays and bus stops / routes.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = _q.trim().toLowerCase();
    bool match(String s) => s.toLowerCase().contains(q);

    final List<Place> places =
        q.isEmpty ? const [] : [for (final p in ref.watch(placesProvider).value ?? const <Place>[]) if (match(p.name)) p];
    final List<Stay> stays = q.isEmpty
        ? const []
        : [
            for (final s in ref.watch(staysProvider).value?.stays ?? const <Stay>[])
              if (match(s.name) || match(s.area)) s,
          ];
    final network = ref.watch(routeNetworkProvider).value;
    final List<TransitStop> stops = q.isEmpty
        ? const []
        : [for (final s in network?.stops.values ?? const <TransitStop>[]) if (match(s.name)) s];
    final List<BusRoute> routes = q.isEmpty
        ? const []
        : [for (final r in network?.routes ?? const <BusRoute>[]) if (match(r.name) || match(r.id)) r];

    void goTransit(LocationChoice c) {
      ref.read(transitDestinationProvider.notifier).set(c);
      ref.read(rootTabProvider.notifier).select(RootTab.transit);
      Navigator.of(context).popUntil((r) => r.isFirst);
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.searchHint, border: InputBorder.none),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      body: ListView(
        children: [
          if (q.isNotEmpty && places.isEmpty && stays.isEmpty && stops.isEmpty && routes.isEmpty)
            Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noResults)),
          if (places.isNotEmpty) SectionLabel(l10n.pickerPlaces),
          for (final p in places)
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(p.name),
              subtitle: Text('${l10n.cityName(p.city.name)} · ${l10n.categoryName(p.category.name)}'),
              onTap: () => PlaceDetailScreen.open(context, p.id),
            ),
          if (stays.isNotEmpty) SectionLabel(l10n.catStays),
          for (final s in stays)
            ListTile(
              leading: const Icon(Icons.bed_outlined),
              title: Text(s.name),
              subtitle: Text(s.area),
              onTap: () => StayDetailScreen.open(context, s.id),
            ),
          if (stops.isNotEmpty || routes.isNotEmpty) SectionLabel(l10n.catTransport),
          for (final s in stops)
            ListTile(
              leading: const Icon(Icons.directions_bus_outlined),
              title: Text(s.name),
              subtitle: Text(l10n.routeHere),
              onTap: () => goTransit(LocationChoice(s.name, s.location, LocationKind.stop)),
            ),
          for (final r in routes)
            ListTile(
              leading: const Icon(Icons.route, color: AppTheme.seed),
              title: Text('${r.id} · ${r.name}'),
              subtitle: Text(r.stops.map((s) => s.name).join(' → '), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}
