import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_item_tiles.dart';

void main() {
  group('QueueItemTile', () {
    testWidgets('renders title and status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QueueItemTile(
              item: {'title': 'Movie.2024', 'status': 'downloading'},
            ),
          ),
        ),
      );

      expect(find.text('Movie.2024'), findsOneWidget);
      expect(find.text('Status: downloading'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('renders Unknown for missing fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: QueueItemTile(item: {})),
        ),
      );

      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('Status: Unknown'), findsOneWidget);
    });
  });

  group('HistoryItemTile', () {
    testWidgets('renders sourceTitle and eventType', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryItemTile(
              item: {'sourceTitle': 'Release.Name', 'eventType': 'grabbed'},
            ),
          ),
        ),
      );

      expect(find.text('Release.Name'), findsOneWidget);
      expect(find.text('grabbed'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('renders Unknown for missing fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HistoryItemTile(item: {})),
        ),
      );

      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('unknown'), findsOneWidget);
    });
  });

  group('BlocklistItemTile', () {
    testWidgets('renders sourceTitle and blocked subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlocklistItemTile(item: {'sourceTitle': 'Bad.Release'}),
          ),
        ),
      );

      expect(find.text('Bad.Release'), findsOneWidget);
      expect(find.text('Blocked'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('renders Unknown when sourceTitle missing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BlocklistItemTile(item: {})),
        ),
      );

      expect(find.text('Unknown'), findsOneWidget);
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
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
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

      expect(find.textContaining('01 - Pilot'), findsOneWidget);
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

    testWidgets('handles missing series data gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WantedItemTile(item: {}, serviceType: ServiceType.series),
          ),
        ),
      );

      expect(find.text('Unknown Series'), findsOneWidget);
      expect(find.textContaining('Unknown Episode'), findsOneWidget);
    });
  });
}
