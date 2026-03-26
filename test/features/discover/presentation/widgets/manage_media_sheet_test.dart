import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/discover/presentation/widgets/manage_media_sheet.dart';

void main() {
  group('ManageMediaSheet', () {
    testWidgets(
      'remove action is a silent no-op when jellyseerr id is missing',
      (tester) async {
        var onDataChangedCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 800,
                  child: ManageMediaSheet(
                    mediaInfo: {'externalServiceId': 42, 'requests': const []},
                    mediaTitle: 'Movie',
                    mediaType: 'movie',
                    tmdbId: 123,
                    onDataChanged: () => onDataChangedCount += 1,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Remove from Radarr'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Remove from Radarr'), findsOneWidget);
        expect(onDataChangedCount, 0);
      },
    );

    testWidgets('clear data is a silent no-op when jellyseerr id is missing', (
      tester,
    ) async {
      var onDataChangedCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 800,
                child: ManageMediaSheet(
                  mediaInfo: {'externalServiceId': 42, 'requests': const []},
                  mediaTitle: 'Movie',
                  mediaType: 'movie',
                  tmdbId: 123,
                  onDataChanged: () => onDataChangedCount += 1,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Clear Data'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Clear Data'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Clear Data'), findsOneWidget);
      expect(onDataChangedCount, 0);
    });
  });
}
