import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab.dart';
import 'package:seekarr/features/activity/presentation/widgets/wanted_tab.dart';
import 'package:seekarr/features/discover/domain/models/jellyseerr_request.dart';
import 'package:seekarr/features/discover/presentation/discover_provider.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';

void main() {
  testWidgets('renders requests screen for discover', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestsProvider.overrideWith((ref) async => <JellyseerrRequest>[]),
        ],
        child: const MaterialApp(
          home: ActivityScreen(serviceType: ServiceType.discover),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Requests'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(ActivityTab), findsNothing);
    expect(find.byType(WantedTab), findsNothing);
    expect(find.text('No requests found'), findsOneWidget);
  });

  testWidgets('renders tabbed activity screen for movies', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          radarrServiceProvider.overrideWith(
            (ref) => FakeRadarrActivityService(),
          ),
        ],
        child: const MaterialApp(
          home: ActivityScreen(serviceType: ServiceType.movies),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Movies Activity'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Wanted'), findsOneWidget);
    expect(find.byType(ActivityTab), findsOneWidget);

    await tester.tap(find.text('Wanted'));
    await tester.pumpAndSettle();

    expect(find.byType(WantedTab), findsOneWidget);
  });
}

class FakeRadarrActivityService extends RadarrService {
  FakeRadarrActivityService()
    : super(ApiClient(baseUrl: 'https://radarr.example.com', apiKey: 'key'));

  @override
  Future<List<dynamic>> getQueue() async => [];

  @override
  Future<List<dynamic>> getHistory({int page = 1, int pageSize = 20}) async =>
      [];

  @override
  Future<List<dynamic>> getBlocklist() async => [];

  @override
  Future<List<dynamic>> getMissing({int page = 1, int pageSize = 20}) async =>
      [];

  @override
  Future<List<dynamic>> getCutoff({int page = 1, int pageSize = 20}) async =>
      [];
}
