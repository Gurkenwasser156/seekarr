import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/router.dart';
import 'package:seekarr/features/discover/data/seerr_service.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_screen.dart';
import 'package:seekarr/features/discover/presentation/discover_screen.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/presentation/movie_detail_screen.dart';
import 'package:seekarr/features/movies/presentation/movies_screen.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/music/presentation/music_detail_screen.dart';
import 'package:seekarr/features/music/presentation/music_screen.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/series/presentation/series_detail_screen.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/nav_tab.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';
import 'package:seekarr/features/settings/presentation/settings_appearance_screen.dart';
import 'package:seekarr/features/settings/presentation/settings_services_screen.dart';
import 'package:seekarr/features/settings/presentation/service_settings_screen.dart';

import '../test_helpers/fake_services.dart';
import '../test_helpers/model_builders.dart';

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

    testWidgets(
      'supports deep-linked library detail routes without extras and preserves default hero tags',
      (tester) async {
        final container = await _pumpRouter(tester);
        final router = container.read(routerProvider);

        router.go('/movies/42');
        await tester.pumpAndSettle();

        final movieScreen = tester.widget<MovieDetailScreen>(
          find.byType(MovieDetailScreen),
        );
        expect(movieScreen.heroTag, 'movie_42');
        expect(movieScreen.movieId, 42);
        expect(movieScreen.initialMovie, isNull);

        router.go('/series/55');
        await tester.pumpAndSettle();

        final seriesScreen = tester.widget<SeriesDetailScreen>(
          find.byType(SeriesDetailScreen),
        );
        expect(seriesScreen.heroTag, 'series_55');
        expect(seriesScreen.seriesId, 55);
        expect(seriesScreen.initialSeries, isNull);

        router.go('/music/9');
        await tester.pumpAndSettle();

        final musicScreen = tester.widget<MusicDetailScreen>(
          find.byType(MusicDetailScreen),
        );
        expect(musicScreen.heroTag, 'artist_9');
        expect(musicScreen.artistId, 9);
        expect(musicScreen.initialArtist, isNull);
      },
    );

    testWidgets('redirects invalid library detail ids back to movies', (
      tester,
    ) async {
      final container = await _pumpRouter(tester);
      final router = container.read(routerProvider);

      router.go('/movies/not-a-number', extra: buildMovie(id: 42));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/movies');
      expect(find.byType(MoviesScreen), findsOneWidget);
      expect(find.byType(MovieDetailScreen), findsNothing);
    });

    testWidgets(
      'library detail routes ignore wrong-type and mismatched extras instead of redirecting',
      (tester) async {
        final container = await _pumpRouter(tester);
        final router = container.read(routerProvider);

        router.go('/movies/42', extra: buildArtist(id: 9));
        await tester.pumpAndSettle();

        expect(router.state.uri.toString(), '/movies/42');
        var movieScreen = tester.widget<MovieDetailScreen>(
          find.byType(MovieDetailScreen),
        );
        expect(movieScreen.movieId, 42);
        expect(movieScreen.initialMovie, isNull);

        router.go('/movies/42', extra: buildMovie(id: 7));
        await tester.pumpAndSettle();

        expect(router.state.uri.toString(), '/movies/42');
        movieScreen = tester.widget<MovieDetailScreen>(
          find.byType(MovieDetailScreen),
        );
        expect(movieScreen.movieId, 42);
        expect(movieScreen.initialMovie?.id, 7);
      },
    );

    testWidgets('unknown service settings routes fall back to seerr', (
      tester,
    ) async {
      final container = await _pumpRouter(tester);
      final router = container.read(routerProvider);

      router.go('/settings/service/not-a-service');
      await tester.pumpAndSettle();

      final screen = tester.widget<ServiceSettingsScreen>(
        find.byType(ServiceSettingsScreen),
      );

      expect(screen.service, ServiceKey.seerr);
      expect(find.text('Seerr Settings'), findsOneWidget);
    });

    testWidgets('supports appearance and services settings subroutes', (
      tester,
    ) async {
      final container = await _pumpRouter(tester);
      final router = container.read(routerProvider);

      router.go('/settings/appearance');
      await tester.pumpAndSettle();

      expect(find.byType(SettingsAppearanceScreen), findsOneWidget);

      router.go('/settings/services');
      await tester.pumpAndSettle();

      expect(find.byType(SettingsServicesScreen), findsOneWidget);
    });

    testWidgets('hidden tabs remain directly routable', (tester) async {
      final container = await _pumpRouter(
        tester,
        settings: const SettingsModel(hiddenTabs: {NavTab.music}),
      );
      final router = container.read(routerProvider);

      router.go('/music');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/music');
      expect(find.byType(MusicScreen), findsOneWidget);
    });
  });
}

Future<ProviderContainer> _pumpRouter(
  WidgetTester tester, {
  SettingsModel settings = const SettingsModel(),
}) async {
  final container = ProviderContainer(
    overrides: [
      currentSettingsProvider.overrideWith((ref) => settings),
      seerrServiceProvider.overrideWith((ref) => FakeSeerrService()),
      radarrServiceProvider.overrideWith((ref) => FakeRadarrService()),
      sonarrServiceProvider.overrideWith((ref) => FakeSonarrService()),
      lidarrServiceProvider.overrideWith((ref) => FakeLidarrService()),
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
