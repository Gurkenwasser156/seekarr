import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/discover/presentation/discover_detail_view_model.dart';

void main() {
  group('DiscoverDetailViewModel', () {
    test('parses movie response with rich metadata', () {
      final cast = List.generate(
        25,
        (index) => {
          'name': 'Actor $index',
          'character': 'Character $index',
          'profilePath': '/actor-$index.jpg',
        },
      );
      final keywords = List.generate(10, (index) => {'name': 'Keyword $index'});
      final details = <String, dynamic>{
        'title': 'Test Movie',
        'overview': 'A movie overview.',
        'posterPath': '/poster.jpg',
        'mediaInfo': {'status': 4, 'path': '/movies/Test Movie'},
        'genres': [
          {'name': 'Action'},
          {'name': 'Drama'},
        ],
        'releaseDate': '2024-03-25',
        'runtime': 123,
        'voteAverage': 7.4,
        'voteCount': 240,
        'credits': {
          'cast': cast,
          'crew': [
            {'job': 'Director', 'name': 'Director A'},
            {'job': 'Director', 'name': 'Director B'},
            {'job': 'Director', 'name': 'Director C'},
            {'job': 'Writer', 'name': 'Writer A'},
            {'job': 'Screenplay', 'name': 'Writer B'},
            {'job': 'Writer', 'name': 'Writer C'},
          ],
        },
        'keywords': keywords,
        'externalIds': {'tvdbId': 999},
      };

      final viewModel = DiscoverDetailViewModel.fromResponse(details);

      expect(viewModel.title, 'Test Movie');
      expect(viewModel.overview, 'A movie overview.');
      expect(viewModel.posterUrl, 'https://image.tmdb.org/t/p/w500/poster.jpg');
      expect(viewModel.jellyseerrStatus, 'Available');
      expect(viewModel.isAvailable, isTrue);
      expect(viewModel.genres, 'Action, Drama');
      expect(viewModel.year, '2024');
      expect(viewModel.runtimeStr, '123min');
      expect(viewModel.voteAverage, 7.4);
      expect(viewModel.voteCount, 240);
      expect(viewModel.cast, hasLength(20));
      expect(viewModel.cast.first.name, 'Actor 0');
      expect(viewModel.cast.first.character, 'Character 0');
      expect(viewModel.directors, ['Director A', 'Director B']);
      expect(viewModel.writers, ['Writer A', 'Writer B']);
      expect(viewModel.keywords, hasLength(8));
      expect(viewModel.keywords.first, 'Keyword 0');
      expect(viewModel.tvdbId, 999);
      expect(viewModel.metadataLine, 'Action, Drama');
      expect(viewModel.hasManageableMedia, isFalse);
      expect(viewModel.servicePath, '/movies/Test Movie');
      expect(viewModel.directorNames, 'Director A, Director B');
      expect(viewModel.writerNames, 'Writer A, Writer B');
    });

    test('parses tv response and prefers initial poster override', () {
      final details = <String, dynamic>{
        'name': 'Test Show',
        'overview': 'A tv overview.',
        'posterPath': '/ignored.jpg',
        'mediaInfo': {'status': 2},
        'genres': [
          {'name': 'Sci-Fi'},
        ],
        'firstAirDate': '2021-01-10',
        'numberOfSeasons': 3,
        'networks': [
          {'name': 'HBO'},
          {'name': 'Max'},
          {'name': 'Ignored'},
        ],
        'vote_average': 8.1,
        'vote_count': 1000,
        'tvdbId': 321,
      };

      final viewModel = DiscoverDetailViewModel.fromResponse(
        details,
        initialPosterUrl: 'https://cdn.example.com/poster.jpg',
      );

      expect(viewModel.title, 'Test Show');
      expect(viewModel.posterUrl, 'https://cdn.example.com/poster.jpg');
      expect(viewModel.jellyseerrStatus, 'Processing');
      expect(viewModel.year, '2021');
      expect(viewModel.numberOfSeasons, 3);
      expect(viewModel.networks, 'HBO, Max');
      expect(viewModel.voteAverage, 8.1);
      expect(viewModel.voteCount, 1000);
      expect(viewModel.tvdbId, 321);
      expect(viewModel.metadataLine, 'Sci-Fi • HBO, Max');
    });

    test('handles missing optional data with safe defaults', () {
      final viewModel = DiscoverDetailViewModel.fromResponse(
        const <String, dynamic>{},
      );

      expect(viewModel.title, 'Unknown');
      expect(viewModel.overview, isEmpty);
      expect(viewModel.posterUrl, isEmpty);
      expect(viewModel.jellyseerrStatus, 'Available to Request');
      expect(viewModel.isAvailable, isFalse);
      expect(viewModel.genres, isEmpty);
      expect(viewModel.year, isEmpty);
      expect(viewModel.runtimeStr, isNull);
      expect(viewModel.numberOfSeasons, isNull);
      expect(viewModel.networks, isEmpty);
      expect(viewModel.voteAverage, isNull);
      expect(viewModel.voteCount, isNull);
      expect(viewModel.cast, isEmpty);
      expect(viewModel.directors, isEmpty);
      expect(viewModel.writers, isEmpty);
      expect(viewModel.keywords, isEmpty);
      expect(viewModel.tvdbId, isNull);
      expect(viewModel.metadataLine, isEmpty);
      expect(viewModel.hasManageableMedia, isFalse);
      expect(viewModel.servicePath, isNull);
    });

    test('maps jellyseerr status codes consistently', () {
      expect(
        DiscoverDetailViewModel.mapJellyseerrStatus(null),
        'Available to Request',
      );
      expect(DiscoverDetailViewModel.mapJellyseerrStatus(1), 'Pending');
      expect(DiscoverDetailViewModel.mapJellyseerrStatus(2), 'Processing');
      expect(DiscoverDetailViewModel.mapJellyseerrStatus(3), 'Partial');
      expect(DiscoverDetailViewModel.mapJellyseerrStatus(4), 'Available');
      expect(DiscoverDetailViewModel.mapJellyseerrStatus(5), 'Available');
      expect(DiscoverDetailViewModel.mapJellyseerrStatus(99), 'Unknown');
    });
  });
}
