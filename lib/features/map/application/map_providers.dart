import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tile source for the map. The default uses flutter_map's built-in tile
/// cache (on mobile/desktop), so recently viewed areas keep working offline.
/// Tests override this with a provider that makes no network calls.
final mapTileProviderProvider = Provider<TileProvider>((ref) {
  final provider = NetworkTileProvider(silenceExceptions: true);
  ref.onDispose(provider.dispose);
  return provider;
});
