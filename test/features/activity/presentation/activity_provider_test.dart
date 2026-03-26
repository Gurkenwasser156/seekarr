import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/features/activity/presentation/activity_provider.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab.dart';
import 'package:seekarr/features/activity/presentation/widgets/wanted_tab.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';

void main() {
  ProviderContainer createContainer({
    RadarrService? radarrService,
    SonarrService? sonarrService,
    LidarrService? lidarrService,
  }) {
    final container = ProviderContainer(
      overrides: [
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

  group('ServiceType.displayTitle', () {
    test('returns Movies for movies', () {
      expect(ServiceType.movies.displayTitle, 'Movies');
    });

    test('returns Series for series', () {
      expect(ServiceType.series.displayTitle, 'Series');
    });

    test('returns Music for music', () {
      expect(ServiceType.music.displayTitle, 'Music');
    });

    test('returns Requests for discover', () {
      expect(ServiceType.discover.displayTitle, 'Requests');
    });
  });

  group('ServiceType.supportsArrActivity', () {
    test('returns true for *arr-backed service types', () {
      expect(ServiceType.movies.supportsArrActivity, isTrue);
      expect(ServiceType.series.supportsArrActivity, isTrue);
      expect(ServiceType.music.supportsArrActivity, isTrue);
    });

    test('returns false for discover', () {
      expect(ServiceType.discover.supportsArrActivity, isFalse);
    });
  });

  group('ServiceType enum', () {
    test('has exactly four values', () {
      expect(ServiceType.values.length, 4);
    });
  });

  group('resolveArrService', () {
    test('returns Radarr service for movies', () {
      final service = FakeRadarrActivityService();
      final container = createContainer(radarrService: service);

      final resolved = container.read(
        resolvedArrServiceProvider(ServiceType.movies),
      );

      expect(identical(resolved, service), isTrue);
    });

    test('returns Sonarr service for series', () {
      final service = FakeSonarrActivityService();
      final container = createContainer(sonarrService: service);

      final resolved = container.read(
        resolvedArrServiceProvider(ServiceType.series),
      );

      expect(identical(resolved, service), isTrue);
    });

    test('returns Lidarr service for music', () {
      final service = FakeLidarrActivityService();
      final container = createContainer(lidarrService: service);

      final resolved = container.read(
        resolvedArrServiceProvider(ServiceType.music),
      );

      expect(identical(resolved, service), isTrue);
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

  group('activity tabs', () {
    test('ActivityTab rejects discover service type', () {
      expect(
        () => ActivityTab(serviceType: ServiceType.discover),
        throwsA(isA<AssertionError>()),
      );
    });

    test('WantedTab rejects discover service type', () {
      expect(
        () => WantedTab(serviceType: ServiceType.discover),
        throwsA(isA<AssertionError>()),
      );
    });
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

class FakeSonarrActivityService extends SonarrService {
  FakeSonarrActivityService()
    : super(ApiClient(baseUrl: 'https://sonarr.example.com', apiKey: 'key'));

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

class FakeLidarrActivityService extends LidarrService {
  FakeLidarrActivityService()
    : super(ApiClient(baseUrl: 'https://lidarr.example.com', apiKey: 'key'));

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
