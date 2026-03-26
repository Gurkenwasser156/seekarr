import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/models/rating_source.dart';
import 'package:seekarr/core/widgets/rating_chip.dart';

/// Displays a horizontal wrap of [RatingChip] widgets from a list of
/// [RatingSource].
class RatingChipsRow extends StatelessWidget {
  final List<RatingSource> ratings;

  const RatingChipsRow({super.key, required this.ratings});

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: ratings.map((rating) {
            return RatingChip(
              value: rating.value.toStringAsFixed(1),
              votes: rating.votes,
              sourceName: rating.name,
              sourceIcon: rating.icon,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
