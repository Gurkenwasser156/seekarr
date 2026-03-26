import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/core/models/media_preview.dart';
import 'package:seekarr/core/router.dart';
import 'package:seekarr/features/discover/data/jellyseerr_service.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_screen.dart';
import 'package:seekarr/features/discover/presentation/discover_screen.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/features/movies/presentation/movie_detail_screen.dart';
import 'package:seekarr/features/movies/presentation/movies_screen.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';
import 'package:seekarr/features/music/presentation/music_detail_screen.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:seekarr/features/series/presentation/series_detail_screen.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';
import 'package:seekarr/features/settings/presentation/service_settings_screen.dart';

void main() {
  group('routerProvider', () {
    testWidgets('redirects invalid discover detail ids back to discover', (
      tester,
    ) async {
      final container = await _pumpRouter(tester);
      final router = container.read(routerProvider);

      router.go('/discover/movie/not-a-number');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/discover');
      expect(find.byType(DiscoverScreen), findsOneWidget);
      expect(find.byType(DiscoverDetailScreen), findsNothing);
    });

    testWidgets(
      'preserves discover detail default hero tag and posterUrl decoding',
      (tester) async {
        final container = await _pumpRouter(tester);
        final router = container.read(routerProvider);
        const encodedPosterUrl =
            'https%3A%2F%2Fcdn.example.com%2Fposter%20image.jpg';

        router.go('/discover/movie/123?posterUrl=$encodedPosterUrl');
        await tester.pumpAndSettle();

        final screen = tester.widget<DiscoverDetailScreen>(
          find.byType(DiscoverDetailScreen),
        );

        expect(
          router.state.uri.toString(),
          '/discover/movie/123?posterUrl=$encodedPosterUrl',
        );
        expect(screen.mediaId, 123);
        expect(screen.mediaType, 'movie');
        expect(screen.heroTag, 'discover_movie_123');
        expect(
          screen.initialPosterUrl,
          'https://cdn.example.com/poster image.jpg',
        );
      },
    );

    testWidgets('preserves default hero tags for library detail routes', (
      tester,
    ) async {
      final container = await _pumpRouter(tester);
      final router = container.read(routerProvider);

      router.go('/movies/42', extra: _buildMovie());
      await tester.pumpAndSettle();

      final movieScreen = tester.widget<MovieDetailScreen>(
        find.byType(MovieDetailScreen),
      );
      expect(movieScreen.heroTag, 'movie_42');

      router.go('/series/55', extra: _buildSeries());
      await tester.pumpAndSettle();

      final seriesScreen = tester.widget<SeriesDetailScreen>(
        find.byType(SeriesDetailScreen),
      );
      expect(seriesScreen.heroTag, 'series_55');

      router.go('/music/9', extra: _buildArtist());
      await tester.pumpAndSettle();

      final musicScreen = tester.widget<MusicDetailScreen>(
        find.byType(MusicDetailScreen),
      );
      expect(musicScreen.heroTag, 'artist_9');
    });

    testWidgets('redirects library detail route when extra is missing', (
      tester,
    ) async {
      final container = await _pumpRouter(tester);
      final router = container.read(routerProvider);

      router.go('/movies/42');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/movies');
      expect(find.byType(MoviesScreen), findsOneWidget);
      expect(find.byType(MovieDetailScreen), findsNothing);
    });

    testWidgets('redirects invalid library detail ids back to movies', (
      tester,
    ) async {
      final container = await _pumpRouter(tester);
      final router = container.read(routerProvider);

      router.go('/movies/not-a-number', extra: _buildMovie());
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/movies');
      expect(find.byType(MoviesScreen), findsOneWidget);
      expect(find.byType(MovieDetailScreen), findsNothing);
    });

    testWidgets(
      'redirects library detail route when extra type is wrong or id mismatches',
      (tester) async {
        final container = await _pumpRouter(tester);
        final router = container.read(routerProvider);

        router.go('/movies/42', extra: _buildArtist());
        await tester.pumpAndSettle();

        expect(router.state.uri.toString(), '/movies');
        expect(find.byType(MoviesScreen), findsOneWidget);

        router.go('/movies/42', extra: _buildMovie(id: 7));
        await tester.pumpAndSettle();

        expect(router.state.uri.toString(), '/movies');
        expect(find.byType(MoviesScreen), findsOneWidget);
      },
    );

    testWidgets('unknown service settings routes fall back to jellyseerr', (
      tester,
    ) async {
      final container = await _pumpRouter(tester);
      final router = container.read(routerProvider);

      router.go('/settings/service/not-a-service');
      await tester.pumpAndSettle();

      final screen = tester.widget<ServiceSettingsScreen>(
        find.byType(ServiceSettingsScreen),
      );

      expect(screen.service, ServiceKey.jellyseerr);
      expect(find.text('Jellyseerr Settings'), findsOneWidget);
    });
  });
}

