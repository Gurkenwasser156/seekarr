import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/music/domain/models/lidarr_album.dart';
import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';
import 'package:seekarr/features/music/presentation/music_detail_provider.dart';
import 'package:seekarr/features/music/presentation/music_detail_screen.dart';
import 'package:seekarr/features/music/presentation/widgets/music_albums_list.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

import '../../../test_helpers/fake_services.dart';
import '../../../test_helpers/model_builders.dart';

LidarrArtist _artist() => buildArtist(
  artistName: 'Radiohead',
  overview: 'An English rock band.',
  statistics: const {'albumCount': 9, 'trackCount': 120, 'trackFileCount': 100},
  genres: const ['Rock', 'Alternative'],
  artistType: 'Group',
  disambiguation: 'UK band',
  path: '/music/Radiohead',
);

List<LidarrAlbum> _albums() => [
  buildAlbum(
    id: 10,
    title: 'OK Computer',
    releaseDate: '1997-06-16',
    statistics: const {'totalTrackCount': 12, 'trackFileCount': 12},
  ),
];

void main() {
  group('MusicDetailScreen', () {
    testWidgets('shows loading state when provider is loading', (tester) async {
      await _pumpMusicDetail(
        tester,
        detailBuilder: (ref, artistId) => Completer<LidarrArtist?>().future,
        albumsBuilder: (ref, artistId) => Completer<List<LidarrAlbum>>().future,
      );
      await tester.pump();

      expect(find.byType(MediaDetailLoadingView), findsOneWidget);
    });

    testWidgets('shows error text for generic errors', (tester) async {
      await _pumpMusicDetail(
        tester,
        detailBuilder: (ref, artistId) =>
            Future<LidarrArtist?>.error(Exception('Network error')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('shows not configured placeholder for configuration errors', (
      tester,
    ) async {
      await _pumpMusicDetail(
        tester,
        detailBuilder: (ref, artistId) =>
            Future<LidarrArtist?>.error(Exception('Lidarr not configured')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotConfiguredPlaceholder), findsOneWidget);
    });

    testWidgets('renders artist detail content with albums when loaded', (
      tester,
    ) async {
      await _pumpMusicDetail(
        tester,
        detailBuilder: (ref, artistId) async => _artist(),
      );
      await tester.pumpAndSettle();
      await _scrollUntilVisible(tester, find.text('Albums'));

      expect(find.text('Radiohead'), findsAtLeastNWidgets(1));
      expect(find.text('An English rock band.'), findsOneWidget);
      expect(find.text('Albums'), findsOneWidget);
      expect(find.byType(MusicAlbumsList), findsOneWidget);
      expect(find.byType(MediaInfoCard), findsOneWidget);
    });

    testWidgets('uses initialArtist while provider is still loading', (
      tester,
    ) async {
      await _pumpMusicDetail(
        tester,
        detailBuilder: (ref, artistId) => Completer<LidarrArtist?>().future,
        initialArtist: _artist(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Radiohead'), findsAtLeastNWidgets(1));
      expect(find.byType(MediaDetailLoadingView), findsNothing);
    });

    testWidgets('shows album and track count tags', (tester) async {
      await _pumpMusicDetail(
        tester,
        detailBuilder: (ref, artistId) async => _artist(),
      );
      await tester.pumpAndSettle();

      expect(find.text('9 Albums'), findsOneWidget);
      expect(find.text('120 Tracks'), findsOneWidget);
      expect(find.byType(TagChip), findsAtLeastNWidgets(2));
    });

    testWidgets('shows albums loading indicator while albums are loading', (
      tester,
    ) async {
      await _pumpMusicDetail(
        tester,
        detailBuilder: (ref, artistId) async => _artist(),
        albumsBuilder: (ref, artistId) => Completer<List<LidarrAlbum>>().future,
      );
      await tester.pump();
      await tester.pump();
      await _scrollUntilVisible(tester, find.text('Albums'), settle: false);

      expect(find.text('Radiohead'), findsAtLeastNWidgets(1));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  bool settle = true,
}) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _pumpMusicDetail(
  WidgetTester tester, {
  required FutureOr<LidarrArtist?> Function(Ref ref, int artistId)
  detailBuilder,
  FutureOr<List<LidarrAlbum>> Function(Ref ref, int artistId)? albumsBuilder,
  LidarrArtist? initialArtist,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentSettingsProvider.overrideWith(
          (ref) => const SettingsModel(
            lidarrUrl: 'http://localhost:8686',
            lidarrApiKey: 'key',
          ),
        ),
        musicDetailProvider.overrideWith(detailBuilder),
        musicAlbumsProvider.overrideWith(
          albumsBuilder ?? (ref, artistId) async => _albums(),
        ),
        lidarrServiceProvider.overrideWith((ref) => FakeLidarrService()),
      ],
      child: MaterialApp(
        home: MusicDetailScreen(
          artistId: 1,
          heroTag: 'music-1',
          initialArtist: initialArtist,
        ),
      ),
    ),
  );
}
