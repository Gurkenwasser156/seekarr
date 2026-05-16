import 'package:flutter_test/flutter_test.dart';
import 'package:seekarr/features/import/domain/manual_import_models.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

void main() {
  group('ManualImportItem', () {
    test('does not treat zero file ids as already imported', () {
      final sonarrItem = ManualImportItem.fromJson({
        'path': '/downloads/Frieren.S02E05.mkv',
        'name': 'Frieren.S02E05.mkv',
        'episodeFileId': 0,
      });
      final radarrItem = ManualImportItem.fromJson({
        'path': '/downloads/Movie.mkv',
        'name': 'Movie.mkv',
        'movieFileId': 0,
      });

      expect(sonarrItem.isAlreadyImported, isFalse);
      expect(sonarrItem.isSelectable, isTrue);
      expect(radarrItem.isAlreadyImported, isFalse);
      expect(radarrItem.isSelectable, isTrue);
    });

    test('treats positive file ids as already imported', () {
      final sonarrItem = ManualImportItem.fromJson({
        'path': '/downloads/Frieren.S02E01.mkv',
        'name': 'Frieren.S02E01.mkv',
        'episodeFileId': 42,
      });
      final radarrItem = ManualImportItem.fromJson({
        'path': '/downloads/Movie.mkv',
        'name': 'Movie.mkv',
        'movieFileId': 99,
      });

      expect(sonarrItem.isAlreadyImported, isTrue);
      expect(sonarrItem.isSelectable, isFalse);
      expect(radarrItem.isAlreadyImported, isTrue);
      expect(radarrItem.isSelectable, isFalse);
    });

    test('includes episode code in sonarr media subtitle', () {
      final item = ManualImportItem.fromJson({
        'path': '/downloads/Frieren.S02E05.mkv',
        'name': 'Frieren.S02E05.mkv',
        'series': {'id': 10, 'title': 'Frieren', 'year': 2023},
        'seasonNumber': 2,
        'episodes': [
          {
            'id': 50,
            'seasonNumber': 2,
            'episodeNumber': 5,
            'title': 'Episode 5',
          },
        ],
      });

      expect(item.mediaSubtitle, contains('S02E05'));
    });

    test('preserves original size when reprocess response omits it', () {
      final original = ManualImportItem.fromJson({
        'path': '/downloads/Frieren.S02E05.mkv',
        'name': 'Frieren.S02E05.mkv',
        'size': 1300000000,
      });
      final reprocessed = ManualImportItem.fromJson({
        'path': '/downloads/Frieren.S02E05.mkv',
        'name': 'Frieren.S02E05.mkv',
        'size': 0,
        'series': {'id': 10, 'title': 'Frieren'},
      });

      final merged = original.mergedWithReprocessed(reprocessed);

      expect(merged.size, 1300000000);
    });

    test(
      'resolved assignment keeps merged size and applies sonarr episode',
      () {
        final original = ManualImportItem.fromJson({
          'path': '/downloads/Frieren.S02E05.mkv',
          'name': 'Frieren.S02E05.mkv',
          'size': 1300000000,
        });
        final reprocessed = ManualImportItem.fromJson({
          'path': '/downloads/Frieren.S02E05.mkv',
          'name': 'Frieren.S02E05.mkv',
          'size': 0,
        });
        final assignment = ManualImportFixAssignment(
          match: ManualImportLookupResult(
            id: 10,
            title: 'Frieren',
            raw: {'id': 10, 'title': 'Frieren', 'year': 2023},
          ),
          episode: ManualImportEpisode(
            id: 50,
            seasonNumber: 2,
            episodeNumber: 5,
            title: 'Episode 5',
            raw: {
              'id': 50,
              'seasonNumber': 2,
              'episodeNumber': 5,
              'title': 'Episode 5',
            },
          ),
        );

        final resolved = original
            .mergedWithReprocessed(reprocessed)
            .resolvedWithAssignment(ServiceKey.sonarr, assignment);

        expect(resolved.size, 1300000000);
        expect(resolved.mediaSubtitle, contains('S02E05'));
        expect(resolved.hasMatchFor(ServiceKey.sonarr), isTrue);
      },
    );

    test('requires only import-blocking ids for sonarr readiness', () {
      final item = ManualImportItem.fromJson({
        'path': '/downloads/Frieren.S02E05.mkv',
        'name': 'Frieren.S02E05.mkv',
        'series': {'id': 10, 'title': 'Frieren'},
        'episodes': [
          {'id': 50, 'seasonNumber': 2, 'episodeNumber': 5, 'title': 'E5'},
        ],
        'rejections': [
          {'reason': 'Unable to determine quality', 'type': 'permanent'},
        ],
      });

      expect(item.hasBlockingMetadataRejection, isTrue);
      expect(item.isReadyForImportFor(ServiceKey.sonarr), isTrue);
    });

    test('reads quality label from nested quality payloads', () {
      final item = ManualImportItem.fromJson({
        'path': '/downloads/Frozen.2.mkv',
        'name': 'Frozen.2.mkv',
        'quality': {
          'quality': {
            'quality': {'id': 7, 'name': 'Bluray-1080p'},
          },
        },
      });

      expect(item.qualityLabel, 'Bluray-1080p');
      expect(item.qualityId, 7);
    });
  });

  group('ManualImportMode', () {
    test('api value uses lowercase enum name', () {
      expect(ManualImportMode.auto.apiValue, 'auto');
      expect(ManualImportMode.move.apiValue, 'move');
      expect(ManualImportMode.copy.apiValue, 'copy');
    });
  });
}
