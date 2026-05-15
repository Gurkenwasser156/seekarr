import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/widgets/media_search_popup_menu.dart';
import 'package:seekarr/features/activity/presentation/activity_provider.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_item_tiles.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

import '../../../../test_helpers/fake_services.dart';

void main() {
  group('QueueItemTile', () {
    testWidgets('renders media-first title, release details, and warning', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QueueItemTile(
              item: {
                'title': 'Movie.2024.2160p.WEB-DL-GROUP',
                'movie': {'title': 'Movie', 'year': 2024},
                'status': 'downloading',
                'trackedDownloadStatus': 'warning',
                'protocol': 'torrent',
                'timeleft': '00:12:00',
                'size': 100,
                'sizeleft': 17,
                'statusMessages': [
                  {
                    'title': 'Import Warning',
                    'messages': ['Needs manual import'],
                  },
                ],
              },
              serviceType: ServiceType.movies,
            ),
          ),
        ),
      );

      expect(find.text('Movie (2024)'), findsOneWidget);
      expect(
        find.textContaining('Movie.2024.2160p.WEB-DL-GROUP'),
        findsOneWidget,
      );
      expect(find.text('Warning'), findsOneWidget);
      expect(find.textContaining('Needs manual import'), findsNothing);
      expect(find.text('torrent'), findsOneWidget);
      expect(find.text('Downloading (83%)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('renders fallback title for missing fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QueueItemTile(item: {}, serviceType: ServiceType.movies),
          ),
        ),
      );

      expect(find.text('Unknown release'), findsOneWidget);
    });

    testWidgets('does not invent episode zero when episode number is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QueueItemTile(
              item: {
                'title': 'Frieren.S02.Pack.1080p.WEB-DL-GROUP',
                'series': {'title': 'Frieren: Beyond Journey\'s End'},
                'seasonNumber': 2,
              },
              serviceType: ServiceType.series,
            ),
          ),
        ),
      );

      expect(find.text('Frieren: Beyond Journey\'s End'), findsOneWidget);
      expect(
        find.textContaining('Frieren.S02.Pack.1080p.WEB-DL-GROUP'),
        findsOneWidget,
      );
      expect(find.textContaining('S02E00'), findsNothing);
    });
  });

  group('HistoryItemTile', () {
    testWidgets('renders media-first title and release name as secondary', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryItemTile(
              item: {
                'sourceTitle': 'Release.Name',
                'eventType': 'grabbed',
                'protocol': 'torrent',
                'movie': {'title': 'Movie Title', 'year': 2024},
              },
              serviceType: ServiceType.movies,
            ),
          ),
        ),
      );

      expect(find.text('Movie Title (2024)'), findsOneWidget);
      expect(find.text('Release.Name'), findsOneWidget);
      expect(find.text('Grabbed'), findsOneWidget);
      expect(find.text('torrent'), findsNothing);
    });

    testWidgets('renders episode code for series history', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryItemTile(
              item: {
                'sourceTitle': 'Release.Name',
                'eventType': 'downloadImported',
                'episode': {'seasonNumber': 1, 'episodeNumber': 2},
              },
              serviceType: ServiceType.series,
            ),
          ),
        ),
      );

      expect(find.text('S01E02'), findsWidgets);
      expect(find.text('Imported'), findsOneWidget);
    });

    testWidgets('renders date-only history metadata', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryItemTile(
              item: {
                'sourceTitle': 'Release.Name',
                'eventType': 'grabbed',
                'date': '2026-04-03T12:34:56Z',
              },
              serviceType: ServiceType.movies,
            ),
          ),
        ),
      );

      expect(find.textContaining('2026-04-03'), findsOneWidget);
      expect(find.textContaining('12:34'), findsNothing);
    });
  });

  group('BlocklistItemTile', () {
    testWidgets('renders media-first title and reason', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlocklistItemTile(
              item: {
                'sourceTitle': 'Bad.Release',
                'message': 'Rejected',
                'movie': {'title': 'Movie Title', 'year': 2024},
              },
              serviceType: ServiceType.movies,
            ),
          ),
        ),
      );

      expect(find.text('Movie Title (2024)'), findsOneWidget);
      expect(find.text('Bad.Release'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.byIcon(Icons.block_rounded), findsOneWidget);
    });

    testWidgets('renders fallback title when sourceTitle missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlocklistItemTile(item: {}, serviceType: ServiceType.movies),
          ),
        ),
      );

      expect(find.text('Unknown release'), findsOneWidget);
    });
  });

  group('WantedItemTile', () {
    testWidgets('renders movie title without subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WantedItemTile(
              item: {'title': 'Cool Movie'},
              serviceType: ServiceType.movies,
            ),
          ),
        ),
      );

      expect(find.text('Cool Movie'), findsOneWidget);
    });

    testWidgets('renders search popup when callbacks provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WantedItemTile(
              item: const {'title': 'Cool Movie'},
              serviceType: ServiceType.movies,
              onAutoSearch: () {},
              onInteractiveSearch: () {},
            ),
          ),
        ),
      );

      expect(find.byType(MediaSearchPopupMenu), findsOneWidget);
    });

    testWidgets('hides search popup when callbacks missing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WantedItemTile(
              item: {'title': 'Cool Movie'},
              serviceType: ServiceType.movies,
            ),
          ),
        ),
      );

      expect(find.byType(MediaSearchPopupMenu), findsNothing);
    });

    testWidgets('renders series format with subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WantedItemTile(
              item: {
                'title': 'Pilot',
                'seasonNumber': 1,
                'episodeNumber': 1,
                'series': {'title': 'Breaking Bad'},
              },
              serviceType: ServiceType.series,
            ),
          ),
        ),
      );

      expect(find.text('S01E01 · Pilot'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsOneWidget);
    });

    testWidgets('renders music with artist subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WantedItemTile(
              item: {
                'title': 'Album Name',
                'artist': {'artistName': 'Artist Name'},
              },
              serviceType: ServiceType.music,
            ),
          ),
        ),
      );

      expect(find.text('Album Name'), findsOneWidget);
      expect(find.text('Artist Name'), findsOneWidget);
    });

    testWidgets('cutoff movie shows quality chip and size highlight', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WantedItemTile(
              item: {
                'title': 'Long Movie Title',
                'status': 'released',
                'qualityProfileId': 7,
                'sizeOnDisk': 8003897815,
                'airDateUtc': '2026-04-03T12:34:56Z',
              },
              serviceType: ServiceType.movies,
              isCutoff: true,
              qualityProfileName: 'HD-1080p',
            ),
          ),
        ),
      );

      expect(find.text('HD-1080p'), findsOneWidget);
      expect(find.text('7.45 GB'), findsOneWidget);
      expect(find.textContaining('Release 2026-04-03'), findsNothing);
      expect(find.text('Released'), findsNothing);
    });

    testWidgets('handles missing series data gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WantedItemTile(item: {}, serviceType: ServiceType.series),
          ),
        ),
      );

      expect(find.text('Unknown Episode'), findsOneWidget);
      expect(find.text('Unknown Series'), findsOneWidget);
    });
  });

  group('Queue status normalization', () {
    testWidgets('prefers trackedDownloadState over completed status', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QueueItemTile(
              item: {
                'title': 'Queued Import',
                'trackedDownloadState': 'importPending',
                'status': 'completed',
              },
              serviceType: ServiceType.movies,
            ),
          ),
        ),
      );

      expect(find.text('Import Pending'), findsOneWidget);
      expect(find.text('Available'), findsNothing);
    });

    testWidgets('shows no inline progress when not downloading', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QueueItemTile(
              item: {
                'title': 'Completed Item',
                'status': 'completed',
                'size': 100,
                'sizeleft': 0,
              },
              serviceType: ServiceType.movies,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('GlobalActivityItemTile', () {
    testWidgets('shows warning badge and media-first hierarchy for queue items', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GlobalActivityItemTile(
                item: GlobalActivityItem(
                  kind: GlobalActivityKind.queue,
                  service: ServiceKey.sonarr,
                  serviceType: ServiceType.series,
                  title: 'Frieren: Beyond Journey\'s End',
                  subtitle:
                      'S01E03 · Killing Magic · Frieren.S01E03.1080p.WEB-DL-GROUP',
                  status: 'Completed',
                  progress: 1,
                  warning: 'Import Warning: Unable to Import Automatically',
                  raw: {
                    'title': 'Frieren.S01E03.1080p.WEB-DL-GROUP',
                    'series': {'title': 'Frieren: Beyond Journey\'s End'},
                    'episode': {
                      'seasonNumber': 1,
                      'episodeNumber': 3,
                      'title': 'Killing Magic',
                    },
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Frieren: Beyond Journey\'s End'), findsOneWidget);
      expect(
        find.textContaining('Frieren.S01E03.1080p.WEB-DL-GROUP'),
        findsOneWidget,
      );
      expect(find.text('Warning'), findsOneWidget);
      expect(
        find.textContaining('Unable to Import Automatically'),
        findsNothing,
      );
    });

    testWidgets('shows search menu for searchable wanted items', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            radarrServiceProvider.overrideWith((ref) => FakeRadarrService()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GlobalActivityItemTile(
                item: GlobalActivityItem(
                  kind: GlobalActivityKind.missing,
                  service: ServiceKey.radarr,
                  serviceType: ServiceType.movies,
                  title: 'Cool Movie',
                  subtitle: 'Radarr',
                  status: 'Missing',
                  raw: {'id': 42, 'title': 'Cool Movie'},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cool Movie'), findsOneWidget);
      expect(find.byType(MediaSearchPopupMenu), findsOneWidget);
    });

    testWidgets('hides search menu for requests', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GlobalActivityItemTile(
                item: GlobalActivityItem(
                  kind: GlobalActivityKind.request,
                  service: ServiceKey.seerr,
                  serviceType: ServiceType.discover,
                  title: 'Shogun',
                  subtitle: 'sarah · Series',
                  status: 'Requested',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Shogun'), findsOneWidget);
      expect(find.byType(MediaSearchPopupMenu), findsNothing);
    });
  });
}
