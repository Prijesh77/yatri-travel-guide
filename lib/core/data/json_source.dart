import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'key_value_store.dart';

/// Somewhere a JSON document can be loaded from.
abstract interface class JsonSource {
  Future<String> load();
}

/// JSON bundled with the app under `assets/`.
class AssetJsonSource implements JsonSource {
  AssetJsonSource(this.path, {this.bundle});
  final String path;
  final AssetBundle? bundle;

  @override
  Future<String> load() => (bundle ?? rootBundle).loadString(path);
}

/// JSON served over HTTP. Not used in v1 but ready for a backend: pass one
/// as `remote` to [OfflineFirstJsonLoader].
class HttpJsonSource implements JsonSource {
  HttpJsonSource(this.uri, {http.Client? client, this.timeout = const Duration(seconds: 8)})
      : _client = client ?? http.Client();
  final Uri uri;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<String> load() async {
    final res = await _client.get(uri).timeout(timeout);
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', uri);
    }
    return utf8.decode(res.bodyBytes);
  }
}

class StringJsonSource implements JsonSource {
  StringJsonSource(this.value);
  final String value;

  @override
  Future<String> load() async => value;
}

enum DataOrigin { remote, cache, bundled }

class LoadedJson {
  const LoadedJson(this.json, this.origin);
  final Map<String, dynamic> json;
  final DataOrigin origin;
}

/// Loads a versioned JSON dataset (`{"version": n, ...}`) offline-first:
///
/// 1. `remote` (if configured) - on success the result is cached;
/// 2. the cached copy, if its `version` is at least the bundled version
///    (so an app update with newer bundled data wins over a stale cache);
/// 3. the bundled asset, which is always available.
class OfflineFirstJsonLoader {
  OfflineFirstJsonLoader({
    required this.cacheKey,
    required this.bundled,
    required this.store,
    this.remote,
  });

  final String cacheKey;
  final JsonSource bundled;
  final JsonSource? remote;
  final KeyValueStore store;

  Future<LoadedJson> load() async {
    if (remote case final remote?) {
      try {
        final raw = await remote.load();
        final json = _decode(raw);
        await store.setString(cacheKey, raw);
        return LoadedJson(json, DataOrigin.remote);
      } catch (_) {
        // Fall through to cache / bundled data.
      }
    }

    final bundledRaw = await bundled.load();
    final bundledJson = _decode(bundledRaw);

    final cachedRaw = store.getString(cacheKey);
    if (cachedRaw != null) {
      try {
        final cached = _decode(cachedRaw);
        if (_version(cached) >= _version(bundledJson)) {
          return LoadedJson(cached, DataOrigin.cache);
        }
      } catch (_) {
        // Corrupt cache: ignore and overwrite below.
      }
    }

    await store.setString(cacheKey, bundledRaw);
    return LoadedJson(bundledJson, DataOrigin.bundled);
  }

  static Map<String, dynamic> _decode(String raw) =>
      jsonDecode(raw) as Map<String, dynamic>;

  static int _version(Map<String, dynamic> json) =>
      (json['version'] as num?)?.toInt() ?? 0;
}
