import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/music/domain/models/lidarr_album.dart';
import 'package:seekarr/features/music/domain/models/lidarr_track.dart';
import 'package:seekarr/features/music/presentation/widgets/music_albums_list.dart';

void main() {
  group('MusicAlbumsList', () {
    testWidgets('shows empty state when no albums are provided', (
      tester,
    ) async {
      await _pumpAlbumsList(tester, albums: const []);

      expect(find.text('No albums found.'), findsOneWidget);
    });

    testWidgets('renders album metadata and search actions', (tester) async {
      await _pumpAlbumsList(tester, albums: [_album()]);

      expect(find.text('OK Computer'), findsOneWidget);
      expect(find.text('1997'), findsOneWidget);
      expect(find.text('12 / 12 tracks'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);
    });

    testWidgets('loads and sorts tracks when album expands', (tester) async {
      final lidarrService = _FakeLidarrService(
        tracksByAlbum: {
          10: [
            _track(id: 3, mediumNumber: 2, trackNumber: '1', title: 'Lucky'),
            _track(
              id: 1,
              mediumNumber: 1,
              trackNumber: '10',
              title: 'No Surprises',
            ),
            _track(
              id: 2,
              mediumNumber: 1,
              trackNumber: '2',
              title: 'Paranoid Android',
            ),
          ],
        },
      );

      await _pumpAlbumsList(
        tester,
        albums: [_album()],
        lidarrService: lidarrService,
      );

      await tester.tap(find.text('OK Computer'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(lidarrService.loadedAlbumIds, [10]);
      expect(find.text('Paranoid Android'), findsOneWidget);
      expect(find.text('No Surprises'), findsOneWidget);
      expect(find.text('Lucky'), findsOneWidget);

      expect(
        tester.getTopLeft(find.text('Paranoid Android')).dy,
        lessThan(tester.getTopLeft(find.text('No Surprises')).dy),
      );
      expect(
        tester.getTopLeft(find.text('No Surprises')).dy,
        lessThan(tester.getTopLeft(find.text('Lucky')).dy),
      );
    });

    testWidgets('shows retry state when loading tracks fails', (tester) async {
      final lidarrService = _FakeLidarrService(throwForAlbumIds: {10});

      await _pumpAlbumsList(
        tester,
        albums: [_album()],
        lidarrService: lidarrService,
      );

      await tester.tap(find.text('OK Computer'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Failed to load tracks'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows no tracks message when album has no tracks', (
      tester,
    ) async {
      await _pumpAlbumsList(
        tester,
        albums: [_album()],
        lidarrService: _FakeLidarrService(tracksByAlbum: {10: const []}),
      );

      await tester.tap(find.text('OK Computer'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No tracks found.'), findsOneWidget);
    });
  });
}

Future<void> _pumpAlbumsList(
  WidgetTester tester, {
  required List<LidarrAlbum> albums,
  LidarrService? lidarrService,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MusicAlbumsList(
          albums: albums,
          lidarrService: lidarrService ?? _FakeLidarrService(),
          baseUrl: 'http://localhost:8686',
          apiKey: 'key',
          onSearchAlbum: (_) {},
          onInteractiveSearchAlbum: (_) {},
          searchingAlbums: const {},
        ),
      ),
    ),
  );
}

LidarrAlbum _album() {
  return const LidarrAlbum(
    id: 10,
    title: 'OK Computer',
    releaseDate: '1997-06-16',
    monitored: true,
    images: [],
    statistics: {'totalTrackCount': 12, 'trackFileCount': 12},
  );
}

LidarrTrack _track({
  required int id,
  int? mediumNumber,
  required dynamic trackNumber,
  required String title,
}) {
  return LidarrTrack(
    id: id,
    mediumNumber: mediumNumber,
    trackNumber: trackNumber,
    title: title,
    hasFile: true,
    duration: 180000,
  );
}

class _FakeLidarrService extends LidarrService {
  final Map<int, List<LidarrTrack>> tracksByAlbum;
  final Set<int> throwForAlbumIds;
  final List<int> loadedAlbumIds = [];

  _FakeLidarrService({
    this.tracksByAlbum = const {},
    this.throwForAlbumIds = const {},
  }) : super(ApiClient(baseUrl: 'http://localhost:8686', apiKey: 'key'));

  @override
  Future<List<LidarrTrack>> getTracks(int albumId) async {
    loadedAlbumIds.add(albumId);
    if (throwForAlbumIds.contains(albumId)) {
      throw Exception('boom');
    }

    return tracksByAlbum[albumId] ?? const [];
  }
}
