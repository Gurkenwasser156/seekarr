import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';

void main() {
  group('FloatingBottomNavBar', () {
    testWidgets('shows only the selected label in the compact nav pill', (
      tester,
    ) async {
      await _pumpNavBar(tester, selectedIndex: 0);

      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Activity'), findsNothing);
      expect(find.text('Search'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('uses the destination accent color for the selected icon', (
      tester,
    ) async {
      await _pumpNavBar(tester, selectedIndex: 1);

      final icon = tester.widget<Icon>(find.byIcon(Icons.bolt_rounded));

      expect(icon.color, AppColors.radarr);
      expect(find.text('Activity'), findsOneWidget);
    });

    testWidgets('slides the selected pill between destinations', (
      tester,
    ) async {
      await _pumpNavBar(tester, selectedIndex: 0);

      final startLeft = _indicatorRect(tester).left;

      await _pumpNavBar(tester, selectedIndex: 2, settle: false);
      await tester.pump(const Duration(milliseconds: 80));

      final midLeft = _indicatorRect(tester).left;

      expect(midLeft, greaterThan(startLeft));
      expect(midLeft, lessThan(_searchItemRect(tester).left));

      await tester.pumpAndSettle();

      final endRect = _indicatorRect(tester);
      final searchRect = _searchItemRect(tester);
      expect(endRect.center.dx, closeTo(searchRect.center.dx, 0.5));
      expect(endRect.left, greaterThan(searchRect.left));
      expect(endRect.right, lessThan(searchRect.right));
    });

    testWidgets('applies elastic drag and springs back to rest', (
      tester,
    ) async {
      await _pumpNavBar(tester, selectedIndex: 0);

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('floating-nav-drag-transform')),
        ),
      );
      await gesture.moveBy(const Offset(40, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(40, 20));
      await tester.pump();

      final dragged = _dragTransform(tester).transform.getTranslation();
      expect(dragged.x, greaterThan(0));
      expect(dragged.x, lessThan(40));
      expect(dragged.x, lessThanOrEqualTo(15));
      expect(dragged.y, greaterThan(0));
      expect(dragged.y, lessThan(20));
      expect(dragged.y, lessThanOrEqualTo(15));

      await gesture.up();
      await tester.pumpAndSettle();

      final settled = _dragTransform(tester).transform.getTranslation();
      expect(settled.x, closeTo(0, 0.01));
      expect(settled.y, closeTo(0, 0.01));
    });
  });
}

Future<void> _pumpNavBar(
  WidgetTester tester, {
  required int selectedIndex,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme(null),
      home: Scaffold(
        bottomNavigationBar: FloatingBottomNavBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (_) {},
          destinations: const [
            FloatingNavDestination(
              icon: Icons.view_list_outlined,
              selectedIcon: Icons.view_list_rounded,
              label: 'Services',
              accentColor: AppColors.seerr,
            ),
            FloatingNavDestination(
              icon: Icons.bolt_outlined,
              selectedIcon: Icons.bolt_rounded,
              label: 'Activity',
              accentColor: AppColors.radarr,
            ),
            FloatingNavDestination(
              icon: Icons.search_outlined,
              selectedIcon: Icons.search_rounded,
              label: 'Search',
              accentColor: AppColors.seerr,
            ),
            FloatingNavDestination(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Settings',
              accentColor: AppColors.onSurfaceVariantDark,
            ),
          ],
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

Transform _dragTransform(WidgetTester tester) {
  return tester.widget<Transform>(
    find.byKey(const ValueKey('floating-nav-drag-transform')),
  );
}

Rect _indicatorRect(WidgetTester tester) {
  return tester.getRect(find.byKey(const ValueKey('floating-nav-indicator')));
}

Rect _searchItemRect(WidgetTester tester) {
  return tester.getRect(find.byKey(const ValueKey('floating-nav-item-search')));
}
