import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/async_value_widget.dart';
import 'package:seekarr/core/widgets/media_grid.dart';
import 'package:seekarr/core/widgets/search_bar_header.dart';
import 'package:seekarr/features/series/presentation/series_provider.dart';
import 'package:seekarr/features/series/presentation/series_search_provider.dart';
import 'package:seekarr/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesProvider);
    final settings = ref.watch(settingsProvider);
    final searchQuery = ref.watch(seriesSearchQueryProvider);
    final searchResults = ref.watch(seriesSearchResultsProvider);

    // Listen for navigation refresh trigger
    ref.listen<int>(navigationRefreshProvider(NavigationSection.series), (
      previous,
      next,
    ) {
      // Clear search query and invalidate provider
      ref.read(seriesSearchQueryProvider.notifier).state = '';
      ref.invalidate(seriesProvider);
    });

    return Scaffold(
      appBar: AppBar(
        leading: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(seriesSearchQueryProvider.notifier).state = '';
                },
                tooltip: 'Exit search',
              )
            : null,
        title: const Text('TV Series'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/activity/series'),
            tooltip: 'Activity',
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBarHeader(
            hintText: 'Search TV series...',
            onQueryChanged: (query) {
              ref.read(seriesSearchQueryProvider.notifier).state = query;
            },
          ),
          Expanded(
            child: searchQuery.isEmpty
                ? _buildLibraryContent(context, ref, seriesAsync, settings)
                : _buildSearchResults(context, ref, searchResults, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SonarrSeries>> seriesAsync,
    dynamic settings,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(seriesProvider);
      },
      child: AsyncValueWidget<List<SonarrSeries>>(
        value: seriesAsync,
        serviceName: 'Sonarr',
        data: (seriesList) => MediaGrid<SonarrSeries>(
          items: seriesList,
          imagesExtractor: (series) => series.images,
          idExtractor: (series) => series.id,
          statusExtractor: (series) {
            // Check if series has any episode files
            final stats = series.statistics;
            final episodeFileCount = stats?['episodeFileCount'] as int? ?? 0;
            return (hasFile: episodeFileCount > 0, status: series.status);
          },
          baseUrl: settings.sonarrUrl,
          apiKey: settings.sonarrApiKey,
          heroTagPrefix: 'series',
          onItemTap: (series, heroTag) {
            context.go('/series/${series.id}?heroTag=$heroTag', extra: series);
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SonarrSeries>?> searchResults,
    dynamic settings,
  ) {
    return searchResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (results) {
        if (results == null || results.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return MediaGrid<SonarrSeries>(
          items: results,
          imagesExtractor: (series) => series.images,
          idExtractor: (series) => series.id,
          statusExtractor: (series) {
            final stats = series.statistics;
            final episodeFileCount = stats?['episodeFileCount'] as int? ?? 0;
            return (hasFile: episodeFileCount > 0, status: series.status);
          },
          baseUrl: settings.sonarrUrl,
          apiKey: settings.sonarrApiKey,
          heroTagPrefix: 'series_search',
          onItemTap: (series, heroTag) {
            context.go('/series/${series.id}?heroTag=$heroTag', extra: series);
          },
        );
      },
    );
  }
}
