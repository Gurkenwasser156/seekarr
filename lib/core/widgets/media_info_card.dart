import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';

class MediaInfoCard extends StatelessWidget {
  final List<MediaInfoGroup> groups;

  const MediaInfoCard({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return _InfoGrid(
      cells: groups
          .map((group) => _InfoGridCell(label: group.title, child: group.child))
          .toList(growable: false),
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

    return _InfoGrid(
      cells: facts
          .map(
            (fact) => _InfoGridCell(
              label: fact.label,
              child: Text(
                fact.value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoGridCell> cells;

  const _InfoGrid({required this.cells});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 320;

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: cells
              .map(
                (cell) => SizedBox(
                  width: useSingleColumn
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.lg) / 2,
                  child: cell,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _InfoGridCell extends StatelessWidget {
  final String label;
  final Widget child;

  const _InfoGridCell({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        DefaultTextStyle.merge(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          child: child,
        ),
      ],
    );
  }
}

class MediaFact {
  final String label;
  final String value;

  const MediaFact(this.label, this.value);
}
