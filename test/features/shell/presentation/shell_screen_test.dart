import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/features/shell/presentation/shell_screen.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('ShellScreen', () {
    testWidgets('renders the floating nav bar with five destinations', (
      tester,
    ) async {
      await _pumpShell(tester);

      expect(find.byType(FloatingBottomNavBar), findsOneWidget);
      expect(_navLabel('Discover'), findsOneWidget);
      expect(_navLabel('Movies'), findsOneWidget);
      expect(_navLabel('Series'), findsOneWidget);
      expect(_navLabel('Music'), findsOneWidget);
      expect(_navLabel('Settings'), findsOneWidget);
    });

    testWidgets('selects Discover for the /discover route', (tester) async {
      await _pumpShell(tester, initialLocation: '/discover');

      expect(find.text('DiscoverPage'), findsOneWidget);
      expect(find.byIcon(Icons.explore), findsOneWidget);
      expect(find.byIcon(Icons.explore_outlined), findsNothing);
    });

    testWidgets('selects Settings for the /settings route', (tester) async {
      await _pumpShell(tester, initialLocation: '/settings');

      expect(find.text('SettingsPage'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    testWidgets('tapping Movies navigates to /movies', (tester) async {
      final harness = await _pumpShell(tester);

      await tester.tap(_navLabel('Movies'));
      await tester.pumpAndSettle();

      expect(harness.router.state.uri.path, '/movies');
      expect(find.text('MoviesPage'), findsOneWidget);
      expect(find.byIcon(Icons.movie), findsOneWidget);
    });

    testWidgets('tapping the current Discover tab triggers a refresh', (
      tester,
    ) async {
      final harness = await _pumpShell(tester, initialLocation: '/discover');

      expect(
        harness.container.read(
          navigationRefreshProvider(NavigationSection.discover),
        ),
        0,
      );

      await tester.tap(_navLabel('Discover'));
      await tester.pumpAndSettle();

      expect(harness.router.state.uri.path, '/discover');
      expect(
        harness.container.read(
          navigationRefreshProvider(NavigationSection.discover),
        ),
        1,
      );
    });

    testWidgets('tapping the current Settings tab does not trigger refresh', (
      tester,
    ) async {
      final harness = await _pumpShell(tester, initialLocation: '/settings');

      await tester.tap(_navLabel('Settings'));
      await tester.pumpAndSettle();

      expect(harness.router.state.uri.path, '/settings');
      expect(
        harness.container.read(
          navigationRefreshProvider(NavigationSection.discover),
        ),
        0,
      );
      expect(
        harness.container.read(
          navigationRefreshProvider(NavigationSection.movies),
        ),
        0,
      );
      expect(
        harness.container.read(
          navigationRefreshProvider(NavigationSection.series),
        ),
        0,
      );
      expect(
        harness.container.read(
          navigationRefreshProvider(NavigationSection.music),
        ),
        0,
      );
    });
  });
}

Future<_ShellHarness> _pumpShell(
  WidgetTester tester, {
  String initialLocation = '/discover',
}) async {
  final container = ProviderContainer();
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/discover',
            builder: (_, __) => const Scaffold(body: Text('DiscoverPage')),
          ),
          GoRoute(
            path: '/movies',
            builder: (_, __) => const Scaffold(body: Text('MoviesPage')),
          ),
          GoRoute(
            path: '/series',
            builder: (_, __) => const Scaffold(body: Text('SeriesPage')),
          ),
          GoRoute(
            path: '/music',
            builder: (_, __) => const Scaffold(body: Text('MusicPage')),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const Scaffold(body: Text('SettingsPage')),
          ),
        ],
      ),
    ],
  );

  addTearDown(() {
    router.dispose();
    container.dispose();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return _ShellHarness(container: container, router: router);
}

Finder _navLabel(String label) {
  return find.descendant(
    of: find.byType(FloatingBottomNavBar),
    matching: find.text(label),
  );
}

class _ShellHarness {
  const _ShellHarness({required this.container, required this.router});

  final ProviderContainer container;
  final GoRouter router;
}
