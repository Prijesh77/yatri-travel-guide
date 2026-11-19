import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../application/weather_providers.dart';
import '../domain/weather.dart';

/// Current conditions, styled for the dark gradient header on Home.
class HeroWeather extends ConsumerWidget {
  const HeroWeather({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const onHero = Colors.white;
    final muted = Colors.white.withValues(alpha: 0.78);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (weather) {
        AsyncValue(:final value?) => _Conditions(key: const ValueKey('ok'), report: value),
        AsyncError() => Row(
            key: const ValueKey('error'),
            children: [
              Icon(Icons.cloud_off, color: muted),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.weatherUnavailable, style: theme.textTheme.bodySmall?.copyWith(color: muted))),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: onHero),
                onPressed: () => ref.invalidate(weatherProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        _ => Row(
            key: const ValueKey('loading'),
            children: [
              SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: muted)),
              const SizedBox(width: 12),
              Text(l10n.weatherLoading, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
            ],
          ),
      },
    );
  }
}

class _Conditions extends StatelessWidget {
  const _Conditions({super.key, required this.report});
  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final current = report.current;
    final today = report.dayOf(current.time);
    final air = current.airQuality;
    final muted = Colors.white.withValues(alpha: 0.78);
    final updated =
        report.fromCache ? l10n.weatherOffline(l10n.time(report.fetchedAt)) : l10n.weatherUpdated(l10n.time(report.fetchedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${current.temperatureC.round()}°',
              style: theme.textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1),
            ),
            const SizedBox(width: 12),
            Icon(current.condition.icon(isDay: current.isDay), size: 30, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.weatherCondition(current.condition.name),
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                  Row(
                    children: [
                      if (report.fromCache) ...[
                        Icon(Icons.cloud_off, size: 12, color: muted),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(updated,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (today != null) _GlassPill(icon: Icons.thermostat, text: l10n.weatherToday(today.minC.round(), today.maxC.round())),
            if (today?.precipitationProbability case final p?) _GlassPill(icon: Icons.umbrella, text: l10n.rainChance(p)),
            if (air != null)
              _GlassPill(
                icon: Icons.air,
                text: '${l10n.airQuality(air.name)} · ${l10n.aqiValue(current.usAqi!)}',
                dot: air.color,
              ),
          ],
        ),
      ],
    );
  }
}

/// Translucent pill for use on the gradient header.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.text, this.dot});
  final IconData icon;
  final String text;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
            const SizedBox(width: 6),
          ] else ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
