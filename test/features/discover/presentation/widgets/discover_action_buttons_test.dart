import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/widgets/header_action_row.dart';
import 'package:seekarr/features/discover/domain/models/discover_detail_model.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_action_buttons.dart';

void main() {
  group('DiscoverActionButtons', () {
    testWidgets('shows only the Request row when nothing can be managed', (
      tester,
    ) async {
      await _pumpButtons(tester, hasManageableMedia: false, isInService: false);

      expect(find.byType(HeaderActionRow), findsOneWidget);
      expect(find.text('Request'), findsOneWidget);
      expect(find.text('Manage Movie'), findsNothing);
      expect(find.text('Open in Radarr'), findsNothing);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('shows Manage Movie when movie media can be managed', (
      tester,
    ) async {
      await _pumpButtons(
        tester,
        mediaType: 'movie',
        hasManageableMedia: true,
        isInService: false,
        mediaInfo: const {'id': 1},
      );

      expect(find.byType(HeaderActionRow), findsNWidgets(2));
      expect(find.text('Manage Movie'), findsOneWidget);
      expect(find.text('Manage Series'), findsNothing);
      expect(find.text('Open in Radarr'), findsNothing);
    });

    testWidgets('shows Manage Series when series media can be managed', (
      tester,
    ) async {
      await _pumpButtons(
        tester,
        mediaType: 'tv',
        hasManageableMedia: true,
        isInService: false,
        mediaInfo: const {'id': 1},
      );

      expect(find.text('Manage Series'), findsOneWidget);
      expect(find.text('Manage Movie'), findsNothing);
      expect(find.text('Open in Sonarr'), findsNothing);
    });

    testWidgets('shows Open in Radarr when movie is only in service', (
      tester,
    ) async {
      await _pumpButtons(
        tester,
        mediaType: 'movie',
        hasManageableMedia: false,
        isInService: true,
      );

      expect(find.text('Open in Radarr'), findsOneWidget);
      expect(find.text('Manage Movie'), findsNothing);
    });

    testWidgets('shows Open in Sonarr when series is only in service', (
      tester,
    ) async {
      await _pumpButtons(
        tester,
        mediaType: 'tv',
        hasManageableMedia: false,
        isInService: true,
      );

      expect(find.text('Open in Sonarr'), findsOneWidget);
      expect(find.text('Manage Series'), findsNothing);
    });

    testWidgets(
      'shows trailing open button only when media is manageable and already in service',
      (tester) async {
        await _pumpButtons(
          tester,
          hasManageableMedia: true,
          isInService: true,
          mediaInfo: const {'id': 1},
        );

        expect(find.text('Manage Movie'), findsOneWidget);
        expect(find.text('Open in Radarr'), findsNothing);
        expect(find.byIcon(Icons.open_in_new), findsOneWidget);
        expect(find.byType(HeaderActionRow), findsNWidgets(2));

        await _pumpButtons(
          tester,
          hasManageableMedia: true,
          isInService: false,
          mediaInfo: const {'id': 1},
        );

        expect(find.text('Manage Movie'), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new), findsNothing);
        expect(find.byType(HeaderActionRow), findsNWidgets(2));
      },
    );
  });
}

Future<void> _pumpButtons(
  WidgetTester tester, {
  String mediaType = 'movie',
  required bool hasManageableMedia,
  required bool isInService,
  Map<String, dynamic>? mediaInfo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: DiscoverActionButtons(
            mediaId: 123,
            mediaType: mediaType,
            hasManageableMedia: hasManageableMedia,
            isInService: isInService,
            isAvailable: false,
            tvdbId: mediaType == 'tv' ? 456 : null,
            mediaInfo: mediaInfo,
            title: 'Title',
            voteAverage: 7.5,
            collapseFactor: 0,
            videos: const <RelatedVideo>[],
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}
