import 'package:flutter/material.dart';

class MediaMetadataLine extends StatelessWidget {
  final List<String> items;
  final TextAlign textAlign;

  const MediaMetadataLine({
    super.key,
    required this.items,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final joined = items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(' • ');

    if (joined.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: Text(
        joined,
        textAlign: textAlign,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
