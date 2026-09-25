import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/navigation.dart';
import '../../../core/geo/geo_point.dart';
import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../itinerary/application/itinerary_controller.dart';
import '../../location/application/location_providers.dart';
import '../application/map_providers.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_category.dart';
import '../../places/presentation/category_filter_bar.dart';
import '../../places/presentation/place_detail_screen.dart';
import '../../places/presentation/place_widgets.dart';
import '../../recommendations/application/recommendation_providers.dart';
import '../../recommendations/domain/scored_place.dart';

LatLng _ll(GeoPoint p) => LatLng(p.lat, p.lng);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _map = MapController();
  PlaceCategory? _category;
  bool _showPlan = true;
  bool _mapReady = false;
  MapFocusRequest? _pendingFocus;

  void _applyFocus(MapFocusRequest request) {
    if (!_mapReady) {
      _pendingFocus = request;
      return;
    }
    if (request.showPlan) setState(() => _showPlan = true);
    final points = [for (final p in request.points) _ll(p)];
    if (points.length == 1) {
      _map.move(points.single, 15);
    } else if (points.length > 1) {
      _map.fitCamera(CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(56)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mapFocusProvider, (_, next) {
      if (next != null) _applyFocus(next);
    });

    final ranked = ref.watch(rankedPlacesProvider).value ?? const <ScoredPlace>[];
    final itinerary = ref.watch(itineraryControllerProvider).value;
    final here = ref.watch(userLocationProvider);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final planIds = {for (final s in itinerary?.stops ?? const []) s.place.id};
    final visible = [
      for (final s in ranked)
        if ((_category == null || s.place.hasCategory(_category!)) && !(_showPlan && planIds.contains(s.place.id)))
          s,
    ];
    final planPoints = [
      if (itinerary != null && !itinerary.isEmpty) ...[
        _ll(itinerary.request.start.location),
        for (final s in itinerary.stops) _ll(s.place.location),
      ],
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _ll(ValleyBounds.center),
              initialZoom: 12,
              minZoom: 9,
              maxZoom: 18,
              onMapReady: () {
                _mapReady = true;
                final pending = _pendingFocus ?? ref.read(mapFocusProvider);
                _pendingFocus = null;
                if (pending != null) _applyFocus(pending);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'np.yatri.yatri',
                tileProvider: ref.watch(mapTileProviderProvider),
              ),
              if (_showPlan && planPoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: planPoints,
                      strokeWidth: 4,
                      color: scheme.primary,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                      pattern: StrokePattern.dashed(segments: const [12, 6]),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final s in visible)
                    Marker(
                      point: _ll(s.place.location),
                      width: 32,
                      height: 32,
                      child: _PlaceMarker(scored: s, onTap: () => _showPlaceSheet(s)),
                    ),
                  if (_showPlan && itinerary != null && !itinerary.isEmpty) ...[
                    Marker(
                      point: _ll(itinerary.request.start.location),
                      width: 28,
                      height: 28,
                      child: Icon(Icons.trip_origin, color: scheme.primary, size: 28),
                    ),
                    for (final (i, stop) in itinerary.stops.indexed)
                      Marker(
                        point: _ll(stop.place.location),
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => PlaceDetailScreen.open(context, stop.place.id),
                          child: CircleAvatar(
                            backgroundColor: scheme.primary,
                            child: Text('${i + 1}',
                                style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                  if (here != null)
                    Marker(
                      point: _ll(here),
                      width: 22,
                      height: 22,
                      child: Tooltip(
                        message: l10n.youAreHere,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                CategoryFilterBar(selected: _category, onSelected: (c) => setState(() => _category = c)),
                if (planPoints.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: FilterChip(
                      avatar: const Icon(Icons.route, size: 18),
                      label: Text(l10n.mapShowPlan),
                      selected: _showPlan,
                      onSelected: (on) => setState(() => _showPlan = on),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: here == null
          ? null
          : FloatingActionButton.small(
              tooltip: l10n.youAreHere,
              onPressed: () => _map.move(_ll(here), 15),
              child: const Icon(Icons.my_location),
            ),
    );
  }

  void _showPlaceSheet(ScoredPlace s) {
    final l10n = context.l10n;
    final Place place = s.place;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryAvatar(place.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.displayName(l10n.localeName), style: Theme.of(context).textTheme.titleMedium),
                        Text('${l10n.cityName(place.city.name)} · ${l10n.categoryName(place.category.name)}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SuitabilityBadge(suitability: s.suitability, label: l10n.suitability(s.suitability.name)),
              const SizedBox(height: 8),
              if (l10n.cardReason(s).isNotEmpty) ReasonLine(text: l10n.cardReason(s), positive: s.isAvailable),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    PlaceDetailScreen.open(context, place.id);
                  },
                  child: Text(l10n.details),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({required this.scored, required this.onTap});
  final ScoredPlace scored;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = scored.place.category;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: scored.isAvailable ? 1 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
          ),
          child: Icon(category.icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
