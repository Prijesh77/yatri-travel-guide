import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../application/weather_providers.dart';
import '../domain/weather.dart';

class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (weather) {
          AsyncValue(:final value?) => _WeatherContent(report: value),
          AsyncError() => Row(
              children: [
                const Icon(Icons.cloud_off),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.weatherUnavailable)),
                TextButton(onPressed: () => ref.invalidate(weatherProvider), child: Text(l10n.retry)),
              ],
            ),
          _ => const SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
        },
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({required this.report});
  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final current = report.current;
    final today = report.dayOf(current.time);
    final air = current.airQuality;
    final updated = report.fromCache ? l10n.weatherOffline(l10n.time(report.fetchedAt)) : l10n.weatherUpdated(l10n.time(report.fetchedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(current.condition.icon(isDay: current.isDay), size: 44, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text('${current.temperatureC.round()}°', style: theme.textTheme.displaySmall),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.weatherCondition(current.condition.name), style: theme.textTheme.titleMedium),
                  Text(l10n.weatherValley, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (today != null) _Pill(icon: Icons.thermostat, text: l10n.weatherToday(today.minC.round(), today.maxC.round())),
            if (today?.precipitationProbability case final p?) _Pill(icon: Icons.umbrella, text: l10n.rainChance(p)),
            if (air != null)
              _Pill(
                icon: Icons.air,
                text: '${l10n.airQuality(air.name)} · ${l10n.aqiValue(current.usAqi!)}',
                color: air.color,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (report.fromCache) ...[
              Icon(Icons.cloud_off, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(updated, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: c.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c)),
        ],
      ),
    );
  }
}
