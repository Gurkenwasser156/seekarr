import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/app_card.dart';

class MediaInfoCard extends StatelessWidget {
  final List<MediaInfoGroup> groups;

  const MediaInfoCard({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard.filled(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < groups.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.lg),
            _MediaInfoGroupView(group: groups[index]),
          ],
        ],
      ),
    );
  }
}

class MediaInfoGroup {
  final String title;
  final Widget child;

  const MediaInfoGroup({required this.title, required this.child});
}

class MediaFactsList extends StatelessWidget {
  final List<MediaFact> facts;

  const MediaFactsList({super.key, required this.facts});

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < facts.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  facts[index].label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  facts[index].value,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class MediaFact {
  final String label;
  final String value;

  const MediaFact(this.label, this.value);
}

class _MediaInfoGroupView extends StatelessWidget {
  final MediaInfoGroup group;

  const _MediaInfoGroupView({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        group.child,
      ],
    );
  }
}
