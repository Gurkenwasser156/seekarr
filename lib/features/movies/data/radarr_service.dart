import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/core/api/base_arr_service.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final radarrServiceProvider = Provider<RadarrService>((ref) {
  final settings = ref.watch(settingsProvider);
  if (settings.radarrUrl.isEmpty || settings.radarrApiKey.isEmpty) {
    throw Exception('Radarr not configured');
  }
  return RadarrService(
    ApiClient(baseUrl: settings.radarrUrl, apiKey: settings.radarrApiKey),
  );
});

/// Service for interacting with Radarr API.
///
/// Provides movie-specific operations plus shared activity operations
/// via [ArrActivityMixin].
class RadarrService with ArrActivityMixin {
  @override
  final ApiClient client;

  @override
  final ArrServiceConfig config = ArrServiceConfig.radarr;

  RadarrService(this.client);

  /// Fetches all movies from Radarr.
  Future<List<RadarrMovie>> getMovies() async {
    try {
      final response = await client.get('/api/v3/movie');
      final data = response.data as List<dynamic>;
      return await Isolate.run(
        () => data.map((e) => RadarrMovie.fromJson(e)).toList(),
      );
    } catch (e) {
      return [];
    }
  }

  /// Triggers an automatic search for the given movie ID.
  Future<void> searchMovie(int movieId) async {
    await client.post(
      '/api/v3/command',
      data: {
        'name': 'MoviesSearch',
        'movieIds': [movieId],
      },
    );
  }

  /// Fetches releases for interactive search.
  Future<List<dynamic>> getReleases(
    int movieId, {
    CancelToken? cancelToken,
  }) async {
    final response = await client.get(
      '/api/v3/release',
      queryParameters: {'movieId': movieId},
      cancelToken: cancelToken,
    );
    return response.data as List<dynamic>;
  }

  /// Grabs a specific release for download.
  Future<void> grabRelease({
    required String guid,
    required int indexerId,
  }) async {
    await client.post(
      '/api/v3/release',
      data: {'guid': guid, 'indexerId': indexerId},
    );
  }

  /// Searches for movies by term using the lookup API.
  Future<List<RadarrMovie>> lookupMovies(String term) async {
    if (term.isEmpty) return [];
    try {
      // URL-encode the term to handle spaces and special characters
      final encodedTerm = Uri.encodeComponent(term);
      final response = await client.get(
        '/api/v3/movie/lookup',
        queryParameters: {'term': encodedTerm},
      );
      final data = response.data as List<dynamic>;
      return await Isolate.run(
        () => data.map((e) => RadarrMovie.fromJson(e)).toList(),
      );
    } catch (e) {
      return [];
    }
  }

  /// Finds a movie in the library by its TMDB ID.
  /// Returns null if not found in the library.
  Future<RadarrMovie?> getMovieByTmdbId(int tmdbId) async {
    try {
      final movies = await getMovies();
      return movies.where((m) => m.tmdbId == tmdbId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  /// Fetches all quality profiles.
  Future<List<Map<String, dynamic>>> getQualityProfiles() async {
    try {
      final response = await client.get('/api/v3/qualityprofile');
      final data = response.data as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Updates a movie's quality profile.
  Future<void> updateMovieProfile(int movieId, int qualityProfileId) async {
    // First get the movie
    final response = await client.get('/api/v3/movie/$movieId');
    final movie = response.data as Map<String, dynamic>;

    // Update quality profile
    movie['qualityProfileId'] = qualityProfileId;

    await client.put('/api/v3/movie/$movieId', data: movie);
  }

  /// Deletes a movie from Radarr.
  Future<void> deleteMovie(
    int movieId, {
    bool deleteFiles = false,
    bool addImportExclusion = false,
  }) async {
    await client.delete(
      '/api/v3/movie/$movieId',
      queryParameters: {
        'deleteFiles': deleteFiles,
        'addImportExclusion': addImportExclusion,
      },
    );
  }
}
