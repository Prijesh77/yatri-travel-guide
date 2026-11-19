import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Creates the tile source for one map. The default uses flutter_map's
/// built-in tile cache (on mobile/desktop), so recently viewed areas keep
/// working offline. Tests override this with a source that makes no network
/// calls.
///
/// It is a factory rather than a shared instance because [TileLayer] disposes
/// its tile provider (closing the HTTP client) when the map closes. A shared
/// instance would leave every map opened after the first one without tiles.
final mapTileProviderFactoryProvider = Provider<TileProvider Function()>(
  (ref) => () => NetworkTileProvider(silenceExceptions: true),
);
