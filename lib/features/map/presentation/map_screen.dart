import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/geo_point.dart';
import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../alerts/domain/condition_alert.dart';
import '../../itinerary/application/itinerary_controller.dart';
import '../../location/application/location_providers.dart';
import '../../places/domain/place_category.dart';
import '../../places/presentation/category_filter_bar.dart';
import '../../places/presentation/place_detail_screen.dart';
import '../../places/presentation/place_widgets.dart';
import '../../recommendations/application/recommendation_providers.dart';
import '../../recommendations/domain/scored_place.dart';
import '../../transport/domain/journey_planner.dart';
import '../application/map_providers.dart';

LatLng _ll(GeoPoint p) => LatLng(p.lat, p.lng);

/// Map of all places, live alerts, and either the day's plan or a bus
/// journey. Opened from Transit, Plan, Live conditions and detail screens.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.focus = const [], this.showPlan = false, this.journey, this.from, this.to});

  /// One point zooms in; several are fitted into view.
  final List<GeoPoint> focus;
  final bool showPlan;
  final Journey? journey;
  final GeoPoint? from;
  final GeoPoint? to;

  static Future<void> open(
    BuildContext context, {
    List<GeoPoint> focus = const [],
    bool showPlan = false,
    Journey? journey,
    GeoPoint? from,
    GeoPoint? to,
  }) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => MapScreen(focus: focus, showPlan: showPlan, journey: journey, from: from, to: to),
      ));

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _map = MapController();
  PlaceCategory? _category;

  List<LatLng> get _journeyPoints {
    final j = widget.journey;
    if (j == null) return const [];
    final points = <LatLng>[if (widget.from != null) _ll(widget.from!)];
    for (final ride in j.rides) {
      final stops = ride.route.stops;
      final a = stops.indexOf(ride.board), b = stops.indexOf(ride.alight);
      final path = a <= b ? stops.sublist(a, b + 1) : stops.sublist(b, a + 1).reversed;
      points.addAll(path.map((s) => _ll(s.location)));
    }
    if (widget.to != null) points.add(_ll(widget.to!));
    return points;
  }

  void _fitInitial() {
    final points = <LatLng>[
      ...widget.focus.map(_ll),
      ..._journeyPoints,
      if (widget.from != null && widget.journey == null) _ll(widget.from!),
      if (widget.to != null && widget.journey == null) _ll(widget.to!),
    ];
    if (widget.showPlan) {
      final it = ref.read(itineraryControllerProvider).value;
      if (it != null && !it.isEmpty) {
        points
          ..add(_ll(it.request.start.location))
          ..addAll(it.stops.map((s) => _ll(s.place.location)));
      }
    }
    if (points.length == 1) {
      _map.move(points.single, 15);
    } else if (points.length > 1) {
      _map.fitCamera(CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(56)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ranked = ref.watch(rankedPlacesProvider).value ?? const <ScoredPlace>[];
    final itinerary = widget.showPlan ? ref.watch(itineraryControllerProvider).value : null;
    final here = ref.watch(userLocationProvider);
    final alerts = [for (final a in ref.watch(activeAlertsProvider)) if (a.location != null) a];
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final planIds = {for (final s in itinerary?.stops ?? const []) s.place.id};
    final visible = [
      for (final s in ranked)
        if ((_category == null || s.place.hasCategory(_category!)) && !planIds.contains(s.place.id)) s,
    ];
    final planPoints = [
      if (itinerary != null && !itinerary.isEmpty) ...[
        _ll(itinerary.request.start.location),
        for (final s in itinerary.stops) _ll(s.place.location),
      ],
    ];
    final journeyPoints = _journeyPoints;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMap)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _ll(ValleyBounds.center),
              initialZoom: 12,
              minZoom: 9,
              maxZoom: 18,
              onMapReady: _fitInitial,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'np.yatri.yatri',
                tileProvider: ref.watch(mapTileProviderProvider),
              ),
              CircleLayer(circles: [
                for (final a in alerts)
                  CircleMarker(
                    point: _ll(a.location!),
                    radius: a.radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: (a.isEvent ? AppTheme.eventColor : AppTheme.alertColor).withValues(alpha: 0.18),
                    borderColor: a.isEvent ? AppTheme.eventColor : AppTheme.alertColor,
                    borderStrokeWidth: 1.5,
                  ),
              ]),
              PolylineLayer(
                polylines: [
                  if (planPoints.length > 1)
                    Polyline(
                      points: planPoints,
                      strokeWidth: 4,
                      color: scheme.primary,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                      pattern: StrokePattern.dashed(segments: const [12, 6]),
                    ),
                  if (journeyPoints.length > 1)
                    Polyline(
                      points: journeyPoints,
                      strokeWidth: 5,
                      color: AppTheme.seed,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
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
                  for (final a in alerts)
                    Marker(
                      point: _ll(a.location!),
                      width: 30,
                      height: 30,
                      child: Tooltip(
                        message: a.title,
                        child: CircleAvatar(
                          backgroundColor: a.isEvent ? AppTheme.eventColor : AppTheme.alertColor,
                          child: Icon(a.isEvent ? Icons.celebration : Icons.warning_amber, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  if (itinerary != null && !itinerary.isEmpty) ...[
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
                  if (widget.journey != null)
                    for (final ride in widget.journey!.rides) ...[
                      Marker(point: _ll(ride.board.location), width: 22, height: 22, child: const _StopDot()),
                      Marker(point: _ll(ride.alight.location), width: 22, height: 22, child: const _StopDot()),
                    ],
                  if (widget.from != null)
                    Marker(point: _ll(widget.from!), width: 26, height: 26, child: const _EndDot(color: Color(0xFF5B9A2E))),
                  if (widget.to != null)
                    Marker(point: _ll(widget.to!), width: 26, height: 26, child: const _EndDot(color: Color(0xFFE0483C))),
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
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: CategoryFilterBar(selected: _category, onSelected: (c) => setState(() => _category = c)),
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
    final place = s.place;
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

class _StopDot extends StatelessWidget {
  const _StopDot();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.seed, width: 4),
        ),
      );
}

class _EndDot extends StatelessWidget {
  const _EndDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
      );
}

/// Opens the map centred on an alert.
void openAlertOnMap(BuildContext context, ConditionAlert alert) {
  if (alert.location != null) MapScreen.open(context, focus: [alert.location!]);
}
