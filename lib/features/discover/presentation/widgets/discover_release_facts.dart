import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/discover/domain/models/discover_detail_model.dart';

class DiscoverReleaseFacts extends StatelessWidget {
  final String title;
  final List<_FactEntry> entries;
  final String? emptyMessage;

  const DiscoverReleaseFacts._({
    required this.title,
    required this.entries,
    this.emptyMessage,
  });

  factory DiscoverReleaseFacts.movie({
    required List<MovieRelease> releases,
    required String region,
  }) {
    final theatrical = _releaseByType(releases, 3);
    final digital = _releaseByType(releases, 4);
    final physical = _releaseByType(releases, 5);
    final entries = <_FactEntry>[];

    _addDatedFactEntry(entries, 'Theatrical', theatrical?.releaseDate);
    _addDatedFactEntry(entries, 'Digital', digital?.releaseDate);
    _addDatedFactEntry(entries, 'Physical', physical?.releaseDate);

    return DiscoverReleaseFacts._(
      title: 'Release Info',
      entries: entries,
      emptyMessage: entries.isEmpty
          ? 'Release info is not available in your region ($region).'
          : null,
    );
  }

  factory DiscoverReleaseFacts.tv({
    String? firstAirDate,
    String? lastAirDate,
    TvEpisodeSummary? nextEpisodeToAir,
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

    return DiscoverReleaseFacts._(
      title: 'Release Info',
      entries: entries,
      emptyMessage: entries.isEmpty ? 'No release info available.' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.filled(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (emptyMessage != null)
            Text(
              emptyMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        entry.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