Future<ProviderContainer> _pumpRouter(
  WidgetTester tester, {
  SettingsModel settings = const SettingsModel(),
  FakeJellyseerrService? jellyseerrService,
  FakeRadarrService? radarrService,
  FakeSonarrService? sonarrService,
  FakeLidarrService? lidarrService,
}) async {
  final container = ProviderContainer(
    overrides: [
      currentSettingsProvider.overrideWith((ref) => settings),
      jellyseerrServiceProvider.overrideWith(
        (ref) => jellyseerrService ?? FakeJellyseerrService(),
      ),
      radarrServiceProvider.overrideWith(
        (ref) => radarrService ?? FakeRadarrService(),
      ),
      sonarrServiceProvider.overrideWith(
        (ref) => sonarrService ?? FakeSonarrService(),
      ),
      lidarrServiceProvider.overrideWith(
        (ref) => lidarrService ?? FakeLidarrService(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: container.read(routerProvider)),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

class FakeJellyseerrService extends JellyseerrService {
  FakeJellyseerrService({
    Map<String, dynamic>? movieDetails,
    Map<String, dynamic>? tvDetails,
  }) : _movieDetails = movieDetails ?? _buildDiscoverMovieDetails(),
       _tvDetails = tvDetails ?? _buildDiscoverTvDetails(),
       super(
         ApiClient(baseUrl: 'https://jellyseerr.example.com', apiKey: 'key'),
       );

  final Map<String, dynamic> _movieDetails;
  final Map<String, dynamic> _tvDetails;

  @override
  Future<List<MediaPreview>> getDiscoverMovies({int page = 1}) async => [];

  @override
  Future<List<MediaPreview>> getDiscoverTV({int page = 1}) async => [];

  @override
  Future<List<MediaPreview>> getDiscoverTrending({int page = 1}) async => [];

  @override
  Future<Map<String, dynamic>> getMovie(int movieId) async => _movieDetails;

  @override
  Future<Map<String, dynamic>> getTv(int tvId) async => _tvDetails;
}

class FakeRadarrService extends RadarrService {
  FakeRadarrService()
    : super(ApiClient(baseUrl: 'https://radarr.example.com', apiKey: 'key'));

  @override
  Future<List<RadarrMovie>> getMovies() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getQualityProfiles() async => const [];
}

class FakeSonarrService extends SonarrService {
  FakeSonarrService()
    : super(ApiClient(baseUrl: 'https://sonarr.example.com', apiKey: 'key'));

  @override
  Future<List<SonarrSeries>> getSeries() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getQualityProfiles() async => const [];

  @override
  Future<List<dynamic>> getEpisodes(int seriesId) async => const [];
}

class FakeLidarrService extends LidarrService {
  FakeLidarrService()
    : super(ApiClient(baseUrl: 'https://lidarr.example.com', apiKey: 'key'));

  @override
  Future<List<LidarrArtist>> getArtists() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getQualityProfiles() async => const [];

  @override
  Future<List<dynamic>> getAlbums(int artistId) async => const [];
}

RadarrMovie _buildMovie({int id = 42}) {
  return RadarrMovie(
    id: id,
    title: 'Movie $id',
    sortTitle: 'movie-$id',
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

SonarrSeries _buildSeries() {
  return const SonarrSeries(
    id: 55,
    title: 'Series 55',
    sortTitle: 'series-55',
    status: 'continuing',
    monitored: true,
    year: 2024,
    images: [],
    tvdbId: 456,
    runtime: 45,
    genres: [],
    seasons: [],
  );
}

LidarrArtist _buildArtist() {
  return const LidarrArtist(
    id: 9,
    artistName: 'Artist 9',
    status: 'active',
    monitored: true,
    images: [],
    genres: [],
  );
}

Map<String, dynamic> _buildDiscoverMovieDetails() {
  return const {
    'title': 'Discover Movie',
    'overview': 'A movie overview.',
    'posterPath': '/poster.jpg',
    'genres': [],
    'credits': {'cast': [], 'crew': []},
    'keywords': [],
  };
}

Map<String, dynamic> _buildDiscoverTvDetails() {
  return const {
    'name': 'Discover Show',
    'overview': 'A show overview.',
    'posterPath': '/show.jpg',
    'genres': [],
    'credits': {'cast': [], 'crew': []},
    'keywords': [],
  };
}
