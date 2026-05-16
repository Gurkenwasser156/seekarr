import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: implementation_imports
import 'package:flutter_riverpod/legacy.dart';

import 'package:seekarr/core/utils/search_results_loader.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';

/// Provider for the current search query in Movies section.
final moviesSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for search results in Movies section.
///
/// Returns null when query is empty, otherwise returns lookup results.
final moviesSearchResultsProvider = FutureProvider<List<RadarrMovie>?>((
  ref,
) async {
  final query = ref.watch(moviesSearchQueryProvider);
  final service = ref.read(radarrServiceProvider);
  return loadNullableSearchResults(query: query, lookup: service.lookupMovies);
});
