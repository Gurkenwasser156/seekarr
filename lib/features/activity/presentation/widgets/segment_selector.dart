import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';

enum ActivitySegment {
  queue('Queue'),
  history('History'),
  blocklist('Blocklist');

  final String label;

  const ActivitySegment(this.label);
}

enum WantedSegment {
  missing('Missing'),
  cutoffUnmet('Cutoff Unmet');

  final String label;

  const WantedSegment(this.label);
}

class ActivitySegmentSelector<T extends Enum> extends StatelessWidget {
  final List<T> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;

  const ActivitySegmentSelector({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ActivitySegmentHeaderDelegate<T>(
        segments: segments,
        selected: selected,
        onChanged: onChanged,
        labelBuilder: labelBuilder,
      ),
    );
  }
}

class _ActivitySegmentHeaderDelegate<T extends Enum>
    extends SliverPersistentHeaderDelegate {
  final List<T> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;

  const _ActivitySegmentHeaderDelegate({
    required this.segments,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.center,
                child: SegmentedButton<T>(
                  showSelectedIcon: false,
                  segments: segments
                      .map(
                        (segment) => ButtonSegment<T>(
                          value: segment,
                          label: Text(labelBuilder(segment)),
                        ),
                      )
                      .toList(growable: false),
                  selected: {selected},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      onChanged(selection.first);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ActivitySegmentHeaderDelegate<T> oldDelegate) {
    return selected != oldDelegate.selected ||
        segments != oldDelegate.segments ||
        labelBuilder != oldDelegate.labelBuilder ||
        onChanged != oldDelegate.onChanged;
  }
}
