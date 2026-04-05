import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';

void main() {
  group('SonarrService', () {
    group('getSeriesByTvdbId', () {
      test('finds series when TVDB ID matches', () async {
        final service = _TestSonarrService([
          _series(
            id: 1,
            title: 'Series 1',
            tvdbId: 11111,
            year: 2023,
            runtime: 45,
            genres: const ['Drama'],
          ),
          _series(
            id: 2,
            title: 'Series 2',
            tvdbId: 22222,
            year: 2020,
            runtime: 60,
            genres: const ['Comedy'],
          ),
        ]);

        final found = await service.getSeriesByTvdbId(11111);
        expect(found, isNotNull);
        expect(found!.id, 1);
        expect(found.title, 'Series 1');
      });

      test('returns null when TVDB ID not found', () async {
        final service = _TestSonarrService([
          _series(
            id: 1,
            title: 'Series 1',
            tvdbId: 11111,
            year: 2023,
            runtime: 45,
            genres: const ['Drama'],
          ),
        ]);

        final found = await service.getSeriesByTvdbId(99999);
        expect(found, isNull);
      });

      test('handles empty library', () async {
        final service = _TestSonarrService(const []);

        final found = await service.getSeriesByTvdbId(11111);
        expect(found, isNull);
      });
    });
  });
}

class _TestSonarrService extends SonarrService {
  _TestSonarrService(this._series) : super(ApiClient(baseUrl: '', apiKey: ''));

  final List<SonarrSeries> _series;

  @override
  Future<List<SonarrSeries>> getSeries() async => _series;
}

SonarrSeries _series({
  required int id,
  required String title,
  required int tvdbId,
  required int year,
  required int runtime,
  required List<String> genres,
}) {
  return SonarrSeries(
    id: id,
    title: title,
    sortTitle: title.toLowerCase(),
    status: 'continuing',
    overview: 'A test series',
    path: '/tv/${title.toLowerCase()}',
    monitored: true,
    year: year,
    images: const [],
    tvdbId: tvdbId,
    runtime: runtime,
    genres: genres,
    seasons: const [],
  );
}
