import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/geo/geo_point.dart';
import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/kathmandu_time.dart';
import '../../location/application/location_providers.dart';
import '../../location/domain/start_presets.dart';
import '../../places/domain/place_category.dart';
import '../../profile/application/preferences_controller.dart';
import '../../transport/domain/transport_option.dart';
import '../application/itinerary_controller.dart';
import '../domain/itinerary.dart';
import 'plan_timeline.dart';

/// Interest chips on the Plan screen (wireframe: Food, Culture, Nature).
enum InterestChoice {
  culture({PlaceCategory.heritage, PlaceCategory.temple}),
  food({PlaceCategory.food}),
  nature({PlaceCategory.nature}),
  views({PlaceCategory.viewpoint}),
  shopping({PlaceCategory.shopping});

  const InterestChoice(this.categories);
  final Set<PlaceCategory> categories;

  static Set<InterestChoice> fromCategories(Set<PlaceCategory> cats) =>
      {for (final c in values) if (c.categories.any(cats.contains)) c};
}

/// "Plan with AI": budget + interests (+ optional date, time and start),
/// then the suggested itinerary as an editable timeline.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  late TravelStyle _budget;
  late Set<InterestChoice> _interests;
  late DateTime _date;
  late int _startMinute;
  late double _hours;
  StartPreset? _preset = StartPreset.thamel; // null = my location
  bool _showOptions = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesProvider);
    final existing = ref.read(itineraryControllerProvider).value?.request;
    _budget = existing?.travelStyle ?? prefs.travelStyle;
    _interests = InterestChoice.fromCategories(existing?.interests ?? prefs.interests);
    final now = ref.read(nowProvider);
    final lateInDay = now.hour >= 17;
    _date = lateInDay ? dateOnly(now).add(const Duration(days: 1)) : dateOnly(now);
    _startMinute = lateInDay ? 9 * 60 : ((minuteOfDay(now) ~/ 30) + 1) * 30;
    _hours = lateInDay ? 8 : ((20 * 60 - _startMinute) / 60).clamp(2, 10).roundToDouble();
    if (ref.read(userLocationProvider) != null) _preset = null;
  }

  ItineraryRequest _request() {
    final here = ref.read(userLocationProvider);
    final GeoPoint location = _preset?.location ?? here ?? StartPreset.thamel.location;
    return ItineraryRequest(
      startTime: atMinuteOfDay(_date, _startMinute),
      availableMinutes: (_hours * 60).round(),
      start: StartPoint(_preset?.name ?? (here == null ? StartPreset.thamel.name : ''), location),
      interests: {for (final i in _interests) ...i.categories},
      travelStyle: _budget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final itinerary = ref.watch(itineraryControllerProvider);
    final aiEnabled = ref.watch(aiConfigProvider).isEnabled;
    final loading = itinerary.isLoading;

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          icon: Icons.auto_awesome,
          title: l10n.planWithAi,
          color: AppTheme.aiColor,
          background: AppTheme.aiBackground,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.budget, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<TravelStyle>(
                initialValue: _budget,
                isExpanded: true,
                items: [
                  for (final s in TravelStyle.values) DropdownMenuItem(value: s, child: Text(l10n.budgetLevel(s.name))),
                ],
                onChanged: (s) => setState(() => _budget = s ?? _budget),
              ),
              const SizedBox(height: 4),
              Text(l10n.travelStyleHint(_budget.name), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              Text(l10n.planInterests, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final i in InterestChoice.values)
                    FilterChip(
                      label: Text(l10n.interestChoice(i.name)),
                      selected: _interests.contains(i),
                      selectedColor: AppTheme.aiBackground,
                      onSelected: (on) => setState(() => on ? _interests.add(i) : _interests.remove(i)),
                    ),
                ],
              ),
              TextButton.icon(
                style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
                onPressed: () => setState(() => _showOptions = !_showOptions),
                icon: Icon(_showOptions ? Icons.expand_less : Icons.expand_more),
                label: Text(l10n.planOptionsSummary(
                  DateFormat.MMMEd(l10n.localeName).format(_date),
                  l10n.minuteOfDayTime(_startMinute),
                  l10n.hoursValue(_hours.round()),
                )),
              ),
              if (_showOptions) _options(context),
              const SizedBox(height: 6),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFF2F80D8),
                ),
                icon: loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(loading ? l10n.planning : l10n.generateItinerary),
                onPressed: loading ? null : () => ref.read(itineraryControllerProvider.notifier).plan(_request()),
              ),
              if (!aiEnabled) ...[
                const SizedBox(height: 6),
                Text(l10n.aiOff, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: switch (itinerary) {
          AsyncValue(:final value?) when !loading => PlanTimeline(itinerary: value, header: form),
          AsyncError(:final error) when !loading => ListView(children: [
              form,
              Padding(padding: const EdgeInsets.all(16), child: Text('${l10n.errorLoading}\n$error')),
            ]),
          _ => ListView(children: [
              form,
              if (!loading)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.planIntro, style: Theme.of(context).textTheme.bodyMedium),
                ),
            ]),
        },
      ),
    );
  }

  Widget _options(BuildContext context) {
    final l10n = context.l10n;
    final today = dateOnly(ref.watch(nowProvider));
    final hasLocation = ref.watch(userLocationProvider) != null;
    if (!hasLocation && _preset == null) _preset = StartPreset.thamel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PickerField(
                value: DateFormat.MMMEd(l10n.localeName).format(_date),
                hint: l10n.planDate,
                icon: Icons.calendar_today,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(_date.year, _date.month, _date.day),
                    firstDate: DateTime(today.year, today.month, today.day),
                    lastDate: DateTime(today.year, today.month, today.day + 13),
                  );
                  if (picked != null) setState(() => _date = ktm(picked.year, picked.month, picked.day));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PickerField(
                value: l10n.minuteOfDayTime(_startMinute),
                hint: l10n.planStartTime,
                icon: Icons.schedule,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: _startMinute ~/ 60, minute: _startMinute % 60),
                  );
                  if (picked != null) setState(() => _startMinute = picked.hour * 60 + picked.minute);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('${l10n.planTimeAvailable}: ${l10n.hoursValue(_hours.round())}'),
        Slider(
          value: _hours,
          min: 1,
          max: 12,
          divisions: 11,
          label: l10n.hoursValue(_hours.round()),
          onChanged: (v) => setState(() => _hours = v),
        ),
        DropdownButtonFormField<StartPreset?>(
          initialValue: _preset,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.planStartFrom, prefixIcon: const Icon(Icons.trip_origin)),
          items: [
            if (hasLocation) DropdownMenuItem(value: null, child: Text(l10n.myLocation)),
            for (final p in StartPreset.values) DropdownMenuItem(value: p, child: Text(l10n.preset(p))),
          ],
          onChanged: (p) => setState(() => _preset = p),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
