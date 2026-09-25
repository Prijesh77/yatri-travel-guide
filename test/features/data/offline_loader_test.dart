import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/data/json_source.dart';
import 'package:yatri/core/data/key_value_store.dart';

class _FailingSource implements JsonSource {
  @override
  Future<String> load() async => throw Exception('offline');
}

void main() {
  String doc(int version, String marker) => jsonEncode({'version': version, 'marker': marker});

  test('first run uses bundled data and caches it', () async {
    final store = MemoryStore();
    final loader = OfflineFirstJsonLoader(cacheKey: 'k', bundled: StringJsonSource(doc(1, 'bundled')), store: store);
    final result = await loader.load();
    expect(result.origin, DataOrigin.bundled);
    expect(store.getString('k'), isNotNull);
  });

  test('remote data wins and is cached', () async {
    final store = MemoryStore();
    final loader = OfflineFirstJsonLoader(
      cacheKey: 'k',
      bundled: StringJsonSource(doc(1, 'bundled')),
      remote: StringJsonSource(doc(3, 'remote')),
      store: store,
    );
    final result = await loader.load();
    expect(result.origin, DataOrigin.remote);
    expect(result.json['marker'], 'remote');
    expect(jsonDecode(store.getString('k')!)['marker'], 'remote');
  });

  test('offline: newer cached data is used', () async {
    final store = MemoryStore({'k': doc(3, 'cached')});
    final loader = OfflineFirstJsonLoader(
      cacheKey: 'k',
      bundled: StringJsonSource(doc(1, 'bundled')),
      remote: _FailingSource(),
      store: store,
    );
    final result = await loader.load();
    expect(result.origin, DataOrigin.cache);
    expect(result.json['marker'], 'cached');
  });

  test('bundled data newer than the cache wins (app update)', () async {
    final store = MemoryStore({'k': doc(1, 'old cache')});
    final loader = OfflineFirstJsonLoader(cacheKey: 'k', bundled: StringJsonSource(doc(2, 'bundled')), store: store);
    final result = await loader.load();
    expect(result.origin, DataOrigin.bundled);
    expect(jsonDecode(store.getString('k')!)['marker'], 'bundled');
  });

  test('corrupt cache is ignored', () async {
    final store = MemoryStore({'k': '{not json'});
    final loader = OfflineFirstJsonLoader(cacheKey: 'k', bundled: StringJsonSource(doc(1, 'bundled')), store: store);
    expect((await loader.load()).origin, DataOrigin.bundled);
  });
}
