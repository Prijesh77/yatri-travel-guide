import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/formatters.dart';
import '../../../core/presentation/l10n.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/providers/core_providers.dart';
import '../../location/presentation/location_picker.dart';
import '../application/alerts_providers.dart';
import '../data/community_reports_repository.dart';
import '../domain/condition_alert.dart';

Future<void> showReportSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ReportSheet(),
    );

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet();

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  AlertType _type = AlertType.roadClosure;
  LocationChoice? _where;
  final _title = TextEditingController();
  late TimeOfDay _eventStart = TimeOfDay.fromDateTime(ref.read(nowProvider));
  int _eventHours = 3;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = _where != null && _title.text.trim().length >= 3;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.reportTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in [AlertType.roadClosure, AlertType.traffic, AlertType.bandh, AlertType.closure, AlertType.festival])
                  ChoiceChip(
                    label: Text(l10n.alertType(t.name)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 80,
              decoration: InputDecoration(labelText: l10n.whatsHappening, hintText: l10n.reportHint(_type.name)),
              onChanged: (_) => setState(() {}),
            ),
            PickerField(
              value: _where?.label,
              hint: l10n.where,
              icon: Icons.place_outlined,
              onTap: () async {
                final c = await showLocationPicker(context, title: l10n.where);
                if (c != null) setState(() => _where = c);
              },
            ),
            if (_type == AlertType.festival) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PickerField(
                      value: context.l10n.minuteOfDayTime(_eventStart.hour * 60 + _eventStart.minute),
                      hint: l10n.planStartTime,
                      icon: Icons.schedule,
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _eventStart);
                        if (t != null) setState(() => _eventStart = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _eventHours,
                    items: [for (final h in [1, 2, 3, 4, 6, 8]) DropdownMenuItem(value: h, child: Text(l10n.hoursValue(h)))],
                    onChanged: (h) => setState(() => _eventHours = h ?? 3),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: valid ? _submit : null,
              child: Text(l10n.submit),
            ),
            const SizedBox(height: 4),
            Text(l10n.reportsOnDevice, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final now = ref.read(nowProvider);
    final isEvent = _type == AlertType.festival;
    await ref.read(communityReportsProvider.notifier).report(NewReport(
          type: _type,
          title: _title.text,
          location: _where!.point,
          locationLabel: _where!.label,
          start: isEvent ? DateTime.utc(now.year, now.month, now.day, _eventStart.hour, _eventStart.minute) : null,
          duration: isEvent ? Duration(hours: _eventHours) : null,
        ));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportThanks)));
  }
}
