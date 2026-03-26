import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/features/movies/presentation/movies_provider.dart';
import 'package:seekarr/features/movies/presentation/movies_search_provider.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaBrowseScaffold<RadarrMovie>(
      title: 'Movies',
      searchHint: 'Search movies...',
      activityRoute: '/activity/movies',
      navigationSection: NavigationSection.movies,
      serviceName: 'Radarr',
      heroTagPrefix: 'movie',
      searchHeroTagPrefix: 'movie_search',
      libraryProvider: moviesProvider,
      searchQueryProvider: moviesSearchQueryProvider,
      searchResultsProvider: moviesSearchResultsProvider,
      imagesExtractor: (movie) => movie.images,
      idExtractor: (movie) => movie.id,
      statusExtractor: (movie) =>
          (hasFile: movie.hasFile, status: movie.status),
      settingsSelector: (settings) =>
          (settings.radarrUrl, settings.radarrApiKey),
      onItemTap: (context, movie, heroTag) {
        context.push('/movies/${movie.id}?heroTag=$heroTag', extra: movie);
      },
    );
  }
}
