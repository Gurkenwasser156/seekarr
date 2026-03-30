import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/series/domain/models/sonarr_episode.dart';

class SeriesSeasonsList extends StatelessWidget {
  final List<dynamic> seasons;
  final AsyncValue<List<SonarrEpisode>> episodesAsync;
  final void Function(int seasonNumber) onSearchSeason;
  final void Function(int seasonNumber) onInteractiveSearchSeason;
  final void Function(int episodeId) onSearchEpisode;
  final void Function(int episodeId) onInteractiveSearchEpisode;
  final Set<int> searchingSeasons;
  final Set<int> searchingEpisodes;

  const SeriesSeasonsList({
    super.key,
    required this.seasons,
    required this.episodesAsync,
    required this.onSearchSeason,
    required this.onInteractiveSearchSeason,
    required this.onSearchEpisode,
    required this.onInteractiveSearchEpisode,
    required this.searchingSeasons,
    required this.searchingEpisodes,
  });

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) {
      return Text(
        'No seasons found.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final sortedSeasons = List<dynamic>.from(seasons)
      ..sort((a, b) => _seasonNumber(a).compareTo(_seasonNumber(b)));

    return Column(
      children: sortedSeasons
          .map(
            (season) => _SeasonTile(
              season: season,
              episodesAsync: episodesAsync,
              onSearchSeason: onSearchSeason,
              onInteractiveSearchSeason: onInteractiveSearchSeason,
              onSearchEpisode: onSearchEpisode,
              onInteractiveSearchEpisode: onInteractiveSearchEpisode,
              isSeasonSearching: searchingSeasons.contains(
                _seasonNumber(season),
              ),
              searchingEpisodes: searchingEpisodes,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SeasonTile extends StatelessWidget {
  final dynamic season;
  final AsyncValue<List<SonarrEpisode>> episodesAsync;
  final void Function(int seasonNumber) onSearchSeason;
  final void Function(int seasonNumber) onInteractiveSearchSeason;
  final void Function(int episodeId) onSearchEpisode;
  final void Function(int episodeId) onInteractiveSearchEpisode;
  final bool isSeasonSearching;
  final Set<int> searchingEpisodes;

  const _SeasonTile({
    required this.season,
    required this.episodesAsync,
    required this.onSearchSeason,
    required this.onInteractiveSearchSeason,
    required this.onSearchEpisode,
    required this.onInteractiveSearchEpisode,
    required this.isSeasonSearching,
    required this.searchingEpisodes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final seasonNumber = _seasonNumber(season);
    final stats = _seasonStatistics(season);
    final episodeFileCount = (stats?['episodeFileCount'] as num?)?.toInt() ?? 0;
    final totalEpisodeCount =
        (stats?['totalEpisodeCount'] as num?)?.toInt() ?? 0;
    final monitored = season['monitored'] as bool? ?? false;
    final progress = totalEpisodeCount > 0
        ? episodeFileCount / totalEpisodeCount
        : 0.0;
    final progressColor = progress >= 1
        ? colorScheme.primary
        : progress > 0
        ? colorScheme.tertiary
        : colorScheme.outline;
    final episodes = episodesAsync.asData?.value ?? const <SonarrEpisode>[];
    final seasonEpisodes =
        episodes
            .where((episode) => episode.seasonNumber == seasonNumber)
            .toList(growable: false)
          ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Text(
            seasonNumber == 0 ? 'S' : seasonNumber.toString(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          seasonNumber == 0 ? 'Specials' : 'Season $seasonNumber',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$episodeFileCount / $totalEpisodeCount Episodes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.borderRadiusXs,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: AppSpacing.xs,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MediaSearchPopupMenu(
              onAutoSearch: () => onSearchSeason(seasonNumber),
              onInteractiveSearch: () =>
                  onInteractiveSearchSeason(seasonNumber),
              isLoading: isSeasonSearching,
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              monitored ? Icons.bookmark : Icons.bookmark_border,
              color: monitored ? colorScheme.tertiary : colorScheme.outline,
            ),
          ],
        ),
        children: _buildEpisodeChildren(
          context,
          seasonEpisodes: seasonEpisodes,
          seasonNumber: seasonNumber,
        ),
      ),
    );
  }

  List<Widget> _buildEpisodeChildren(
    BuildContext context, {
    required List<SonarrEpisode> seasonEpisodes,
    required int seasonNumber,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (episodesAsync.isLoading && episodesAsync.asData?.value == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (episodesAsync.hasError && episodesAsync.asData?.value == null) {
      return [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Failed to load episodes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
      ];
    }

    if (seasonEpisodes.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            seasonNumber == 0
                ? 'No specials found.'
                : 'No episodes found for this season.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    return seasonEpisodes
        .map(
          (episode) => ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: AppSpacing.md,
              backgroundColor: episode.hasFile
                  ? colorScheme.primary
                  : colorScheme.outline,
              child: Text(
                episode.episodeNumber.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: episode.hasFile
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(episode.title, style: theme.textTheme.bodyMedium),
            trailing: MediaSearchPopupMenu(
              onAutoSearch: () => onSearchEpisode(episode.id),
              onInteractiveSearch: () => onInteractiveSearchEpisode(episode.id),
              isLoading: searchingEpisodes.contains(episode.id),
            ),
          ),
        )
        .toList(growable: false);
  }
}

int _seasonNumber(dynamic season) =>
    (season['seasonNumber'] as num?)?.toInt() ?? 0;

Map<String, dynamic>? _seasonStatistics(dynamic season) {
  final stats = season['statistics'];
  return stats is Map<String, dynamic> ? stats : null;
}
