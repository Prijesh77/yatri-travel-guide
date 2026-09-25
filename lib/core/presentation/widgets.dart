import 'package:flutter/material.dart';

/// Screen title with a rounded icon tile, as in the wireframes
/// ("Find your route", "Live conditions", "Plan with AI", ...).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.background,
    this.action,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color background;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          ?action,
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small coloured pill ("rerouted", "event", "Verified 2026").
class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key, required this.color, required this.background, this.icon});
  final String text;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Grey rounded card used for list items in the wireframes.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.onTap, this.highlighted = false, this.padding});
  final Widget child;
  final VoidCallback? onTap;
  final bool highlighted;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: highlighted ? scheme.primaryContainer.withValues(alpha: 0.35) : scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: highlighted ? BorderSide(color: scheme.primary.withValues(alpha: 0.5)) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding ?? const EdgeInsets.all(14), child: child),
      ),
    );
  }
}

/// Read-only field that opens a picker when tapped.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.value,
    required this.hint,
    required this.onTap,
    this.dotColor,
    this.icon,
  });

  final String? value;
  final String hint;
  final VoidCallback onTap;
  final Color? dotColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (dotColor != null) ...[
          Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(prefixIcon: icon == null ? null : Icon(icon)),
              child: Text(
                value ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: value == null
                    ? theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                    : theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
