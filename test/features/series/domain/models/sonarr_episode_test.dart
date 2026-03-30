import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/series/domain/models/sonarr_episode.dart';

void main() {
  group('SonarrEpisode', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final episode = SonarrEpisode.fromJson({
          'id': 11,
          'seasonNumber': 2,
          'episodeNumber': 4,
          'title': 'Episode Title',
          'hasFile': true,
          'monitored': true,
        });

        expect(episode.id, 11);
        expect(episode.seasonNumber, 2);
        expect(episode.episodeNumber, 4);
        expect(episode.title, 'Episode Title');
        expect(episode.hasFile, isTrue);
        expect(episode.monitored, isTrue);
      });

      test('falls back safely for missing values', () {
        final episode = SonarrEpisode.fromJson(<String, dynamic>{});

        expect(episode.id, 0);
        expect(episode.seasonNumber, 0);
        expect(episode.episodeNumber, 0);
        expect(episode.title, 'Episode ?');
        expect(episode.hasFile, isFalse);
        expect(episode.monitored, isFalse);
      });

      test('uses episode number in fallback title when title is blank', () {
        final episode = SonarrEpisode.fromJson({
          'episodeNumber': 8,
          'title': '   ',
        });

        expect(episode.title, 'Episode 8');
      });
    });
  });
}
