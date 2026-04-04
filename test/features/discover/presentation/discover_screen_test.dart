import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/models/media_preview.dart';
import 'package:seekarr/core/widgets/content_card.dart';
import 'package:seekarr/features/discover/presentation/discover_provider.dart';
import 'package:seekarr/features/discover/presentation/discover_screen.dart';
import 'package:seekarr/features/discover/presentation/discover_search_provider.dart';

const _movies = [
  MediaPreview(id: 1, title: 'Movie One', mediaType: 'movie'),
  MediaPreview(id: 2, title: 'Movie Two', mediaType: 'movie'),
];

const _tvShows = [MediaPreview(id: 10, title: 'Show One', mediaType: 'tv')];

const _trending = [
  MediaPreview(id: 20, title: 'Trending One', mediaType: 'movie'),
];

void main() {
  group('DiscoverScreen sections', () {
    testWidgets('renders three section headers when data loads', (
      tester,
    ) async {
      await _pumpDiscover(tester);
      await tester.pumpAndSettle();

      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('TV Series'), findsOneWidget);
      expect(find.byType(ContentCard), findsNWidgets(4));
    });

    testWidgets('shows loading indicator when a section is loading', (
      tester,
    ) async {
      await _pumpDiscover(
        tester,
        trendingBuilder: (ref) => Completer<List<MediaPreview>>().future,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows empty message when a section returns empty list', (
      tester,
    ) async {
      await _pumpDiscover(
        tester,
        moviesBuilder: (ref) async => const <MediaPreview>[],
      );
      await tester.pumpAndSettle();

      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('renders app bar with title and activity button', (
      tester,
    ) async {
      await _pumpDiscover(tester);
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    });
  });

  group('DiscoverScreen search', () {
    testWidgets('shows search results grid when query is non-empty', (
      tester,
    ) async {
      await _pumpDiscover(
        tester,
        searchQueryBuilder: (ref) => 'batman',
        searchResultsBuilder: (ref) async => _movies,
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ContentCard), findsNWidgets(2));
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('shows no results message when search returns empty', (
      tester,
    ) async {
      await _pumpDiscover(
        tester,
        searchQueryBuilder: (ref) => 'xyz',
        searchResultsBuilder: (ref) async => const <MediaPreview>[],
      );
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('shows error state when search fails', (tester) async {
      await _pumpDiscover(
        tester,
        searchQueryBuilder: (ref) => 'fail',
        searchResultsBuilder: (ref) =>
            Future<List<MediaPreview>?>.error(Exception('Network error')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error loading results'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });
  });
}

Future<void> _pumpDiscover(
  WidgetTester tester, {
  Future<List<MediaPreview>> Function(Ref ref)? trendingBuilder,
  Future<List<MediaPreview>> Function(Ref ref)? moviesBuilder,
  Future<List<MediaPreview>> Function(Ref ref)? tvBuilder,
  String Function(Ref ref)? searchQueryBuilder,
  Future<List<MediaPreview>?> Function(Ref ref)? searchResultsBuilder,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverTrendingProvider.overrideWith(
          trendingBuilder ?? (ref) async => _trending,
        ),
        discoverMoviesProvider.overrideWith(
          moviesBuilder ?? (ref) async => _movies,
        ),
        discoverTVProvider.overrideWith(tvBuilder ?? (ref) async => _tvShows),
        discoverSearchQueryProvider.overrideWith(
          searchQueryBuilder ?? (ref) => '',
        ),
        discoverSearchResultsProvider.overrideWith(
          searchResultsBuilder ?? (ref) async => null,
        ),
      ],
      child: const MaterialApp(home: DiscoverScreen()),
    ),
  );
}
