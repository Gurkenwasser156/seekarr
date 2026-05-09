import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:seekarr/features/series/presentation/series_provider.dart';
import 'package:seekarr/features/series/presentation/series_search_provider.dart';

class SeriesScreen extends StatelessWidget {
  final bool showAppBar;
  final double topPadding;

  const SeriesScreen({super.key, this.showAppBar = true, this.topPadding = 0});

  @override
  Widget build(BuildContext context) {
    return MediaBrowseScaffold<SonarrSeries>(
      title: 'TV Series',
      searchHint: 'Search TV series...',
      activityRoute: '/activity/series',
      navigationSection: NavigationSection.services,
      serviceName: 'Sonarr',
      heroTagPrefix: 'series',
      searchHeroTagPrefix: 'series_search',
      libraryProvider: seriesProvider,
      searchQueryProvider: seriesSearchQueryProvider,
      searchResultsProvider: seriesSearchResultsProvider,
      imagesExtractor: (series) => series.images,
      idExtractor: (series) => series.id,
      statusExtractor: (series) {
        final stats = series.statistics;
        final episodeFileCount =
            (stats?['episodeFileCount'] as num?)?.toInt() ?? 0;
        final episodeCount = (stats?['episodeCount'] as num?)?.toInt() ?? 0;
        return MediaAvailabilityInfo(
          hasFile: episodeFileCount > 0,
          status: series.status,
          fileCount: episodeFileCount,
          totalCount: episodeCount,
        );
      },
      settingsSelector: (settings) =>
          (settings.sonarrUrl, settings.sonarrApiKey),
      onItemTap: (context, series, heroTag) {
        context.go(
          '/services/sonarr/series/${series.id}?heroTag=$heroTag',
          extra: series,
        );
      },
      showAppBar: showAppBar,
      topPadding: topPadding,
    );
  }
}
