import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/series/domain/models/sonarr_episode.dart';

class SeriesSeasonsList extends StatefulWidget {
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
  State<SeriesSeasonsList> createState() => _SeriesSeasonsListState();
}

class _SeriesSeasonsListState extends State<SeriesSeasonsList> {
  int? _selectedSeasonNumber;

  @override
  Widget build(BuildContext context) {
    if (widget.seasons.isEmpty) {
      return Text(
        'No seasons found.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final sortedSeasons = List<dynamic>.from(widget.seasons)
      ..sort((a, b) => _compareSeasons(_seasonNumber(a), _seasonNumber(b)));
    final selectedSeason = _selectedSeason(sortedSeasons);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < sortedSeasons.length; index++) ...[
                _SeasonPill(
                  season: sortedSeasons[index],
                  selected:
                      _seasonNumber(sortedSeasons[index]) ==
                      _seasonNumber(selectedSeason),
                  isSearching: widget.searchingSeasons.contains(
                    _seasonNumber(sortedSeasons[index]),
                  ),
                  onSelected: () => setState(
                    () => _selectedSeasonNumber = _seasonNumber(
                      sortedSeasons[index],
                    ),
                  ),
                ),
                if (index < sortedSeasons.length - 1)
                  const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SelectedSeasonPanel(
          season: selectedSeason,
          episodesAsync: widget.episodesAsync,
          onSearchSeason: widget.onSearchSeason,
          onInteractiveSearchSeason: widget.onInteractiveSearchSeason,
          onSearchEpisode: widget.onSearchEpisode,
          onInteractiveSearchEpisode: widget.onInteractiveSearchEpisode,
          isSeasonSearching: widget.searchingSeasons.contains(
            _seasonNumber(selectedSeason),
          ),
          searchingEpisodes: widget.searchingEpisodes,
        ),
      ],
    );
  }

  dynamic _selectedSeason(List<dynamic> sortedSeasons) {
    final selectedNumber = _selectedSeasonNumber;
    if (selectedNumber != null) {
      for (final season in sortedSeasons) {
        if (_seasonNumber(season) == selectedNumber) {
          return season;
        }
      }
    }

    return sortedSeasons.first;
  }
}

class _SeasonPill extends StatelessWidget {
  final dynamic season;
  final bool selected;
  final bool isSearching;
  final VoidCallback onSelected;

  const _SeasonPill({
    required this.season,
    required this.selected,
    required this.isSearching,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final seasonNumber = _seasonNumber(season);

    return ChoiceChip(
      label: Text(seasonNumber == 0 ? 'Specials' : 'S$seasonNumber'),
      avatar: isSearching
          ? SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : null,
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: selected ? colorScheme.onSecondaryContainer : null,
      ),
    );
  }
}

class _SelectedSeasonPanel extends StatelessWidget {
  final dynamic season;
  final AsyncValue<List<SonarrEpisode>> episodesAsync;
  final void Function(int seasonNumber) onSearchSeason;
  final void Function(int seasonNumber) onInteractiveSearchSeason;
  final void Function(int episodeId) onSearchEpisode;
  final void Function(int episodeId) onInteractiveSearchEpisode;
  final bool isSeasonSearching;
  final Set<int> searchingEpisodes;

  const _SelectedSeasonPanel({
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
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.borderRadiusSm,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  seasonNumber == 0 ? 'Specials' : 'Season $seasonNumber',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              MediaSearchPopupMenu(
                onAutoSearch: () => onSearchSeason(seasonNumber),
                onInteractiveSearch: () =>
                    onInteractiveSearchSeason(seasonNumber),
                isLoading: isSeasonSearching,
                iconSize: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                monitored ? Icons.bookmark : Icons.bookmark_border,
                size: 18,
                color: monitored ? colorScheme.tertiary : colorScheme.outline,
              ),
            ],
          ),
          Text(
            '$episodeFileCount / $totalEpisodeCount Episodes',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.borderRadiusXs,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._buildEpisodeChildren(
            context,
            seasonEpisodes: seasonEpisodes,
            seasonNumber: seasonNumber,
          ),
        ],
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
          padding: const EdgeInsets.all(AppSpacing.sm),
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
          (episode) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    episode.episodeNumber.toString().padLeft(2, '0'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                MediaSearchPopupMenu(
                  onAutoSearch: () => onSearchEpisode(episode.id),
                  onInteractiveSearch: () =>
                      onInteractiveSearchEpisode(episode.id),
                  isLoading: searchingEpisodes.contains(episode.id),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: episode.hasFile
                        ? colorScheme.primary
                        : colorScheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
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

int _compareSeasons(int left, int right) {
  if (left == 0 && right != 0) {
    return 1;
  }

  if (left != 0 && right == 0) {
    return -1;
  }

  return left.compareTo(right);
}
