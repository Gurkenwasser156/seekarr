import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';

/// A row layout for media detail screens with poster on the left
/// and status badge + action buttons on the right.
///
/// Scales smoothly between expanded and collapsed sizes based on
/// [collapseFactor] (0.0 = fully expanded, 1.0 = fully collapsed).
class MediaDetailPosterRow extends StatelessWidget {
  /// The poster widget (typically a [MediaPosterCard]).
  /// Will be sized by the row based on [collapseFactor].
  final Widget posterCard;

  /// Optional status badge shown above the action buttons.
  final Widget? statusBadge;

  /// Action buttons displayed in a [Wrap] below the status badge.
  final List<Widget> actionButtons;

  /// Collapse progress: 0.0 = fully expanded, 1.0 = fully collapsed.
  final double collapseFactor;

  const MediaDetailPosterRow({
    super.key,
    required this.posterCard,
    required this.actionButtons,
    required this.collapseFactor,
    this.statusBadge,
  });

  // Poster dimensions at expanded state.
  static const expandedWidth = 120.0;
  static const expandedHeight = 180.0;

  // Poster dimensions at collapsed state.
  static const collapsedWidth = 80.0;
  static const collapsedHeight = 120.0;

  /// Threshold after which action buttons start fading out.
  ///
  /// Buttons are fully visible when [collapseFactor] ≤ this value
  /// and fully hidden when [collapseFactor] = 1.0.
  static const _buttonsFadeStart = 0.4;

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

    // Buttons fade out between _buttonsFadeStart and 1.0 to prevent overflow
    // in the collapsed state where vertical space is limited.
    final buttonsOpacity = collapseFactor <= _buttonsFadeStart
        ? 1.0
        : (1.0 -
                  ((collapseFactor - _buttonsFadeStart) /
                      (1.0 - _buttonsFadeStart)))
              .clamp(0.0, 1.0);

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
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (actionButtons.isNotEmpty)
                  Flexible(
                    child: IgnorePointer(
                      ignoring: buttonsOpacity == 0,
                      child: Opacity(
                        opacity: buttonsOpacity,
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: actionButtons,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
