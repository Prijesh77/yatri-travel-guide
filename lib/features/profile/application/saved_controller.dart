import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';

enum SavedKind { place, stay }

class SavedItem {
  const SavedItem(this.kind, this.id);
  final SavedKind kind;
  final String id;

  String get key => '${kind.name}:$id';

  @override
  bool operator ==(Object other) => other is SavedItem && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Places and stays the user bookmarked ("Saved locations" on Profile).
final savedProvider = NotifierProvider<SavedController, List<SavedItem>>(SavedController.new);

class SavedController extends Notifier<List<SavedItem>> {
  static const _key = 'profile.saved.v1';

  @override
  List<SavedItem> build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return [
        for (final k in jsonDecode(raw) as List)
          if ((k as String).split(':') case [final kind, final id])
            if (SavedKind.values.asNameMap()[kind] case final SavedKind k2) SavedItem(k2, id),
      ];
    } catch (_) {
      return const [];
    }
  }

  bool isSaved(SavedItem item) => state.contains(item);

  void toggle(SavedItem item) {
    state = isSaved(item) ? [for (final s in state) if (s != item) s] : [item, ...state];
    ref.read(keyValueStoreProvider).setString(_key, jsonEncode([for (final s in state) s.key]));
  }
}
