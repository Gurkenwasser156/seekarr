import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/app_spacing.dart';
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
      _setTestViewport(tester, const Size(390, 844));

      await _pumpNavBar(tester, selectedIndex: 0);

      final startRect = _indicatorRect(tester);
      final startLeft = startRect.left;

      await _pumpNavBar(tester, selectedIndex: 2, settle: false);
      await tester.pump(const Duration(milliseconds: 80));

      final midLeft = _indicatorRect(tester).left;

      expect(midLeft, greaterThan(startLeft));

      await tester.pumpAndSettle();

      final endRect = _indicatorRect(tester);
      final searchRect = _itemRect(tester, 'search');
      expect(midLeft, lessThan(endRect.left));
      expect(startRect.width, greaterThan(endRect.width));
      expect(endRect.center.dx, closeTo(searchRect.center.dx, 0.5));
      expect(endRect.left, greaterThanOrEqualTo(searchRect.left - 0.5));
      expect(endRect.right, lessThanOrEqualTo(searchRect.right + 0.5));
    });

    testWidgets(
      'uses a compact centered navbar and aligns edge selections on iPhone widths',
      (tester) async {
        _setTestViewport(tester, const Size(390, 844));

        await _pumpNavBar(tester, selectedIndex: 0);

        expect(tester.takeException(), isNull);

        final servicesRect = _itemRect(tester, 'services');
        final activityRect = _itemRect(tester, 'activity');
        final searchRect = _itemRect(tester, 'search');
        final settingsRect = _itemRect(tester, 'settings');
        final servicesIndicatorRect = _indicatorRect(tester);
        final navSurfaceRect = _navSurfaceRect(tester);
        final maxSurfaceWidth = 390.0 - (AppSpacing.lg * 2);

        expect(navSurfaceRect.width, lessThan(maxSurfaceWidth));
        expect(navSurfaceRect.center.dx, closeTo(195.0, 0.5));
        expect(servicesRect.width, greaterThan(activityRect.width));
        expect(servicesRect.width, greaterThan(searchRect.width));
        expect(servicesRect.width, greaterThan(settingsRect.width));
        expect(activityRect.width, closeTo(searchRect.width, 0.5));
        expect(
          servicesIndicatorRect.center.dx,
          closeTo(servicesRect.center.dx, 0.5),
        );
        expect(
          servicesIndicatorRect.width,
          lessThanOrEqualTo(servicesRect.width + 0.5),
        );
        expect(
          servicesIndicatorRect.left,
          greaterThanOrEqualTo(servicesRect.left - 0.5),
        );
        expect(
          servicesIndicatorRect.right,
          lessThanOrEqualTo(servicesRect.right + 0.5),
        );

        await _pumpNavBar(tester, selectedIndex: 3);

        expect(tester.takeException(), isNull);

        final selectedSettingsRect = _itemRect(tester, 'settings');
        final settingsIndicatorRect = _indicatorRect(tester);
        final updatedNavSurfaceRect = _navSurfaceRect(tester);

        expect(
          selectedSettingsRect.width,
          greaterThan(_itemRect(tester, 'search').width),
        );
        expect(updatedNavSurfaceRect.width, closeTo(navSurfaceRect.width, 0.5));
        expect(
          updatedNavSurfaceRect.center.dx,
          closeTo(navSurfaceRect.center.dx, 0.5),
        );
        expect(
          settingsIndicatorRect.center.dx,
          closeTo(selectedSettingsRect.center.dx, 0.5),
        );
        expect(
          settingsIndicatorRect.width,
          lessThanOrEqualTo(selectedSettingsRect.width + 0.5),
        );
        expect(
          settingsIndicatorRect.left,
          greaterThanOrEqualTo(selectedSettingsRect.left - 0.5),
        );
        expect(
          settingsIndicatorRect.right,
          lessThanOrEqualTo(selectedSettingsRect.right + 0.5),
        );
      },
    );

    testWidgets('stays anchored near the bottom of the viewport', (
      tester,
    ) async {
      _setTestViewport(tester, const Size(390, 844));

      await _pumpNavBar(tester, selectedIndex: 0);

      final navSurfaceRect = _navSurfaceRect(tester);
      final distanceFromBottom = 844.0 - navSurfaceRect.bottom;

      expect(distanceFromBottom, greaterThanOrEqualTo(0));
      expect(
        distanceFromBottom,
        lessThanOrEqualTo(
          FloatingNavBarMetrics.bottomPadding +
              MediaQueryData.fromView(tester.view).padding.bottom +
              12,
        ),
      );
      expect(navSurfaceRect.center.dy, greaterThan(700));
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

void _setTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Transform _dragTransform(WidgetTester tester) {
  return tester.widget<Transform>(
    find.byKey(const ValueKey('floating-nav-drag-transform')),
  );
}

Rect _indicatorRect(WidgetTester tester) {
  return tester.getRect(find.byKey(const ValueKey('floating-nav-indicator')));
}

Rect _navSurfaceRect(WidgetTester tester) {
  return tester.getRect(find.byKey(const ValueKey('floating-nav-surface')));
}

Rect _itemRect(WidgetTester tester, String label) {
  return tester.getRect(find.byKey(ValueKey('floating-nav-item-$label')));
}
