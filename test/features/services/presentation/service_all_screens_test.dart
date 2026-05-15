import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seekarr/core/widgets/content_card.dart';

import 'package:seekarr/features/discover/domain/models/seerr_request.dart';
import 'package:seekarr/features/services/presentation/service_all_screens.dart';
import 'package:seekarr/features/services/presentation/services_provider.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

import '../../../test_helpers/model_builders.dart';

void main() {
  testWidgets('all requests renders filter chips and compact request rows', (
    tester,
  ) async {
    await _pumpAllRequests(tester);
    await _pumpAsyncContent(tester);

    expect(find.text('All Requests'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Declined'), findsOneWidget);
    expect(find.text('A Quiet Place'), findsOneWidget);
    expect(find.text('sarah'), findsOneWidget);
    expect(find.text('Movie'), findsOneWidget);
    expect(find.text('AVAILABLE'), findsOneWidget);
    expect(find.text('PARTIALLY AVAILABLE'), findsOneWidget);
    expect(_contentCardWithImage('/quiet-place.jpg'), findsOneWidget);
  });

  testWidgets('all media renders service-specific grid content', (
    tester,
  ) async {
    await _pumpAllMedia(tester, ServiceKey.radarr);
    await _pumpAsyncContent(tester);

    expect(find.text('All Movies'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Missing'), findsOneWidget);
    expect(find.text('In Queue'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
  });

  testWidgets('all media routes taps to the correct detail route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/services/sonarr/media',
      routes: [
        GoRoute(
          path: '/services/sonarr/media',
          builder: (context, state) =>
              const ServiceAllMediaScreen(service: ServiceKey.sonarr),
        ),
        GoRoute(
          path: '/services/sonarr/series/:id',
          builder: (context, state) => Scaffold(
            body: Text('Series detail ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _providerOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await _pumpAsyncContent(tester);

    await tester.tap(find.text('The Boys'));
    await tester.pumpAndSettle();

    expect(
      router.state.uri.toString(),
      '/services/sonarr/series/20?heroTag=services_sonarr_media_20_0',
    );
    expect(find.text('Series detail 20'), findsOneWidget);
  });
}

Future<void> _pumpAllRequests(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _providerOverrides(),
      child: const MaterialApp(home: ServiceAllRequestsScreen()),
    ),
  );
}

Future<void> _pumpAllMedia(WidgetTester tester, ServiceKey service) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _providerOverrides(),
      child: MaterialApp(home: ServiceAllMediaScreen(service: service)),
    ),
  );
}

_providerOverrides() {
  return [
    currentSettingsProvider.overrideWith(
      (ref) => const SettingsModel(
        seerrUrl: 'http://seerr.local:5055',
        seerrApiKey: 'key',
        radarrUrl: 'http://radarr.local:7878',
        radarrApiKey: 'key',
        sonarrUrl: 'http://sonarr.local:8989',
        sonarrApiKey: 'key',
        lidarrUrl: 'http://lidarr.local:8686',
        lidarrApiKey: 'key',
      ),
    ),
    servicesRequestsProvider.overrideWith(
      (ref) async => const [
        SeerrRequest(
          id: 1,
          status: RequestStatus.pendingApproval,
          media: RequestMedia(
            title: 'A Quiet Place',
            tmdbId: 123,
            posterPath: '/quiet-place.jpg',
            status: MediaAvailability.available,
          ),
          createdAt: '2026-05-02T10:00:00Z',
          type: 'movie',
          requestedBy: RequestedBy(id: 1, displayName: 'sarah'),
        ),
        SeerrRequest(
          id: 2,
          status: RequestStatus.approved,
          media: RequestMedia(
            title: 'Shogun',
            status: MediaAvailability.partiallyAvailable,
          ),
          createdAt: '2026-05-01T10:00:00Z',
          type: 'tv',
          requestedBy: RequestedBy(id: 2, displayName: 'james'),
        ),
      ],
    ),
    servicesMoviesProvider.overrideWith(
      (ref) async => [
        buildMovie(id: 10, title: 'Dune', year: 2024),
        buildMovie(id: 11, title: 'Furiosa', year: 2023, hasFile: false),
      ],
    ),
    servicesSeriesProvider.overrideWith(
      (ref) async => [buildSeries(id: 20, title: 'The Boys', year: 2024)],
    ),
    servicesMusicProvider.overrideWith(
      (ref) async => [
        buildArtist(
          id: 30,
          artistName: 'Charli XCX',
          statistics: const {'trackFileCount': 12, 'trackCount': 12},
        ),
      ],
    ),
  ];
}

Future<void> _pumpAsyncContent(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Finder _contentCardWithImage(String imagePath) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is ContentCard && widget.imageUrl?.contains(imagePath) == true,
    skipOffstage: false,
  );
}
