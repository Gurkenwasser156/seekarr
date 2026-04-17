import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/activity/presentation/activity_provider.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab.dart';
import 'package:seekarr/features/activity/presentation/widgets/wanted_tab.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';

import '../../../test_helpers/fake_services.dart';

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
}
