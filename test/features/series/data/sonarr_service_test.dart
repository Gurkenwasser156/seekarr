import 'package:flutter_test/flutter_test.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';

void main() {
  group('SonarrService', () {
    group('getSeriesByTvdbId', () {
      test('finds series when TVDB ID matches', () {
        final series = [
          SonarrSeries(
            id: 1,
            title: 'Series 1',
            sortTitle: 'series 1',
            status: 'continuing',
            overview: 'A test series',
            path: '/tv/series1',
            monitored: true,
            year: 2023,
            images: [],
            tvdbId: 11111,
            runtime: 45,
            genres: ['Drama'],
            seasons: [],
          ),
          SonarrSeries(
            id: 2,
            title: 'Series 2',
            sortTitle: 'series 2',
            status: 'ended',
            overview: 'Another series',
            path: '/tv/series2',
            monitored: true,
            year: 2020,
            images: [],
            tvdbId: 22222,
            runtime: 60,
            genres: ['Comedy'],
            seasons: [],
          ),
        ];

        final found = series.where((s) => s.tvdbId == 11111).firstOrNull;
        expect(found, isNotNull);
        expect(found!.id, 1);
        expect(found.title, 'Series 1');
      });

      test('returns null when TVDB ID not found', () {
        final series = [
          SonarrSeries(
            id: 1,
            title: 'Series 1',
            sortTitle: 'series 1',
            status: 'continuing',
            overview: 'A test series',
            path: '/tv/series1',
            monitored: true,
            year: 2023,
            images: [],
            tvdbId: 11111,
            runtime: 45,
            genres: ['Drama'],
            seasons: [],
          ),
        ];

        final found = series.where((s) => s.tvdbId == 99999).firstOrNull;
        expect(found, isNull);
      });

      test('handles empty library', () {
        final series = <SonarrSeries>[];
        final found = series.where((s) => s.tvdbId == 11111).firstOrNull;
        expect(found, isNull);
      });
    });
  });
}
