import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo_point.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../places/application/places_providers.dart';
import '../../transport/application/transport_providers.dart';
import '../application/location_providers.dart';

enum LocationKind { myLocation, hub, place, stop }

/// A named point chosen by the user.
class LocationChoice {
  const LocationChoice(this.label, this.point, this.kind);
  final String label;
  final GeoPoint point;
  final LocationKind kind;
}

/// Bottom sheet to pick "My location", a transport hub, an attraction or a
/// bus stop, with type-to-filter.
Future<LocationChoice?> showLocationPicker(BuildContext context, {required String title, bool stopsOnly = false}) =>
    showModalBottomSheet<LocationChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _LocationPicker(title: title, stopsOnly: stopsOnly),
      ),
    );

class _LocationPicker extends ConsumerStatefulWidget {
  const _LocationPicker({required this.title, required this.stopsOnly});
  final String title;
  final bool stopsOnly;

  @override
  ConsumerState<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends ConsumerState<_LocationPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final here = ref.watch(userLocationProvider);
    final network = ref.watch(routeNetworkProvider).value;
    final places = widget.stopsOnly ? const [] : ref.watch(placesProvider).value ?? const [];
    final q = _query.trim().toLowerCase();
    bool match(String s) => q.isEmpty || s.toLowerCase().contains(q);

    final hubs = [
      for (final h in network?.hubs ?? const [])
        if (h.stop != null && (match(h.name) || match(h.stop!.name)))
          LocationChoice(h.stop!.name, h.stop!.location, LocationKind.hub),
    ];
    final hubStops = {for (final h in hubs) h.label};
    final placeChoices = [
      for (final p in places)
        if (match(p.name)) LocationChoice(p.name, p.location, LocationKind.place),
    ];
    final stops = [
      for (final s in (network?.stops.values.toList() ?? const [])..sort((a, b) => a.name.compareTo(b.name)))
        if (match(s.name) && !hubStops.contains(s.name)) LocationChoice(s.name, s.location, LocationKind.stop),
    ];

    Widget tile(LocationChoice c) => ListTile(
          dense: true,
          leading: Icon(switch (c.kind) {
            LocationKind.myLocation => Icons.my_location,
            LocationKind.hub => Icons.hub_outlined,
            LocationKind.place => Icons.place_outlined,
            LocationKind.stop => Icons.directions_bus_outlined,
          }),
          title: Text(c.label),
          onTap: () => Navigator.pop(context, c),
        );

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.seed)),
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: widget.title, prefixIcon: const Icon(Icons.search)),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (here != null && q.isEmpty) tile(LocationChoice(l10n.myLocation, here, LocationKind.myLocation)),
              if (hubs.isNotEmpty) ...[header(l10n.pickerHubs), ...hubs.map(tile)],
              if (placeChoices.isNotEmpty) ...[header(l10n.pickerPlaces), ...placeChoices.map(tile)],
              if (stops.isNotEmpty) ...[header(l10n.pickerStops), ...stops.map(tile)],
              if (hubs.isEmpty && placeChoices.isEmpty && stops.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noResults)),
            ],
          ),
        ),
      ],
    );
  }
}
