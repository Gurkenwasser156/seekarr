import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/discover/domain/models/discover_detail_model.dart';
import 'package:seekarr/features/discover/domain/models/jellyseerr_request.dart';

class DiscoverSeasonsList extends StatelessWidget {
  final List<TvSeason> seasons;
  final Map<String, dynamic>? mediaInfo;

  const DiscoverSeasonsList({
    super.key,
    required this.seasons,
    required this.mediaInfo,
  });

  @override
  Widget build(BuildContext context) {
    final orderedSeasons = [...seasons]..sort(_compareSeasons);
    final availabilityBySeason = _availabilityBySeason(mediaInfo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seasons', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        AppCard.filled(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < orderedSeasons.length; index++) ...[
                _SeasonRow(
                  season: orderedSeasons[index],
                  availability:
                      availabilityBySeason[orderedSeasons[index].seasonNumber],
                ),
                if (index < orderedSeasons.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Map<int, MediaAvailability> _availabilityBySeason(
    Map<String, dynamic>? currentMediaInfo,
  ) {
    final seasonsData = currentMediaInfo?['seasons'];
    if (seasonsData is! List) {
      return const {};
    }

    final results = <int, MediaAvailability>{};

    for (final item in seasonsData) {
      if (item is! Map) {
        continue;
      }

      final seasonNumber = _asInt(item['seasonNumber']);
      if (seasonNumber == null) {
        continue;
      }

      results[seasonNumber] = MediaAvailability.fromCode(item['status']);
    }

    return results;
  }
}

class _SeasonRow extends StatelessWidget {
  final TvSeason season;
  final MediaAvailability? availability;

  const _SeasonRow({required this.season, required this.availability});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayName = season.name.isNotEmpty
        ? season.name
        : 'Season ${season.seasonNumber}';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${season.episodeCount} episodes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (availability == MediaAvailability.available)
            const _SeasonAvailabilityChip(
              label: 'Available',
              backgroundColor: AppColors.success,
            )
          else if (availability == MediaAvailability.partiallyAvailable)
            const _SeasonAvailabilityChip(
              label: 'Partial',
              backgroundColor: AppColors.warning,
            ),
        ],
      ),
    );
  }
}

class _SeasonAvailabilityChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const _SeasonAvailabilityChip({
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.18),
        borderRadius: AppRadius.borderRadiusSm,
        border: Border.all(color: backgroundColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: backgroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

int _compareSeasons(TvSeason left, TvSeason right) {
  if (left.seasonNumber == 0 && right.seasonNumber != 0) {
    return 1;
  }

  if (left.seasonNumber != 0 && right.seasonNumber == 0) {
    return -1;
  }

  return left.seasonNumber.compareTo(right.seasonNumber);
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}
