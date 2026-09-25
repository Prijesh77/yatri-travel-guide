import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/json_source.dart';
import '../../../core/providers/core_providers.dart';
import '../data/stays_repository.dart';
import '../domain/stay.dart';

final staysRepositoryProvider = Provider<StaysRepository>((ref) {
  return JsonStaysRepository(OfflineFirstJsonLoader(
    cacheKey: 'cache.stays',
    bundled: AssetJsonSource('assets/data/stays.json'),
    store: ref.watch(keyValueStoreProvider),
  ));
});

final staysProvider = FutureProvider<StayCatalog>((ref) {
  return ref.watch(staysRepositoryProvider).getCatalog();
});

final stayByIdProvider = Provider.family<Stay?, String>((ref, id) {
  for (final s in ref.watch(staysProvider).value?.stays ?? const <Stay>[]) {
    if (s.id == id) return s;
  }
  return null;
});
