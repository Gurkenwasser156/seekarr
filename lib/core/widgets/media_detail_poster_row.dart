import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';

/// A row layout for media detail screens with poster on the left
/// and status badge + action content on the right.
///
/// Scales smoothly between expanded and collapsed sizes based on
/// [collapseFactor] (0.0 = fully expanded, 1.0 = fully collapsed).
class MediaDetailPosterRow extends StatelessWidget {
  /// The poster widget (typically a [MediaPosterCard]).
  /// Will be sized by the row based on [collapseFactor].
  final Widget posterCard;

  /// Optional status badge shown above the actions.
  final Widget? statusBadge;

  /// Action content displayed below the status badge.
  ///
  /// Typically a [Column] of [HeaderActionRow] widgets. The caller
  /// should use [actionGap] for consistent vertical spacing between rows.
  final Widget? actions;

  /// Collapse progress: 0.0 = fully expanded, 1.0 = fully collapsed.
  final double collapseFactor;

  const MediaDetailPosterRow({
    super.key,
    required this.posterCard,
    required this.collapseFactor,
    this.statusBadge,
    this.actions,
  });

  // Poster dimensions at expanded state.
  static const expandedWidth = 120.0;
  static const expandedHeight = 180.0;

  // Poster dimensions at collapsed state.
  static const collapsedWidth = 80.0;
  static const collapsedHeight = 120.0;

  /// Calculates the vertical gap between action rows based on collapse progress.
  ///
  /// Lerps from [AppSpacing.sm] (expanded) to [AppSpacing.xs] (collapsed)
  /// for a tighter layout in the collapsed state.
  static double actionGap(double collapseFactor) =>
      lerpDouble(AppSpacing.sm, AppSpacing.xs, collapseFactor)!;

  @override
  Widget build(BuildContext context) {
    final posterWidth = lerpDouble(
      expandedWidth,
      collapsedWidth,
      collapseFactor,
    )!;
    final posterHeight = lerpDouble(
      expandedHeight,
      collapsedHeight,
      collapseFactor,
    )!;
    final gap = actionGap(collapseFactor);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: posterWidth, height: posterHeight, child: posterCard),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: SizedBox(
            height: posterHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (statusBadge != null) ...[
                  statusBadge!,
                  SizedBox(height: gap),
                ],
                if (actions != null) Flexible(child: actions!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
