import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/discover/domain/models/discover_detail_model.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_action_buttons.dart';

void main() {
  group('DiscoverActionButtons', () {
    testWidgets('shows request plus videos and manage icon buttons', (
      tester,
    ) async {
      await _pumpButtons(tester, hasManageableMedia: false, isInService: false);

      expect(find.text('Request'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    });

    testWidgets('shows requested state and manage icon for manageable movie', (
      tester,
    ) async {
      await _pumpButtons(
        tester,
        mediaType: 'movie',
        hasManageableMedia: true,
        isInService: false,
        mediaInfo: const {'id': 1},
      );

      expect(find.text('Requested'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.text('Manage Movie'), findsNothing);
    });

    testWidgets('uses manage icon for manageable series', (tester) async {
      await _pumpButtons(
        tester,
        mediaType: 'tv',
        hasManageableMedia: true,
        isInService: false,
        mediaInfo: const {'id': 1},
      );

      expect(find.text('Requested'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.text('Manage Series'), findsNothing);
    });

    testWidgets('uses open icon when movie is only in service', (tester) async {
      await _pumpButtons(
        tester,
        mediaType: 'movie',
        hasManageableMedia: false,
        isInService: true,
      );

      expect(find.text('Requested'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    });

    testWidgets('uses open icon when series is only in service', (
      tester,
    ) async {
      await _pumpButtons(
        tester,
        mediaType: 'tv',
        hasManageableMedia: false,
        isInService: true,
      );

      expect(find.text('Requested'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    });
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
