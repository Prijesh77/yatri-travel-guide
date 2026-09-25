import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/geo/geo_point.dart';
import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/kathmandu_time.dart';
import '../../location/application/location_providers.dart';
import '../../location/domain/start_presets.dart';
import '../../places/domain/place_category.dart';
import '../../profile/application/preferences_controller.dart';
import '../../transport/domain/transport_option.dart';
import '../domain/itinerary.dart';

class PlanForm extends ConsumerStatefulWidget {
  const PlanForm({super.key, required this.onSubmit, this.initial});

  final ValueChanged<ItineraryRequest> onSubmit;
  final ItineraryRequest? initial;

  @override
  ConsumerState<PlanForm> createState() => _PlanFormState();
}

/// `null` start preset means "my location".
class _PlanFormState extends ConsumerState<PlanForm> {
  late DateTime _date;
  late int _startMinute;
  late double _hours;
  StartPreset? _preset = StartPreset.thamel;
  late Set<PlaceCategory> _interests;
  late TravelStyle _style;

  @override
  void initState() {
    super.initState();
    final now = ref.read(nowProvider);
    final prefs = ref.read(preferencesProvider);
    final lateInDay = now.hour >= 17;
    _date = lateInDay ? dateOnly(now).add(const Duration(days: 1)) : dateOnly(now);
    _startMinute = lateInDay ? 9 * 60 : ((minuteOfDay(now) ~/ 30) + 1) * 30;
    _hours = lateInDay ? 8 : ((20 * 60 - _startMinute) / 60).clamp(2, 10).roundToDouble();
    _interests = {...prefs.interests};
    _style = prefs.travelStyle;
    if (ref.read(userLocationProvider) != null) _preset = null;
  }

  GeoPoint? get _startLocation => _preset?.location ?? ref.read(userLocationProvider);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final hasLocation = ref.watch(userLocationProvider) != null;
    if (!hasLocation && _preset == null) _preset = StartPreset.thamel;
    final today = dateOnly(ref.watch(nowProvider));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _FieldButton(
                label: l10n.planDate,
                value: DateFormat.MMMEd(l10n.localeName).format(_date),
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
            const SizedBox(width: 12),
            Expanded(
              child: _FieldButton(
                label: l10n.planStartTime,
                value: l10n.minuteOfDayTime(_startMinute),
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
        const SizedBox(height: 20),
        Text('${l10n.planTimeAvailable}: ${l10n.hoursValue(_hours.round())}', style: text.titleSmall),
        Slider(
          value: _hours,
          min: 1,
          max: 12,
          divisions: 11,
          label: l10n.hoursValue(_hours.round()),
          onChanged: (v) => setState(() => _hours = v),
        ),
        const SizedBox(height: 8),
        Text(l10n.planStartFrom, style: text.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<StartPreset?>(
          initialValue: _preset,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.trip_origin)),
          items: [
            if (hasLocation) DropdownMenuItem(value: null, child: Text(l10n.myLocation)),
            for (final p in StartPreset.values) DropdownMenuItem(value: p, child: Text(l10n.preset(p))),
          ],
          onChanged: (p) => setState(() => _preset = p),
        ),
        const SizedBox(height: 20),
        Text(l10n.planInterests, style: text.titleSmall),
        Text(l10n.planInterestsHint, style: text.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in PlaceCategory.values)
              FilterChip(
                avatar: Icon(c.icon, size: 18),
                label: Text(l10n.categoryName(c.name)),
                selected: _interests.contains(c),
                onSelected: (on) => setState(() => on ? _interests.add(c) : _interests.remove(c)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(l10n.planTravelStyle, style: text.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<TravelStyle>(
          segments: [
            for (final s in TravelStyle.values) ButtonSegment(value: s, label: Text(l10n.travelStyle(s.name))),
          ],
          selected: {_style},
          onSelectionChanged: (s) => setState(() => _style = s.single),
        ),
        const SizedBox(height: 4),
        Text(l10n.travelStyleHint(_style.name), style: text.bodySmall),
        const SizedBox(height: 28),
        FilledButton.icon(
          icon: const Icon(Icons.auto_awesome),
          label: Text(l10n.planButton),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _submit,
        ),
      ],
    );
  }

  void _submit() {
    final location = _startLocation ?? StartPreset.thamel.location;
    widget.onSubmit(ItineraryRequest(
      startTime: atMinuteOfDay(_date, _startMinute),
      availableMinutes: (_hours * 60).round(),
      start: StartPoint(_preset?.name ?? '', location),
      interests: {..._interests},
      travelStyle: _style,
    ));
  }
}

class _FieldButton extends StatelessWidget {
  const _FieldButton({required this.label, required this.value, required this.icon, required this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: Icon(icon)),
        child: Text(value),
      ),
    );
  }
}
