import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';

void main() {
  group('RadarrService', () {
    group('getMovieByTmdbId', () {
      test('finds movie when TMDB ID matches', () async {
        final service = _TestRadarrService([
          _movie(
            id: 1,
            title: 'Movie 1',
            tmdbId: 12345,
            year: 2023,
            runtime: 120,
          ),
          _movie(
            id: 2,
            title: 'Movie 2',
            tmdbId: 67890,
            year: 2024,
            runtime: 90,
          ),
        ]);

        final found = await service.getMovieByTmdbId(12345);

        expect(found, isNotNull);
        expect(found?.id, 1);
        expect(found?.title, 'Movie 1');
      });

      test('returns null when TMDB ID not found', () async {
        final service = _TestRadarrService([
          _movie(
            id: 1,
            title: 'Movie 1',
            tmdbId: 12345,
            year: 2023,
            runtime: 120,
          ),
        ]);

        final found = await service.getMovieByTmdbId(99999);
        expect(found, isNull);
      });

      test('handles empty library', () async {
        final service = _TestRadarrService(const []);

        final found = await service.getMovieByTmdbId(12345);
        expect(found, isNull);
      });
    });
  });
}

class _TestRadarrService extends RadarrService {
  _TestRadarrService(this._movies) : super(ApiClient(baseUrl: '', apiKey: ''));

  final List<RadarrMovie> _movies;

  @override
  Future<List<RadarrMovie>> getMovies() async => _movies;
}

RadarrMovie _movie({
  required int id,
  required String title,
  required int tmdbId,
  required int year,
  required int runtime,
}) {
  return RadarrMovie(
    id: id,
    title: title,
    sortTitle: title.toLowerCase(),
    sizeOnDisk: 0,
    status: 'released',
    hasFile: true,
    monitored: true,
    year: year,
    images: const [],
    tmdbId: tmdbId,
    runtime: runtime,
    genres: const [],
  );
}
