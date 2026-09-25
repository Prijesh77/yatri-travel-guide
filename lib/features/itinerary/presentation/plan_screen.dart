import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/l10n.dart';
import '../application/itinerary_controller.dart';
import 'itinerary_view.dart';
import 'plan_form.dart';

/// Plan tab: the form when there is no plan (or when making a new one),
/// otherwise the editable itinerary.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final itinerary = ref.watch(itineraryControllerProvider);
    final showForm = _editing || (itinerary.hasValue && itinerary.value == null);

    return Scaffold(
      appBar: AppBar(
        title: Text(showForm ? l10n.planYourDay : l10n.itineraryTitle),
        leading: _editing && itinerary.value != null
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _editing = false))
            : null,
        actions: [
          if (!showForm && itinerary.value != null)
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.newPlan),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: switch (itinerary) {
        _ when showForm => PlanForm(
            initial: itinerary.value?.request,
            onSubmit: (request) async {
              setState(() => _editing = false);
              await ref.read(itineraryControllerProvider.notifier).plan(request);
            },
          ),
        AsyncValue(:final value?) => ItineraryView(itinerary: value),
        AsyncError(:final error) => Center(child: Text('${l10n.errorLoading}\n$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
