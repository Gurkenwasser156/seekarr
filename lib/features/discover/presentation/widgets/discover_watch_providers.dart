import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/discover/domain/models/discover_detail_model.dart';

class DiscoverWatchProviders extends StatelessWidget {
  final WatchProviderRegion? providers;
  final String region;

  const DiscoverWatchProviders({
    super.key,
    required this.providers,
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where to Watch', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        AppCard.filled(
          child: providers == null
              ? Text(
                  'Watch provider info is not available in your region ($region).',
                  style: mutedTextStyle,
                )
              : _ProvidersContent(providers: providers!),
        ),
      ],
    );
  }
}

class _ProvidersContent extends StatelessWidget {
  final WatchProviderRegion providers;

  const _ProvidersContent({required this.providers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (providers.flatrate.isEmpty && providers.buy.isEmpty) {
      return Text(
        'No streaming or purchase options available.',
        style: mutedTextStyle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (providers.flatrate.isNotEmpty) ...[
          Text('Stream', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          _WatchProviderRow(entries: providers.flatrate),
        ],
        if (providers.flatrate.isNotEmpty && providers.buy.isNotEmpty)
          const SizedBox(height: AppSpacing.lg),
        if (providers.buy.isNotEmpty) ...[
          Text('Buy', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          _WatchProviderRow(entries: providers.buy),
        ],
      ],
    );
  }
}

class _WatchProviderRow extends StatelessWidget {
  final List<WatchProviderEntry> entries;

  const _WatchProviderRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) =>
            _WatchProviderTile(entry: entries[index]),
      ),
    );
  }
}

class _WatchProviderTile extends StatelessWidget {
  final WatchProviderEntry entry;

  const _WatchProviderTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final logoPath = entry.logoPath;

    return SizedBox(
      width: 60,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: AppRadius.borderRadiusSm,
            child: Container(
              width: 40,
              height: 40,
              color: colorScheme.surfaceContainerHighest,
              child: logoPath != null && logoPath.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: 'https://image.tmdb.org/t/p/w92$logoPath',
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                        Icons.play_circle_outline,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Icon(
                      Icons.play_circle_outline,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            entry.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
