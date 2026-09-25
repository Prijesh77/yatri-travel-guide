import 'package:flutter/material.dart';

import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/transport_option.dart';

/// One row per transport mode with time, fare and route details.
class TransportOptionsList extends StatelessWidget {
  const TransportOptionsList({super.key, required this.options, this.suggested, this.dense = false});

  final List<TransportOption> options;
  final TransportOption? suggested;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final o in options) TransportOptionTile(option: o, isSuggested: identical(o, suggested), dense: dense),
      ],
    );
  }
}

class TransportOptionTile extends StatelessWidget {
  const TransportOptionTile({super.key, required this.option, this.isSuggested = false, this.dense = false});

  final TransportOption option;
  final bool isSuggested;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final o = option;
    final perWho = switch (o.mode) {
      TransportMode.walk => null,
      TransportMode.bus => l10n.perPerson,
      TransportMode.taxi || TransportMode.bikeTaxi => l10n.perVehicle,
    };
    final journey = o.journey;
    final details = <String>[
      if (journey != null)
        l10n.busJourney(journey.rides.map((r) => r.route.id).join(' → '), o.boardAt!, o.alightAt!)
      else if (o.routeName != null)
        l10n.busRoute(o.routeName!, o.boardAt!, o.alightAt!),
      for (final n in o.notes) l10n.transportNote(n),
      if (!o.available) l10n.notAvailable,
    ];

    return Opacity(
      opacity: o.available ? 1 : 0.55,
      child: ListTile(
        dense: dense,
        contentPadding: EdgeInsets.zero,
        leading: Icon(o.mode.icon, color: isSuggested ? theme.colorScheme.primary : null),
        title: Text.rich(TextSpan(children: [
          TextSpan(text: l10n.transportMode(o.mode.name), style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: '  ${l10n.duration(o.durationMinutes)}'),
        ])),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text([l10n.fare(o.fare), ?perWho].join(' ')),
            for (final d in details) Text(d, style: theme.textTheme.bodySmall),
          ],
        ),
        trailing: isSuggested
            ? Chip(
                label: Text(l10n.suggested),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              )
            : null,
      ),
    );
  }
}
