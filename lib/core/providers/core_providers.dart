import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/key_value_store.dart';
import '../time/kathmandu_time.dart';

/// Overridden in `main()` with a SharedPreferences-backed store, and with a
/// [MemoryStore] in tests.
final keyValueStoreProvider = Provider<KeyValueStore>((ref) => MemoryStore());

final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Current Kathmandu time, refreshed every minute so "open now" and
/// time-of-day scoring stay current while the app is open.
final nowProvider = NotifierProvider<NowNotifier, DateTime>(NowNotifier.new);

class NowNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final clock = ref.watch(clockProvider);
    final timer = Timer.periodic(const Duration(minutes: 1), (_) => state = clock.now());
    ref.onDispose(timer.cancel);
    return clock.now();
  }

  void refresh() => state = ref.read(clockProvider).now();
}
