import 'package:flutter_test/flutter_test.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';

void main() {
  group('SonarrSeries', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': 1,
          'title': 'Test Series',
          'sortTitle': 'test series',
          'status': 'continuing',
          'overview': 'A test series overview.',
          'path': '/tv/Test Series',
          'monitored': true,
          'year': 2023,
          'images': [
            {
              'coverType': 'poster',
              'remoteUrl': 'https://example.com/poster.jpg',
            },
          ],
          'tvdbId': 123456,
          'runtime': 45,
          'network': 'Netflix',
          'genres': ['Drama', 'Sci-Fi'],
          'seasons': [
            {'seasonNumber': 1, 'monitored': true},
          ],
          'statistics': {'episodeFileCount': 10, 'totalEpisodeCount': 12},
        };

        final series = SonarrSeries.fromJson(json);

        expect(series.id, 1);
        expect(series.title, 'Test Series');
        expect(series.sortTitle, 'test series');
        expect(series.status, 'continuing');
        expect(series.overview, 'A test series overview.');
        expect(series.path, '/tv/Test Series');
        expect(series.monitored, true);
        expect(series.year, 2023);
        expect(series.images.length, 1);
        expect(series.tvdbId, 123456);
        expect(series.runtime, 45);
        expect(series.network, 'Netflix');
        expect(series.genres, ['Drama', 'Sci-Fi']);
        expect(series.seasons.length, 1);
        expect(series.statistics?['episodeFileCount'], 10);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 1,
          'title': 'Test Series',
          'sortTitle': 'test series',
          'status': 'unknown',
          'monitored': false,
          'year': 2023,
          'images': [],
          'tvdbId': 123,
          'runtime': 0,
          'genres': [],
          'seasons': [],
        };

        final series = SonarrSeries.fromJson(json);

        expect(series.overview, isNull);
        expect(series.path, isNull);
        expect(series.network, isNull);
        expect(series.statistics, isNull);
      });

      test('handles null values with defaults', () {
        final json = <String, dynamic>{};

        final series = SonarrSeries.fromJson(json);

        expect(series.id, 0);
        expect(series.title, 'Unknown');
        expect(series.sortTitle, '');
        expect(series.status, 'unknown');
        expect(series.monitored, false);
        expect(series.year, 0);
        expect(series.images, isEmpty);
        expect(series.tvdbId, 0);
        expect(series.runtime, 0);
        expect(series.genres, isEmpty);
        expect(series.seasons, isEmpty);
      });
    });

    group('toMediaPreview', () {
      test('converts to MediaPreview correctly', () {
        final series = SonarrSeries(
          id: 1,
          title: 'Test Series',
          sortTitle: 'test series',
          status: 'continuing',
          overview: 'Overview',
          monitored: true,
          year: 2023,
          images: [
            {
              'coverType': 'poster',
              'remoteUrl': 'https://example.com/poster.jpg',
            },
          ],
          tvdbId: 123,
          runtime: 45,
          genres: ['Drama'],
          seasons: [],
        );

        final preview = series.toMediaPreview();

        expect(preview.id, 1);
        expect(preview.title, 'Test Series');
        expect(preview.overview, 'Overview');
        expect(preview.releaseDate, '2023');
        expect(preview.mediaType, 'tv');
      });
    });
  });
}
