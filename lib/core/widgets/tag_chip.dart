import 'package:flutter/material.dart';

/// A reusable tag/chip widget for displaying metadata labels.
///
/// Used in detail screens to show year, status, runtime, etc.
class TagChip extends StatelessWidget {
  final String text;
  final Color? color;

  const TagChip({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            color?.withValues(alpha: 0.2) ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: color != null
            ? Border.all(color: color!.withValues(alpha: 0.5))
            : null,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
