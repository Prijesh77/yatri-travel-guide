import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/geo/geo_point.dart';

enum RootTab { explore, plan, map }

final rootTabProvider = NotifierProvider<RootTabNotifier, RootTab>(RootTabNotifier.new);

class RootTabNotifier extends Notifier<RootTab> {
  @override
  RootTab build() => RootTab.explore;

  void select(RootTab tab) => state = tab;
}

/// A request for the map to move: one point zooms in, several fit the view.
class MapFocusRequest {
  MapFocusRequest(this.points, {this.showPlan = false});
  final List<GeoPoint> points;
  final bool showPlan;
}

final mapFocusProvider = NotifierProvider<MapFocusNotifier, MapFocusRequest?>(MapFocusNotifier.new);

class MapFocusNotifier extends Notifier<MapFocusRequest?> {
  @override
  MapFocusRequest? build() => null;

  void focus(MapFocusRequest request) {
    state = request;
    ref.read(rootTabProvider.notifier).select(RootTab.map);
  }
}
