import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom navigation tabs (wireframe: Home, Transit, Alerts, Plan, Profile).
enum RootTab { home, transit, alerts, plan, profile }

final rootTabProvider = NotifierProvider<RootTabNotifier, RootTab>(RootTabNotifier.new);

class RootTabNotifier extends Notifier<RootTab> {
  @override
  RootTab build() => RootTab.home;

  void select(RootTab tab) => state = tab;
}
