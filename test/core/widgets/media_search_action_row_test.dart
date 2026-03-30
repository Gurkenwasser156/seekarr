import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/widgets/media_search_action_row.dart';

void main() {
  group('MediaSearchActionRow', () {
    testWidgets('both buttons enabled when not loading', (tester) async {
      var autoPressed = false;
      var interactivePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaSearchActionRow(
              onAutomaticSearch: () => autoPressed = true,
              onInteractiveSearch: () => interactivePressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Automatic Search'));
      await tester.pump();
      await tester.tap(find.text('Interactive Search'));
      await tester.pump();

      expect(autoPressed, isTrue);
      expect(interactivePressed, isTrue);
    });

    testWidgets('automatic search button disabled when isSearching is true', (
      tester,
    ) async {
      var autoPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaSearchActionRow(
              isSearching: true,
              onAutomaticSearch: () => autoPressed = true,
              onInteractiveSearch: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Automatic Search'));
      await tester.pump();

      expect(autoPressed, isFalse);
    });

    testWidgets(
      'interactive search button disabled when isLoadingReleases is true',
      (tester) async {
        var interactivePressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaSearchActionRow(
                isLoadingReleases: true,
                onAutomaticSearch: () {},
                onInteractiveSearch: () => interactivePressed = true,
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.text('Interactive Search'));
        await tester.pump();

        expect(interactivePressed, isFalse);
      },
    );

    testWidgets('shows correct button labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MediaSearchActionRow())),
      );

      expect(find.text('Automatic Search'), findsOneWidget);
      expect(find.text('Interactive Search'), findsOneWidget);
    });

    testWidgets('null callbacks disable buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MediaSearchActionRow())),
      );

      final buttons = tester.widgetList<ButtonStyleButton>(
        find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
      );
      expect(buttons.length, 2);
      expect(buttons.every((button) => button.onPressed == null), isTrue);
    });

    testWidgets(
      'uses FilledButton for primary and OutlinedButton for secondary',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: MediaSearchActionRow())),
        );

        // FilledButton.icon returns _FilledButtonWithIcon, a private subclass,
        // so find.byType(FilledButton) won't match; use an `is` predicate.
        expect(
          find.byWidgetPredicate((w) => w is FilledButton),
          findsOneWidget,
        );
        expect(find.byType(OutlinedButton), findsOneWidget);
      },
    );
  });
}
