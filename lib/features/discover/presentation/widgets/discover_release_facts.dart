import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/discover/domain/models/discover_detail_model.dart';

class DiscoverReleaseInfoCard extends StatelessWidget {
  final List<_FactEntry> releaseEntries;
  final String? emptyMessage;
  final List<String> genresList;
  final List<String> studios;
  final List<String> directors;
  final List<String> writers;
  final String networks;

  const DiscoverReleaseInfoCard._({
    required this.releaseEntries,
    this.emptyMessage,
    this.genresList = const [],
    this.studios = const [],
    this.directors = const [],
    this.writers = const [],
    this.networks = '',
  });

  factory DiscoverReleaseInfoCard.movie({
    required List<MovieRelease> releases,
    required String region,
    List<String> genresList = const [],
    List<String> studios = const [],
    List<String> directors = const [],
    List<String> writers = const [],
  }) {
    final theatrical = _releaseByType(releases, 3);
    final digital = _releaseByType(releases, 4);
    final physical = _releaseByType(releases, 5);
    final entries = <_FactEntry>[];

    _addDatedFactEntry(entries, 'Theatrical', theatrical?.releaseDate);
    _addDatedFactEntry(entries, 'Digital', digital?.releaseDate);
    _addDatedFactEntry(entries, 'Physical', physical?.releaseDate);

    return DiscoverReleaseInfoCard._(
      releaseEntries: entries,
      emptyMessage: entries.isEmpty
          ? 'Release info is not available in your region ($region).'
          : null,
      genresList: genresList,
      studios: studios,
      directors: directors,
      writers: writers,
    );
  }

  factory DiscoverReleaseInfoCard.tv({
    String? firstAirDate,
    String? lastAirDate,
    TvEpisodeSummary? nextEpisodeToAir,
    List<String> genresList = const [],
    List<String> studios = const [],
    List<String> directors = const [],
    List<String> writers = const [],
    String networks = '',
  }) {
    final entries = <_FactEntry>[];

    _addDatedFactEntry(entries, 'First Aired', firstAirDate);
    _addDatedFactEntry(entries, 'Last Aired', lastAirDate);
    if (nextEpisodeToAir != null &&
        (nextEpisodeToAir.airDate?.isNotEmpty ?? false)) {
      final parts = <String>[];
      if (nextEpisodeToAir.seasonNumber != null &&
          nextEpisodeToAir.episodeNumber != null) {
        parts.add(
          'S${nextEpisodeToAir.seasonNumber}E${nextEpisodeToAir.episodeNumber}',
        );
      }
      if ((nextEpisodeToAir.name?.isNotEmpty ?? false)) {
        parts.add(nextEpisodeToAir.name!);
      }
      parts.add(_formatDate(nextEpisodeToAir.airDate!));

      entries.add(_FactEntry('Next Episode', parts.join(' • ')));
    }

    return DiscoverReleaseInfoCard._(
      releaseEntries: entries,
      emptyMessage: entries.isEmpty ? 'No release info available.' : null,
      genresList: genresList,
      studios: studios,
      directors: directors,
      writers: writers,
      networks: networks,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sectionChildren = <Widget>[
      _InfoGroup(
        title: 'Release Dates',
        child: emptyMessage != null
            ? Text(
                emptyMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : _FactsList(entries: releaseEntries),
      ),
      if (genresList.isNotEmpty)
        _InfoGroup(
          title: 'Genre',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: genresList
                .map((genre) => GenreChip(genre: genre))
                .toList(growable: false),
          ),
        ),
      if (studios.isNotEmpty)
        _InfoGroup(
          title: 'Studios',
          child: Text(studios.join(', '), style: theme.textTheme.bodyMedium),
        ),
      if (networks.isNotEmpty)
        _InfoGroup(
          title: 'Networks',
          child: Text(networks, style: theme.textTheme.bodyMedium),
        ),
      if (directors.isNotEmpty || writers.isNotEmpty)
        _InfoGroup(
          title: 'Crew',
          child: _FactsList(
            entries: [
              if (directors.isNotEmpty)
                _FactEntry('Director', directors.join(', ')),
              if (writers.isNotEmpty) _FactEntry('Writer', writers.join(', ')),
            ],
          ),
        ),
    ];

    return AppCard.filled(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < sectionChildren.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.lg),
            sectionChildren[index],
          ],
        ],
      ),
    );
  }
}

class _InfoGroup extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoGroup({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _FactsList extends StatelessWidget {
  final List<_FactEntry> entries;

  const _FactsList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  entries[index].label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  entries[index].value,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FactEntry {
  final String label;
  final String value;

  const _FactEntry(this.label, this.value);
}

void _addDatedFactEntry(List<_FactEntry> entries, String label, String? value) {
  if (value == null || value.isEmpty) {
    return;
  }

  entries.add(_FactEntry(label, _formatDate(value)));
}

MovieRelease? _releaseByType(List<MovieRelease> releases, int type) {
  for (final release in releases) {
    if (release.type == type && release.releaseDate.isNotEmpty) {
      return release;
    }
  }

  return null;
}

String _formatDate(String value) {
  if (value.isEmpty) {
    return '';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.split('T').first;
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}
