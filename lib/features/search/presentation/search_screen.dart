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
  final _controller = TextEditingController();
  String _q = '';

  /// Shown before anything is typed, so the screen is never blank.
  static const _suggestions = ['Boudha', 'Patan', 'Temple', 'Momo', 'Bhaktapur', 'Ratnapark', 'Guesthouse'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    _controller.value = TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length));
    setState(() => _q = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = _q.trim().toLowerCase();
    bool match(String s) => s.toLowerCase().contains(q);

    // Names, plus category and city, so "temple" or "Bhaktapur" find places.
    final List<Place> places = q.isEmpty
        ? const []
        : [
            for (final p in ref.watch(placesProvider).value ?? const <Place>[])
              if (match(p.name) || match(l10n.categoryName(p.category.name)) || match(l10n.cityName(p.city.name))) p,
          ];
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
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: _q.isEmpty
                ? null
                : IconButton(tooltip: l10n.clearSearch, icon: const Icon(Icons.close), onPressed: () => _search('')),
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (q.isEmpty) ...[
            SectionLabel(l10n.searchTry),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _suggestions)
                    ActionChip(avatar: const Icon(Icons.search, size: 16), label: Text(s), onPressed: () => _search(s)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Text(l10n.searchIntro,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
          if (q.isNotEmpty && places.isEmpty && stays.isEmpty && stops.isEmpty && routes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text(l10n.noResults, textAlign: TextAlign.center),
                ],
              ),
            ),
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
              leading: Icon(Icons.route, color: context.yatri.transit),
              title: Text('${r.id} · ${r.name}'),
              subtitle: Text(r.stops.map((s) => s.name).join(' → '), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}
