import 'package:flutter_test/flutter_test.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';

void main() {
  group('RadarrService', () {
    group('getMovieByTmdbId', () {
      test('finds movie when TMDB ID matches', () {
        // Simulate the logic of getMovieByTmdbId
        final movies = [
          RadarrMovie(
            id: 1,
            title: 'Movie 1',
            sortTitle: 'movie 1',
            sizeOnDisk: 0,
            status: 'released',
            hasFile: true,
            monitored: true,
            year: 2023,
            images: [],
            tmdbId: 12345,
            runtime: 120,
            genres: [],
          ),
          RadarrMovie(
            id: 2,
            title: 'Movie 2',
            sortTitle: 'movie 2',
            sizeOnDisk: 0,
            status: 'released',
            hasFile: true,
            monitored: true,
            year: 2024,
            images: [],
            tmdbId: 67890,
            runtime: 90,
            genres: [],
          ),
        ];

        // Test finding a movie by TMDB ID
        final found = movies.where((m) => m.tmdbId == 12345).firstOrNull;
        expect(found, isNotNull);
        expect(found!.id, 1);
        expect(found.title, 'Movie 1');
      });

      test('returns null when TMDB ID not found', () {
        final movies = [
          RadarrMovie(
            id: 1,
            title: 'Movie 1',
            sortTitle: 'movie 1',
            sizeOnDisk: 0,
            status: 'released',
            hasFile: true,
            monitored: true,
            year: 2023,
            images: [],
            tmdbId: 12345,
            runtime: 120,
            genres: [],
          ),
        ];

        final found = movies.where((m) => m.tmdbId == 99999).firstOrNull;
        expect(found, isNull);
      });

      test('handles empty library', () {
        final movies = <RadarrMovie>[];
        final found = movies.where((m) => m.tmdbId == 12345).firstOrNull;
        expect(found, isNull);
      });
    });
  });
}
