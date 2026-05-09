import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/activity/presentation/activity_provider.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab.dart';
import 'package:seekarr/features/activity/presentation/widgets/wanted_tab.dart';
import 'package:seekarr/features/discover/data/seerr_service.dart';
import 'package:seekarr/features/discover/domain/models/seerr_request.dart';
import 'package:seekarr/features/discover/presentation/discover_provider.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

import '../../../test_helpers/fake_services.dart';

void main() {
  ProviderContainer createContainer({
    SeerrService? seerrService,
    RadarrService? radarrService,
    SonarrService? sonarrService,
    LidarrService? lidarrService,
    List<SeerrRequest>? requests,
  }) {
    final container = ProviderContainer(
      overrides: [
        if (seerrService != null)
          seerrServiceProvider.overrideWith((ref) => seerrService),
        if (requests != null)
          requestsProvider.overrideWith((ref) async => requests),
        if (radarrService != null)
          radarrServiceProvider.overrideWith((ref) => radarrService),
        if (sonarrService != null)
          sonarrServiceProvider.overrideWith((ref) => sonarrService),
        if (lidarrService != null)
          lidarrServiceProvider.overrideWith((ref) => lidarrService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('ServiceType.displayTitle returns the expected label per type', () {
    const expected = {
      ServiceType.movies: 'Movies',
      ServiceType.series: 'Series',
      ServiceType.music: 'Music',
      ServiceType.discover: 'Requests',
    };
    for (final entry in expected.entries) {
      expect(entry.key.displayTitle, entry.value, reason: '${entry.key}');
    }
  });

  test('ServiceType.supportsArrActivity is true only for *arr services', () {
    expect(ServiceType.movies.supportsArrActivity, isTrue);
    expect(ServiceType.series.supportsArrActivity, isTrue);
    expect(ServiceType.music.supportsArrActivity, isTrue);
    expect(ServiceType.discover.supportsArrActivity, isFalse);
  });

  group('resolveArrService', () {
    test('returns the Radarr/Sonarr/Lidarr service for its matching type', () {
      final radarr = FakeRadarrService();
      final sonarr = FakeSonarrService();
      final lidarr = FakeLidarrService();
      final container = createContainer(
        radarrService: radarr,
        sonarrService: sonarr,
        lidarrService: lidarr,
      );

      expect(
        identical(
          container.read(resolvedArrServiceProvider(ServiceType.movies)),
          radarr,
        ),
        isTrue,
      );
      expect(
        identical(
          container.read(resolvedArrServiceProvider(ServiceType.series)),
          sonarr,
        ),
        isTrue,
      );
      expect(
        identical(
          container.read(resolvedArrServiceProvider(ServiceType.music)),
          lidarr,
        ),
        isTrue,
      );
    });

    test('throws for discover', () {
      final container = createContainer();

      expect(
        () => container.read(resolvedArrServiceProvider(ServiceType.discover)),
        throwsA(
          predicate<Object>(
            (error) => error.toString().contains(
              'only supports movies, series, and music',
            ),
            'provider error for unsupported discover service type',
          ),
        ),
      );
    });
  });

  test('ActivityTab and WantedTab reject the discover service type', () {
    expect(
      () => ActivityTab(serviceType: ServiceType.discover),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => WantedTab(serviceType: ServiceType.discover),
      throwsA(isA<AssertionError>()),
    );
  });

  group('global activity providers', () {
    test('combines requests, queue, and history sorted newest first', () async {
      final container = createContainer(
        requests: const [
          SeerrRequest(
            id: 1,
            status: RequestStatus.approved,
            media: RequestMedia(title: 'Shogun'),
            createdAt: '2026-04-03T09:05:00Z',
            type: 'tv',
            requestedBy: RequestedBy(id: 1, displayName: 'sarah'),
          ),
        ],
        radarrService: _ActivityRadarrService(
          queue: const [
            {
              'title': 'Furiosa',
              'status': 'downloading',
              'estimatedCompletionTime': '2026-04-03T14:32:00Z',
              'size': 100,
              'sizeleft': 25,
            },
          ],
          history: const [
            {
              'sourceTitle': 'Dune.Part.Two.2024',
              'eventType': 'downloadImported',
              'date': '2026-04-02T11:18:00Z',
              'movie': {'title': 'Dune: Part Two'},
            },
          ],
        ),
      );

      final items = await container.read(globalActivityFeedProvider.future);

      expect(items.map((item) => item.title), [
        'Furiosa',
        'Shogun',
        'Dune.Part.Two.2024',
      ]);
      expect(items.first.kind, GlobalActivityKind.queue);
      expect(items.first.service, ServiceKey.radarr);
      expect(items.first.progress, 0.75);
      expect(items[1].kind, GlobalActivityKind.request);
      expect(items[1].service, ServiceKey.seerr);
      expect(items[2].kind, GlobalActivityKind.history);
    });

    test('keeps global queue available when one service fails', () async {
      final container = createContainer(
        radarrService: _ThrowingQueueRadarrService(),
        sonarrService: _ActivitySonarrService(
          queue: const [
            {'title': 'House of the Dragon S02E03', 'status': 'downloading'},
          ],
        ),
      );

      final items = await container.read(globalQueueItemsProvider.future);

      expect(items, hasLength(1));
      expect(items.single.service, ServiceKey.sonarr);
      expect(items.single.title, 'House of the Dragon S02E03');
    });

    test('wanted provider combines missing and cutoff items', () async {
      final container = createContainer(
        radarrService: _ActivityRadarrService(
          missing: const [
            {'title': 'Kingdom of the Planet of the Apes', 'year': 2024},
          ],
          cutoff: const [
            {'title': 'Inception', 'year': 2010},
          ],
        ),
      );

      final items = await container.read(globalWantedItemsProvider.future);

      expect(items.map((item) => item.kind), [
        GlobalActivityKind.missing,
        GlobalActivityKind.cutoff,
      ]);
      expect(items.map((item) => item.title), [
        'Kingdom of the Planet of the Apes',
        'Inception',
      ]);
    });
  });
}

class _ActivityRadarrService extends FakeRadarrService {
  _ActivityRadarrService({
    this.queue = const [],
    this.history = const [],
    this.missing = const [],
    this.cutoff = const [],
  });

  final List<dynamic> queue;
  final List<dynamic> history;
  final List<dynamic> missing;
  final List<dynamic> cutoff;

  @override
  Future<List<dynamic>> getQueue() async => queue;

  @override
  Future<List<dynamic>> getHistory({int page = 1, int pageSize = 20}) async =>
      history;

  @override
  Future<List<dynamic>> getAllHistory() async => history;

  @override
  Future<List<dynamic>> getBlocklist() async => const [];

  @override
  Future<List<dynamic>> getMissing({int page = 1, int pageSize = 20}) async {
    expect(page, 1);
    expect(pageSize, 50);
    return missing;
  }

  @override
  Future<List<dynamic>> getAllMissing() async => missing;

  @override
  Future<List<dynamic>> getCutoff({int page = 1, int pageSize = 20}) async {
    expect(page, 1);
    expect(pageSize, 50);
    return cutoff;
  }

  @override
  Future<List<dynamic>> getAllCutoff() async => cutoff;
}

class _ActivitySonarrService extends FakeSonarrService {
  _ActivitySonarrService({this.queue = const []});

  final List<dynamic> queue;

  @override
  Future<List<dynamic>> getQueue() async => queue;
}

class _ThrowingQueueRadarrService extends FakeRadarrService {
  @override
  Future<List<dynamic>> getQueue() async => throw Exception('Radarr down');
}
