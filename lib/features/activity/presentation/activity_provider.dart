import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/api/base_arr_service.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';

/// Resolves a [ServiceType] to the corresponding *arr service.
///
/// Discover uses Jellyseerr rather than an *arr service, so it is not
/// supported by this provider.
final resolvedArrServiceProvider =
    Provider.family<ArrActivityMixin, ServiceType>((ref, serviceType) {
      assert(
        serviceType.supportsArrActivity,
        'resolvedArrServiceProvider only supports movies, series, and music.',
      );

      switch (serviceType) {
        case ServiceType.movies:
          return ref.read(radarrServiceProvider);
        case ServiceType.series:
          return ref.read(sonarrServiceProvider);
        case ServiceType.music:
          return ref.read(lidarrServiceProvider);
        case ServiceType.discover:
          throw ArgumentError.value(
            serviceType,
            'serviceType',
            'ServiceType.discover does not have an *arr service',
          );
      }
    });

ArrActivityMixin resolveArrService(WidgetRef ref, ServiceType serviceType) {
  return ref.read(resolvedArrServiceProvider(serviceType));
}
