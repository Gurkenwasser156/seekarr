import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/features/movies/presentation/movie_detail_provider.dart';
import 'package:seekarr/features/movies/presentation/movie_detail_screen.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

import '../../../test_helpers/fake_services.dart';
import '../../../test_helpers/model_builders.dart';

RadarrMovie _movie({bool hasFile = true, String? path}) => buildMovie(
  title: 'Inception',
  overview: 'A mind-bending thriller.',
  path: path ?? '/movies/Inception (2010)/Inception.mkv',
  hasFile: hasFile,
  year: 2010,
  tmdbId: 100,
  runtime: 148,
  sizeOnDisk: 1000000,
  studio: 'Warner Bros',
  genres: const ['Sci-Fi', 'Action'],
  certification: 'PG-13',
);

void main() {
  group('MovieDetailScreen', () {
    testWidgets('shows loading state when provider is loading', (tester) async {
      await _pumpMovieDetail(
        tester,
        detailBuilder: (ref, movieId) => Completer<RadarrMovie?>().future,
      );
      await tester.pump();

      expect(find.byType(MediaDetailLoadingView), findsOneWidget);
    });

    testWidgets('shows error text for generic errors', (tester) async {
      await _pumpMovieDetail(
        tester,
        detailBuilder: (ref, movieId) =>
            Future<RadarrMovie?>.error(Exception('Network failure')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
      expect(find.textContaining('Network failure'), findsOneWidget);
    });

    testWidgets('shows not configured placeholder for configuration errors', (
      tester,
    ) async {
      await _pumpMovieDetail(
        tester,
        detailBuilder: (ref, movieId) =>
            Future<RadarrMovie?>.error(Exception('Radarr not configured')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotConfiguredPlaceholder), findsOneWidget);
    });

    testWidgets('renders movie detail content when data is loaded', (
      tester,
    ) async {
      await _pumpMovieDetail(
        tester,
        detailBuilder: (ref, movieId) async => _movie(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inception'), findsAtLeastNWidgets(1));
      expect(find.text('A mind-bending thriller.'), findsOneWidget);
      expect(find.byType(MediaMetadataLine), findsOneWidget);
      expect(find.byType(MediaInfoCard), findsOneWidget);
      expect(find.byType(FileInfoSection), findsOneWidget);
    });

    testWidgets('uses initialMovie while provider is still loading', (
      tester,
    ) async {
      await _pumpMovieDetail(
        tester,
        detailBuilder: (ref, movieId) => Completer<RadarrMovie?>().future,
        initialMovie: _movie(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Inception'), findsAtLeastNWidgets(1));
      expect(find.byType(MediaDetailLoadingView), findsNothing);
    });

    testWidgets('hides file info section when the movie has no file', (
      tester,
    ) async {
      await _pumpMovieDetail(
        tester,
        detailBuilder: (ref, movieId) async =>
            _movie(hasFile: false, path: null),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FileInfoSection), findsNothing);
    });
  });
}

Future<void> _pumpMovieDetail(
  WidgetTester tester, {
  required FutureOr<RadarrMovie?> Function(Ref ref, int movieId) detailBuilder,
  RadarrMovie? initialMovie,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentSettingsProvider.overrideWith(
          (ref) => const SettingsModel(
            radarrUrl: 'http://localhost:7878',
            radarrApiKey: 'key',
          ),
        ),
        movieDetailProvider.overrideWith(detailBuilder),
        radarrServiceProvider.overrideWith((ref) => FakeRadarrService()),
      ],
      child: MaterialApp(
        home: MovieDetailScreen(
          movieId: 1,
          heroTag: 'movie-1',
          initialMovie: initialMovie,
        ),
      ),
    ),
  );
}
