import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/media_detail_hero_summary.dart';

/// Prototype-style hero title row for media detail screens.
class MediaDetailPosterRow extends StatelessWidget {
  /// The poster widget (typically a [MediaPosterCard]).
  final Widget posterCard;

  /// Optional status badge shown above the actions.
  final Widget? statusBadge;

  /// Deprecated: actions now render below the hero in the prototype layout.
  final Widget? actions;

  /// Title shown in the prototype-style hero copy block.
  final String? title;

  /// Metadata shown below [title], joined by the caller.
  final List<String> metadataItems;

  /// Inline genre/status chips shown below metadata.
  final List<Widget> tags;

  /// Whether the poster should use the circular artist treatment.
  final bool circularPoster;

  /// Deprecated: kept to avoid churn in existing call sites.
  final double collapseFactor;

  const MediaDetailPosterRow({
    super.key,
    required this.posterCard,
    required this.collapseFactor,
    this.statusBadge,
    this.actions,
    this.title,
    this.metadataItems = const [],
    this.tags = const [],
    this.circularPoster = false,
  });

  // Poster dimensions at expanded state.
  static const expandedWidth = 68.0;
  static const expandedHeight = 102.0;

  // Poster dimensions at collapsed state.
  static const collapsedWidth = 52.0;
  static const collapsedHeight = 78.0;

  /// Calculates the vertical gap between action rows based on collapse progress.
  ///
  /// Lerps from [AppSpacing.sm] (expanded) to [AppSpacing.xs] (collapsed)
  /// for a tighter layout in the collapsed state.
  static double actionGap(double collapseFactor) =>
      lerpDouble(AppSpacing.sm, AppSpacing.xs, collapseFactor)!;

  @override
  Widget build(BuildContext context) {
    const posterWidth = expandedWidth;
    const posterHeight = expandedHeight;
    final effectivePosterWidth = circularPoster ? 80.0 : posterWidth;
    final effectivePosterHeight = circularPoster ? 80.0 : posterHeight;
    final showTextContent =
        title != null ||
        statusBadge != null ||
        metadataItems.any((item) => item.trim().isNotEmpty) ||
        tags.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: effectivePosterWidth,
          height: effectivePosterHeight,
          child: posterCard,
        ),
        if (showTextContent) ...[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _HeroSummaryBlock(
              title: title,
              statusBadge: statusBadge,
              metadataItems: metadataItems,
              tags: tags,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroSummaryBlock extends StatelessWidget {
  final String? title;
  final Widget? statusBadge;
  final List<String> metadataItems;
  final List<Widget> tags;

  const _HeroSummaryBlock({
    required this.title,
    required this.statusBadge,
    required this.metadataItems,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (statusBadge != null) ...[
          statusBadge!,
          const SizedBox(height: AppSpacing.xs),
        ],
        if (title != null && title!.trim().isNotEmpty)
          MediaDetailHeroSummaryCard(
            title: title!,
            metadataItems: metadataItems,
            tags: tags.take(3).toList(growable: false),
          ),
      ],
    );
  }
}
