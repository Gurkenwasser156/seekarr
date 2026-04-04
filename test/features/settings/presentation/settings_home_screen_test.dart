import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/widgets/app_card.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';
import 'package:seekarr/features/settings/presentation/settings_home_screen.dart';

void main() {
  group('SettingsHomeScreen', () {
    testWidgets('renders the main settings sections', (tester) async {
      await _pumpSettingsHome(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('formats the selected region label', (tester) async {
      await _pumpSettingsHome(
        tester,
        settings: const SettingsModel(region: 'gb'),
      );

      expect(find.text('United Kingdom (GB)'), findsOneWidget);
    });

    testWidgets('shows Not configured for empty service settings', (
      tester,
    ) async {
      await _pumpSettingsHome(tester);

      expect(find.text('Jellyseerr'), findsOneWidget);
      expect(find.text('Radarr'), findsOneWidget);
      expect(find.text('Sonarr'), findsOneWidget);
      expect(find.text('Lidarr'), findsOneWidget);
      expect(find.text('Not configured'), findsNWidgets(4));
    });

    testWidgets('shows the extracted host for configured services', (
      tester,
    ) async {
      await _pumpSettingsHome(
        tester,
        settings: const SettingsModel(radarrUrl: 'https://radarr.local:7878'),
      );

      expect(find.text('radarr.local'), findsOneWidget);
    });

    testWidgets('tapping Region navigates to the region screen', (
      tester,
    ) async {
      await _pumpSettingsHome(tester);

      await tester.tap(find.text('Region'));
      await tester.pumpAndSettle();

      expect(find.text('RegionPage'), findsOneWidget);
    });

    testWidgets('tapping a service card navigates to its route', (
      tester,
    ) async {
      await _pumpSettingsHome(tester);

      await tester.tap(find.text('Radarr'));
      await tester.pumpAndSettle();

      expect(find.text('ServicePage:radarr'), findsOneWidget);
    });

    testWidgets('Share App shows the coming soon snackbar', (tester) async {
      await _pumpSettingsHome(tester);

      await tester.scrollUntilVisible(find.text('Share App'), 300);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share App'));
      await tester.pumpAndSettle();

      expect(find.text('Coming soon!'), findsOneWidget);
    });

    testWidgets('renders tappable settings cards', (tester) async {
      await _pumpSettingsHome(tester);

      expect(find.byType(SettingsCard), findsAtLeastNWidgets(6));

      await tester.scrollUntilVisible(find.text('Send Feedback'), 300);
      await tester.pumpAndSettle();

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Send Feedback'), findsOneWidget);
    });
  });
}

Future<void> _pumpSettingsHome(
  WidgetTester tester, {
  SettingsModel settings = const SettingsModel(),
}) async {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsHomeScreen(),
        routes: [
          GoRoute(
            path: 'region',
            builder: (_, __) => const Scaffold(body: Text('RegionPage')),
          ),
          GoRoute(
            path: 'service/:service',
            builder: (context, state) {
              final service = state.pathParameters['service'] ?? 'unknown';
              return Scaffold(body: Text('ServicePage:$service'));
            },
          ),
        ],
      ),
    ],
  );

  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [currentSettingsProvider.overrideWith((ref) => settings)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}
