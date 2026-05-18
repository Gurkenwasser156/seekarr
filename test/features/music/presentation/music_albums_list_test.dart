import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/music/domain/models/lidarr_album.dart';
import 'package:seekarr/features/music/domain/models/lidarr_track.dart';
import 'package:seekarr/features/music/presentation/widgets/music_albums_list.dart';

import '../../../test_helpers/fake_services.dart';
import '../../../test_helpers/model_builders.dart';

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
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.byType(MediaSearchPopupMenu), findsOneWidget);
      expect(find.byType(StatusBadge), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);
    });

    testWidgets('renders availability badges for album completion states', (
      tester,
    ) async {
      await _pumpAlbumsList(
        tester,
        albums: [
          _album(id: 10, title: 'Complete', fileCount: 12, trackCount: 12),
          _album(id: 11, title: 'Half Album', fileCount: 6, trackCount: 12),
          _album(id: 12, title: 'Empty Album', fileCount: 0, trackCount: 12),
        ],
      );

      expect(find.byType(ExpansionTile), findsNWidgets(3));
      expect(find.byType(StatusBadge), findsNWidgets(3));
      expect(find.text('12 / 12 tracks'), findsOneWidget);
      expect(find.text('6 / 12 tracks'), findsOneWidget);
      expect(find.text('0 / 12 tracks'), findsOneWidget);
    });

    testWidgets('loads and sorts tracks when album expands', (tester) async {
      final lidarrService = _FakeLidarrService(
        tracksByAlbum: {
          10: [
            buildTrack(
              id: 3,
              mediumNumber: 2,
              trackNumber: '1',
              title: 'Lucky',
            ),
            buildTrack(
              id: 1,
              mediumNumber: 1,
              trackNumber: '10',
              title: 'No Surprises',
            ),
            buildTrack(
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

LidarrAlbum _album({
  int id = 10,
  String title = 'OK Computer',
  int trackCount = 12,
  int fileCount = 12,
}) => buildAlbum(
  id: id,
  title: title,
  releaseDate: '1997-06-16',
  statistics: {'totalTrackCount': trackCount, 'trackFileCount': fileCount},
);

class _FakeLidarrService extends FakeLidarrService {
  _FakeLidarrService({
    this.tracksByAlbum = const {},
    this.throwForAlbumIds = const {},
  });

  final Map<int, List<LidarrTrack>> tracksByAlbum;
  final Set<int> throwForAlbumIds;
  final List<int> loadedAlbumIds = [];

  @override
  Future<List<LidarrTrack>> getTracks(int albumId) async {
    loadedAlbumIds.add(albumId);
    if (throwForAlbumIds.contains(albumId)) {
      throw Exception('boom');
    }

    return tracksByAlbum[albumId] ?? const [];
  }
}
