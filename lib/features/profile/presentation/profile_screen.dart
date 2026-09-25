import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../itinerary/application/itinerary_controller.dart';
import '../../places/application/places_providers.dart';
import '../../places/presentation/place_detail_screen.dart';
import '../../stays/application/stays_providers.dart';
import '../../stays/presentation/stay_detail_screen.dart';
import '../../transport/application/transport_providers.dart';
import '../application/preferences_controller.dart';
import '../application/saved_controller.dart';
import 'preferences_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final saved = ref.watch(savedProvider);
    final prefs = ref.watch(preferencesProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: AppTheme.transitBackground, child: Text('GU')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.guestUser, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        InkWell(
                          onTap: () => ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(l10n.accountsComingSoon))),
                          child: Text(l10n.signInToSync, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.seed)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SectionLabel(l10n.savedLocations),
            if (saved.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.noSaved))
            else
              for (final item in saved) _SavedTile(item: item),
            SectionLabel(l10n.settings),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.language),
              trailing: Text(l10n.languageEnglish),
              onTap: () => _chooseLanguage(context),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: Text(l10n.notifications),
              subtitle: Text(l10n.notificationsHint),
              value: prefs.notifications,
              onChanged: (on) => ref.read(preferencesProvider.notifier).setNotifications(on),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(l10n.preferences),
              subtitle: Text(l10n.preferencesSummary(l10n.visitorType(prefs.visitorType.name), l10n.budgetLevel(prefs.travelStyle.name))),
              onTap: () => showPreferencesSheet(context),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.aboutData),
              onTap: () => _about(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _chooseLanguage(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: Row(children: [Expanded(child: Text(l10n.languageEnglish)), const Icon(Icons.check)]),
          ),
          SimpleDialogOption(
            onPressed: null,
            child: Text(l10n.languageNepaliSoon, style: TextStyle(color: Theme.of(context).disabledColor)),
          ),
        ],
      ),
    );
  }

  void _about(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final network = ref.read(routeNetworkProvider).value;
    final ai = ref.read(aiConfigProvider);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aboutData),
        content: SingleChildScrollView(
          child: Text([
            l10n.aboutPlaces,
            if (network != null) '${network.source}\n${network.disclaimer}',
            l10n.aboutWeather,
            ai.isEnabled ? l10n.aboutAiOn(ai.model) : l10n.aboutAiOff,
            l10n.reportsOnDevice,
          ].join('\n\n')),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.done))],
      ),
    );
  }
}

class _SavedTile extends ConsumerWidget {
  const _SavedTile({required this.item});
  final SavedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final (String? title, String subtitle, IconData icon, VoidCallback? open) = switch (item.kind) {
      SavedKind.place => () {
          final p = ref.watch(placeByIdProvider(item.id));
          return (
            p?.name,
            p == null ? '' : l10n.categoryName(p.category.name),
            Icons.place_outlined,
            p == null ? null : () => PlaceDetailScreen.open(context, p.id),
          );
        }(),
      SavedKind.stay => () {
          final s = ref.watch(stayByIdProvider(item.id));
          return (
            s?.name,
            l10n.catStays,
            Icons.bed_outlined,
            s == null ? null : () => StayDetailScreen.open(context, s.id),
          );
        }(),
    };
    if (title == null) return const SizedBox.shrink();
    return ListTile(
      leading: CircleAvatar(backgroundColor: AppTheme.transitBackground, child: Icon(icon, color: AppTheme.seed)),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: open,
      trailing: IconButton(
        tooltip: l10n.unsave,
        icon: const Icon(Icons.bookmark_remove_outlined),
        onPressed: () => ref.read(savedProvider.notifier).toggle(item),
      ),
    );
  }
}
