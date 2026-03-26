import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/core/models/rating_source.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_extras_provider.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart'
    as radarr;
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart'
    as sonarr;
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

void main() {
  group('discoverDetailExtrasProvider', () {
    ProviderContainer createContainer({
      required SettingsModel settings,
      FakeRadarrService? radarrService,
      FakeSonarrService? sonarrService,
    }) {
      final container = ProviderContainer(
        overrides: [
          currentSettingsProvider.overrideWith((ref) => settings),
          if (radarrService != null)
            radarrServiceProvider.overrideWith((ref) => radarrService),
          if (sonarrService != null)
            sonarrServiceProvider.overrideWith((ref) => sonarrService),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('returns movie library status when Radarr finds the media', () async {
      final container = createContainer(
        settings: const SettingsModel(
          radarrUrl: 'https://radarr.example.com',
          radarrApiKey: 'radarr-key',
        ),
        radarrService: FakeRadarrService(movieByTmdbId: _buildMovie()),
      );

      final result = await container.read(
        discoverDetailExtrasProvider((
          mediaId: 123,
          mediaType: 'movie',
          tvdbId: null,
          voteAverage: 7.2,
        )).future,
      );

      expect(result.isInLibrary, isTrue);
      expect(result.libraryCheckDone, isTrue);
      expect(result.lookupRatings, isNull);
    });

    test('returns false when movie is missing from Radarr', () async {
      final container = createContainer(
        settings: const SettingsModel(
          radarrUrl: 'https://radarr.example.com',
          radarrApiKey: 'radarr-key',
        ),
        radarrService: FakeRadarrService(movieByTmdbId: null),
      );

      final result = await container.read(
        discoverDetailExtrasProvider((
          mediaId: 999,
          mediaType: 'movie',
          tvdbId: null,
          voteAverage: 7.2,
        )).future,
      );

      expect(result.isInLibrary, isFalse);
      expect(result.libraryCheckDone, isTrue);
    });

    test(
      'skips tv library lookup when status is driven by Jellyseerr',
      () async {
        final sonarrService = FakeSonarrService(seriesByTvdbId: _buildSeries());
        final container = createContainer(
          settings: const SettingsModel(
            sonarrUrl: 'https://sonarr.example.com',
            sonarrApiKey: 'sonarr-key',
          ),
          sonarrService: sonarrService,
        );

        final result = await container.read(
          discoverDetailExtrasProvider((
            mediaId: 456,
            mediaType: 'tv',
            tvdbId: 555,
            voteAverage: 8.0,
          )).future,
        );

        expect(result.isInLibrary, isNull);
        expect(result.libraryCheckDone, isTrue);
        expect(result.lookupRatings, isNull);
        expect(sonarrService.getSeriesByTvdbIdCallCount, 0);
      },
    );

    test('gracefully handles tv media without a tvdb id', () async {
      final sonarrService = FakeSonarrService(seriesByTvdbId: _buildSeries());
      final container = createContainer(
        settings: const SettingsModel(
          sonarrUrl: 'https://sonarr.example.com',
          sonarrApiKey: 'sonarr-key',
        ),
        sonarrService: sonarrService,
      );

      final result = await container.read(
        discoverDetailExtrasProvider((
          mediaId: 456,
          mediaType: 'tv',
          tvdbId: null,
          voteAverage: null,
        )).future,
      );

      expect(result.isInLibrary, isNull);
      expect(result.libraryCheckDone, isTrue);
      expect(result.lookupRatings, isNull);
      expect(sonarrService.getSeriesByTvdbIdCallCount, 0);
      expect(sonarrService.lookupSeriesCallCount, 0);
    });

    test('skips service calls when Radarr is not configured', () async {
      final radarrService = FakeRadarrService(movieByTmdbId: _buildMovie());
      final container = createContainer(
        settings: const SettingsModel(),
        radarrService: radarrService,
      );

      final result = await container.read(
        discoverDetailExtrasProvider((
          mediaId: 123,
          mediaType: 'movie',
          tvdbId: null,
          voteAverage: null,
        )).future,
      );

      expect(result.isInLibrary, isNull);
      expect(result.libraryCheckDone, isTrue);
      expect(result.lookupRatings, isNull);
      expect(radarrService.getMovieByTmdbIdCallCount, 0);
      expect(radarrService.lookupMoviesCallCount, 0);
    });

    test('loads fallback ratings when voteAverage is missing', () async {
      final radarrService = FakeRadarrService(
        movieByTmdbId: _buildMovie(),
        lookupResults: [_buildMovieWithRatings()],
      );
      final container = createContainer(
        settings: const SettingsModel(
          radarrUrl: 'https://radarr.example.com',
          radarrApiKey: 'radarr-key',
        ),
        radarrService: radarrService,
      );

      final result = await container.read(
        discoverDetailExtrasProvider((
          mediaId: 123,
          mediaType: 'movie',
          tvdbId: null,
          voteAverage: null,
        )).future,
      );

      expect(result.lookupRatings, isNotNull);
      expect(result.lookupRatings, hasLength(1));
      final rating = result.lookupRatings!.single;
      expect(rating.name, 'TMDB');
      expect(rating.value, 8.1);
      expect(radarrService.lookupMoviesCallCount, 1);
    });

    test('loads tv fallback ratings when voteAverage is missing', () async {
      final sonarrService = FakeSonarrService(
        seriesByTvdbId: _buildSeries(),
        lookupResults: [_buildSeriesWithRatings()],
      );
      final container = createContainer(
        settings: const SettingsModel(
          sonarrUrl: 'https://sonarr.example.com',
          sonarrApiKey: 'sonarr-key',
        ),
        sonarrService: sonarrService,
      );

      final result = await container.read(
        discoverDetailExtrasProvider((
          mediaId: 456,
          mediaType: 'tv',
          tvdbId: 555,
          voteAverage: null,
        )).future,
      );

      expect(result.isInLibrary, isNull);
      expect(result.lookupRatings, hasLength(1));
      expect(result.lookupRatings!.single.name, 'TVDB');
      expect(result.lookupRatings!.single.value, 8.4);
      expect(sonarrService.getSeriesByTvdbIdCallCount, 0);
      expect(sonarrService.lookupSeriesCallCount, 1);
    });

    test(
      'skips fallback ratings when voteAverage is already present',
      () async {
        final radarrService = FakeRadarrService(
          movieByTmdbId: _buildMovie(),
          lookupResults: [_buildMovieWithRatings()],
        );
        final container = createContainer(
          settings: const SettingsModel(
            radarrUrl: 'https://radarr.example.com',
            radarrApiKey: 'radarr-key',
          ),
          radarrService: radarrService,
        );

        final result = await container.read(
          discoverDetailExtrasProvider((
            mediaId: 123,
            mediaType: 'movie',
            tvdbId: null,
            voteAverage: 7.5,
          )).future,
        );

        expect(result.lookupRatings, isNull);
        expect(radarrService.lookupMoviesCallCount, 0);
      },
    );

    test('falls back cleanly when a service throws', () async {
      final container = createContainer(
        settings: const SettingsModel(
          radarrUrl: 'https://radarr.example.com',
          radarrApiKey: 'radarr-key',
        ),
        radarrService: FakeRadarrService(
          throwOnGetMovieByTmdbId: true,
          throwOnLookupMovies: true,
        ),
      );

      final result = await container.read(
        discoverDetailExtrasProvider((
          mediaId: 123,
          mediaType: 'movie',
          tvdbId: null,
          voteAverage: null,
        )).future,
      );

      expect(result.isInLibrary, isNull);
      expect(result.libraryCheckDone, isTrue);
      expect(result.lookupRatings, isNull);
    });

    test('falls back cleanly when Sonarr lookup throws', () async {
      final sonarrService = FakeSonarrService(throwOnLookupSeries: true);
      final container = createContainer(
        settings: const SettingsModel(
          sonarrUrl: 'https://sonarr.example.com',
          sonarrApiKey: 'sonarr-key',
        ),
        sonarrService: sonarrService,
      );

      final result = await container.read(
        discoverDetailExtrasProvider((
          mediaId: 456,
          mediaType: 'tv',
          tvdbId: 555,
          voteAverage: null,
        )).future,
      );

      expect(result.isInLibrary, isNull);
      expect(result.libraryCheckDone, isTrue);
      expect(result.lookupRatings, isNull);
      expect(sonarrService.getSeriesByTvdbIdCallCount, 0);
      expect(sonarrService.lookupSeriesCallCount, 1);
    });
  });
}

class FakeRadarrService extends RadarrService {
  final radarr.RadarrMovie? movieByTmdbId;
  final List<radarr.RadarrMovie> lookupResults;
  final bool throwOnGetMovieByTmdbId;
  final bool throwOnLookupMovies;

  int getMovieByTmdbIdCallCount = 0;
  int lookupMoviesCallCount = 0;

  FakeRadarrService({
    this.movieByTmdbId,
    this.lookupResults = const <radarr.RadarrMovie>[],
    this.throwOnGetMovieByTmdbId = false,
    this.throwOnLookupMovies = false,
  }) : super(ApiClient(baseUrl: 'https://radarr.example.com', apiKey: 'key'));

  @override
  Future<radarr.RadarrMovie?> getMovieByTmdbId(int tmdbId) async {
    getMovieByTmdbIdCallCount += 1;
    if (throwOnGetMovieByTmdbId) {
      throw Exception('radarr lookup failed');
    }

    return movieByTmdbId;
  }

  @override
  Future<List<radarr.RadarrMovie>> lookupMovies(String term) async {
    lookupMoviesCallCount += 1;
    if (throwOnLookupMovies) {
      throw Exception('radarr ratings lookup failed');
    }

    return lookupResults;
  }
}

class FakeSonarrService extends SonarrService {
  final sonarr.SonarrSeries? seriesByTvdbId;
  final List<sonarr.SonarrSeries> lookupResults;
  final bool throwOnGetSeriesByTvdbId;
  final bool throwOnLookupSeries;

  int getSeriesByTvdbIdCallCount = 0;
  int lookupSeriesCallCount = 0;

  FakeSonarrService({
    this.seriesByTvdbId,
    this.lookupResults = const <sonarr.SonarrSeries>[],
    this.throwOnGetSeriesByTvdbId = false,
    this.throwOnLookupSeries = false,
  }) : super(ApiClient(baseUrl: 'https://sonarr.example.com', apiKey: 'key'));

  @override
  Future<sonarr.SonarrSeries?> getSeriesByTvdbId(int tvdbId) async {
    getSeriesByTvdbIdCallCount += 1;
    if (throwOnGetSeriesByTvdbId) {
      throw Exception('sonarr lookup failed');
    }

    return seriesByTvdbId;
  }

  @override
  Future<List<sonarr.SonarrSeries>> lookupSeries(String term) async {
    lookupSeriesCallCount += 1;
    if (throwOnLookupSeries) {
      throw Exception('sonarr ratings lookup failed');
    }

    return lookupResults;
  }
}

radarr.RadarrMovie _buildMovie() {
  return radarr.RadarrMovie(
    id: 1,
    title: 'Movie',
    sortTitle: 'movie',
    sizeOnDisk: 0,
    status: 'released',
    hasFile: true,
    monitored: true,
    year: 2024,
    images: const [],
    tmdbId: 123,
    runtime: 100,
    genres: const [],
  );
}

radarr.RadarrMovie _buildMovieWithRatings() {
  return radarr.RadarrMovie(
    id: 1,
    title: 'Movie',
    sortTitle: 'movie',
    sizeOnDisk: 0,
    status: 'released',
    hasFile: true,
    monitored: true,
    year: 2024,
    images: const [],
    tmdbId: 123,
    runtime: 100,
    genres: const [],
    ratings: [
      const RatingSource(name: 'TMDB', value: 8.1, votes: 200, icon: 'TMDB'),
    ],
  );
}

sonarr.SonarrSeries _buildSeries() {
  return sonarr.SonarrSeries(
    id: 1,
    title: 'Series',
    sortTitle: 'series',
    status: 'continuing',
    monitored: true,
    year: 2024,
    images: const [],
    tvdbId: 555,
    runtime: 45,
    genres: const [],
    seasons: const [],
  );
}

sonarr.SonarrSeries _buildSeriesWithRatings() {
  return sonarr.SonarrSeries(
    id: 1,
    title: 'Series',
    sortTitle: 'series',
    status: 'continuing',
    monitored: true,
    year: 2024,
    images: const [],
    tvdbId: 555,
    runtime: 45,
    genres: const [],
    seasons: const [],
    ratings: [
      const RatingSource(name: 'TVDB', value: 8.4, votes: 145000, icon: 'TVDB'),
    ],
  );
}
