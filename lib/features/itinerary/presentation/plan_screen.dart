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

  IconData get icon => switch (this) {
        culture => Icons.account_balance_outlined,
        food => Icons.restaurant_outlined,
        nature => Icons.park_outlined,
        views => Icons.landscape_outlined,
        shopping => Icons.shopping_bag_outlined,
      };

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

  /// With a plan on screen the form collapses to a summary, so the plan is
  /// what the traveller sees first.
  bool _editing = false;

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

  /// Starts editing from the plan on screen, so "Edit" shows its settings.
  void _loadFrom(ItineraryRequest r) {
    _budget = r.travelStyle;
    _interests = InterestChoice.fromCategories(r.interests);
    final today = dateOnly(ref.read(nowProvider));
    final day = dateOnly(r.startTime);
    if (!day.isBefore(today)) {
      _date = day;
      _startMinute = minuteOfDay(r.startTime);
      _hours = (r.availableMinutes / 60).clamp(1, 12).roundToDouble();
    }
    for (final p in StartPreset.values) {
      if (p.name == r.start.label) _preset = p;
    }
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

    final theme = Theme.of(context);
    final y = context.yatri;

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          icon: Icons.auto_awesome,
          title: l10n.planWithAi,
          color: y.ai,
          background: y.aiContainer,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldLabel(l10n.budget),
              SegmentedButton<TravelStyle>(
                segments: [
                  for (final s in TravelStyle.values)
                    ButtonSegment(
                      value: s,
                      label: Text(l10n.budgetLevel(s.name), maxLines: 1, overflow: TextOverflow.ellipsis),
                      icon: Icon(switch (s) {
                        TravelStyle.budget => Icons.savings_outlined,
                        TravelStyle.balanced => Icons.balance,
                        TravelStyle.comfort => Icons.local_taxi_outlined,
                      }),
                    ),
                ],
                selected: {_budget},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _budget = s.first),
              ),
              const SizedBox(height: 6),
              Text(l10n.travelStyleHint(_budget.name),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              _FieldLabel(l10n.planInterests),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final i in InterestChoice.values)
                    FilterChip(
                      avatar: Icon(i.icon, size: 18, color: _interests.contains(i) ? y.ai : null),
                      label: Text(l10n.interestChoice(i.name)),
                      selected: _interests.contains(i),
                      selectedColor: y.aiContainer,
                      side: _interests.contains(i) ? BorderSide(color: y.ai.withValues(alpha: 0.5)) : null,
                      labelStyle: _interests.contains(i)
                          ? theme.textTheme.labelLarge?.copyWith(color: y.ai, fontWeight: FontWeight.w700)
                          : null,
                      onSelected: (on) => setState(() => on ? _interests.add(i) : _interests.remove(i)),
                    ),
                ],
              ),
              _FieldLabel(l10n.tripDetails),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showOptions = !_showOptions),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                        child: Row(
                          children: [
                            Icon(Icons.event_note_outlined, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.planOptionsSummary(
                                  DateFormat.MMMEd(l10n.localeName).format(_date),
                                  l10n.minuteOfDayTime(_startMinute),
                                  l10n.hoursValue(_hours.round()),
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _showOptions ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.expand_more),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _showOptions
                          ? Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 8), child: _options(context))
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: y.ai,
                  foregroundColor: y.aiContainer,
                ),
                icon: loading
                    ? SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: y.aiContainer))
                    : const Icon(Icons.auto_awesome),
                label: Text(loading ? l10n.planning : l10n.generateItinerary),
                onPressed: loading
                    ? null
                    : () {
                        setState(() => _editing = false);
                        ref.read(itineraryControllerProvider.notifier).plan(_request());
                      },
              ),
              if (!aiEnabled) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(l10n.aiOff,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    Widget compact(ItineraryRequest r) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(icon: Icons.auto_awesome, title: l10n.planWithAi, color: y.ai, background: y.aiContainer),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  Icon(Icons.tune, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            l10n.budgetLevel(r.travelStyle.name),
                            if (r.interests.isEmpty)
                              l10n.anyInterests
                            else
                              [
                                for (final i in InterestChoice.fromCategories(r.interests))
                                  l10n.interestChoice(i.name),
                              ].join(', '),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          l10n.planOptionsSummary(
                            DateFormat.MMMEd(l10n.localeName).format(r.startTime),
                            l10n.time(r.startTime),
                            l10n.hoursValue((r.availableMinutes / 60).round()),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _loadFrom(r);
                      _editing = true;
                    }),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.editPlan),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: switch (itinerary) {
          AsyncValue(:final value?) when !loading =>
            PlanTimeline(itinerary: value, header: _editing ? form : compact(value.request)),
          AsyncError(:final error) when !loading => ListView(children: [
              form,
              Padding(padding: const EdgeInsets.all(16), child: Text('${l10n.errorLoading}\n$error')),
            ]),
          _ => ListView(children: [
              form,
              if (!loading) const _PlanIntro(),
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
        const SizedBox(height: 12),
        Text('${l10n.planTimeAvailable}: ${l10n.hoursValue(_hours.round())}',
            style: Theme.of(context).textTheme.labelLarge),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

/// Shown before the first plan: what the planner does, in three steps.
class _PlanIntro extends StatelessWidget {
  const _PlanIntro();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final y = context.yatri;
    final steps = [
      (Icons.tune, l10n.planEmptyStep1),
      (Icons.schedule, l10n.planEmptyStep2),
      (Icons.alt_route, l10n.planEmptyStep3),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.planEmptyTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.planIntro, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            for (final (i, (icon, text)) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: y.aiContainer, borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, size: 18, color: y.ai),
                    ),
                    const SizedBox(width: 12),
                    Text('${i + 1}. ', style: theme.textTheme.labelLarge?.copyWith(color: y.ai)),
                    Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
