import 'package:flutter/material.dart';
import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';

class RatingChip extends StatelessWidget {
  final String value;
  final int votes;
  final String sourceName;
  final String sourceIcon;
  final VoidCallback? onTap;

  const RatingChip({
    super.key,
    required this.value,
    required this.votes,
    required this.sourceName,
    required this.sourceIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedVotes = _formatVoteCount(votes);
    final displayText = formattedVotes.isNotEmpty
        ? '$value ($formattedVotes)'
        : value;

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: sourceName,
        preferBelow: true,
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: AppRadius.borderRadiusFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sourceIcon,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                displayText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatVoteCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
