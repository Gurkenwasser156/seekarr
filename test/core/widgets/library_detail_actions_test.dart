import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/widgets/library_detail_actions.dart';

void main() {
  group('LibraryDetailActions', () {
    testWidgets('shows add button only when item is not in library', (
      tester,
    ) async {
      var primaryPressed = false;

      await _pumpActions(
        tester,
        isInLibrary: false,
        isMonitored: false,
        addLabel: 'Add Movie',
        onPrimaryAction: () => primaryPressed = true,
      );

      expect(find.text('Add Movie'), findsOneWidget);
      expect(find.text('Interactive'), findsNothing);
      expect(find.text('Auto Search'), findsNothing);
      expect(find.text('Delete'), findsNothing);

      await tester.tap(find.text('Add Movie'));
      await tester.pump();

      expect(primaryPressed, isTrue);
    });

    testWidgets('shows unmonitor and management actions for monitored items', (
      tester,
    ) async {
      await _pumpActions(
        tester,
        isInLibrary: true,
        isMonitored: true,
        addLabel: 'Add Series',
        currentProfileName: 'HD-1080p',
      );

      expect(find.text('Unmonitor'), findsOneWidget);
      expect(find.text('Interactive'), findsOneWidget);
      expect(find.text('Auto Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Import'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Add Series'), findsNothing);
    });

    testWidgets('shows monitor and hides profile action without profile name', (
      tester,
    ) async {
      await _pumpActions(
        tester,
        isInLibrary: true,
        isMonitored: false,
        addLabel: 'Add Artist',
      );

      expect(find.text('Monitor'), findsOneWidget);
      expect(find.text('Interactive'), findsOneWidget);
      expect(find.text('Auto Search'), findsOneWidget);
      expect(find.text('Profile'), findsNothing);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('disables primary action while monitoring state is updating', (
      tester,
    ) async {
      var primaryPressed = false;

      await _pumpActions(
        tester,
        isInLibrary: true,
        isMonitored: true,
        addLabel: 'Add Movie',
        isUpdatingMonitoredState: true,
        onPrimaryAction: () => primaryPressed = true,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Unmonitor'));
      await tester.pump();

      expect(primaryPressed, isFalse);
    });
  });
}

Future<void> _pumpActions(
  WidgetTester tester, {
  required bool isInLibrary,
  required bool isMonitored,
  required String addLabel,
  String? currentProfileName,
  bool isUpdatingMonitoredState = false,
  VoidCallback? onPrimaryAction,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LibraryDetailActions(
          collapseFactor: 0,
          isInLibrary: isInLibrary,
          isMonitored: isMonitored,
          addLabel: addLabel,
          isSearching: false,
          isDeleting: false,
          isUpdatingMonitoredState: isUpdatingMonitoredState,
          currentProfileName: currentProfileName,
          currentProfileId: 1,
          qualityProfiles: const [
            {'id': 1, 'name': 'HD-1080p'},
          ],
          onPrimaryAction: onPrimaryAction ?? () {},
          onInteractiveSearch: () {},
          onAutoSearch: () {},
          onProfileSelected: (_) async {},
          onDelete: () {},
        ),
      ),
    ),
  );
}
