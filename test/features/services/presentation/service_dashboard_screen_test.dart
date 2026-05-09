import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/features/services/presentation/service_dashboard_screen.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

void main() {
  testWidgets('renders service title and switches services from picker', (
    tester,
  ) async {
    final router = _buildRouter('/services/radarr');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('service-dashboard-title-radarr')),
      findsOneWidget,
    );
    expect(find.text('Radarr body'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('service-dashboard-switcher')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('service-dashboard-picker')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('service-dashboard-selected-radarr')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('service-dashboard-option-sonarr')),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/services/sonarr');
    expect(
      find.byKey(const ValueKey('service-dashboard-title-sonarr')),
      findsOneWidget,
    );
    expect(find.text('Sonarr body'), findsOneWidget);
  });

  testWidgets('back and activity actions navigate to parent routes', (
    tester,
  ) async {
    final router = _buildRouter('/services/lidarr');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Activity'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/activity');
    expect(find.text('Activity page'), findsOneWidget);

    router.go('/services/lidarr');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back to Services'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/services');
    expect(find.text('Services home'), findsOneWidget);
  });
}

GoRouter _buildRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/services',
        builder: (context, state) =>
            const Scaffold(body: Text('Services home')),
        routes: [
          for (final service in ServiceKey.values)
            GoRoute(
              path: service.routeParam,
              builder: (context, state) => ServiceDashboardScreen(
                service: service,
                child: Scaffold(body: Text('${service.title} body')),
              ),
            ),
        ],
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) =>
            const Scaffold(body: Text('Activity page')),
      ),
    ],
  );
}
