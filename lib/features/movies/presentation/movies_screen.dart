import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/async_value_widget.dart';
import 'package:seekarr/core/widgets/media_grid.dart';
import 'package:seekarr/core/widgets/search_bar_header.dart';
import 'package:seekarr/features/movies/presentation/movies_provider.dart';
import 'package:seekarr/features/movies/presentation/movies_search_provider.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching = ref.watch(
      moviesSearchQueryProvider.select((value) => value.isNotEmpty),
    );

    // Listen for navigation refresh trigger
    ref.listen<int>(navigationRefreshProvider(NavigationSection.movies), (
      previous,
      next,
    ) {
      // Clear search query and invalidate provider
      ref.read(moviesSearchQueryProvider.notifier).state = '';
      ref.invalidate(moviesProvider);
    });

    return Scaffold(
      appBar: AppBar(
        leading: isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(moviesSearchQueryProvider.notifier).state = '';
                },
                tooltip: 'Exit search',
              )
            : null,
        title: const Text('Movies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/activity/movies'),
            tooltip: 'Activity',
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBarHeader(
            hintText: 'Search movies...',
            onQueryChanged: (query) {
              ref.read(moviesSearchQueryProvider.notifier).state = query;
            },
          ),
          Expanded(
            child: isSearching
                ? const _MoviesSearchResults()
                : const _MoviesLibraryContent(),
          ),
        ],
      ),
    );
  }
}

class _MoviesLibraryContent extends ConsumerWidget {
  const _MoviesLibraryContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(moviesProvider);
    final (url, apiKey) = ref.watch(
      settingsProvider.select((s) => (s.radarrUrl, s.radarrApiKey)),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(moviesProvider);
      },
      child: AsyncValueWidget<List<RadarrMovie>>(
        value: moviesAsync,
        serviceName: 'Radarr',
        data: (movies) => MediaGrid<RadarrMovie>(
          items: movies,
          imagesExtractor: (movie) => movie.images,
          idExtractor: (movie) => movie.id,
          statusExtractor: (movie) =>
              (hasFile: movie.hasFile, status: movie.status),
          baseUrl: url,
          apiKey: apiKey,
          heroTagPrefix: 'movie',
          onItemTap: (movie, heroTag) {
            context.push('/movies/${movie.id}?heroTag=$heroTag', extra: movie);
          },
        ),
      ),
    );
  }
}

class _MoviesSearchResults extends ConsumerWidget {
  const _MoviesSearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(moviesSearchResultsProvider);
    final (url, apiKey) = ref.watch(
      settingsProvider.select((s) => (s.radarrUrl, s.radarrApiKey)),
    );

    return searchResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (results) {
        if (results == null || results.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return MediaGrid<RadarrMovie>(
          items: results,
          imagesExtractor: (movie) => movie.images,
          idExtractor: (movie) => movie.id,
          statusExtractor: (movie) =>
              (hasFile: movie.hasFile, status: movie.status),
          baseUrl: url,
          apiKey: apiKey,
          heroTagPrefix: 'movie_search',
          onItemTap: (movie, heroTag) {
            context.push('/movies/${movie.id}?heroTag=$heroTag', extra: movie);
          },
        );
      },
    );
  }
}
