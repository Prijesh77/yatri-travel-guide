import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../places/domain/place_category.dart';
import '../../transport/domain/transport_option.dart';
import '../domain/user_preferences.dart';

final preferencesProvider = NotifierProvider<PreferencesController, UserPreferences>(PreferencesController.new);

class PreferencesController extends Notifier<UserPreferences> {
  static const _key = 'prefs.user.v1';

  @override
  UserPreferences build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null) return const UserPreferences();
    try {
      return UserPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const UserPreferences();
    }
  }

  void toggleInterest(PlaceCategory category) {
    final next = {...state.interests};
    if (!next.remove(category)) next.add(category);
    _save(state.copyWith(interests: next));
  }

  void setVisitorType(VisitorType type) => _save(state.copyWith(visitorType: type));

  void setTravelStyle(TravelStyle style) => _save(state.copyWith(travelStyle: style));

  void _save(UserPreferences prefs) {
    state = prefs;
    ref.read(keyValueStoreProvider).setString(_key, jsonEncode(prefs.toJson()));
  }
}
