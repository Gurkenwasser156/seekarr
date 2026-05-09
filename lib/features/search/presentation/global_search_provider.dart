import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: implementation_imports
import 'package:flutter_riverpod/legacy.dart';

import 'package:seekarr/core/models/media_preview.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/features/discover/data/seerr_service.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';
import 'package:seekarr/features/search/domain/global_search_result.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

final globalSearchQueryProvider = StateProvider<String>((ref) => '');

final globalSearchResultsProvider = FutureProvider.autoDispose((ref) async {
  final query = ref.watch(globalSearchQueryProvider).trim();
  final settings = ref.watch(currentSettingsProvider);
  if (query.isEmpty) return const <GlobalSearchServiceResults>[];

  return Future.wait([
    _loadSeerrResults(ref, query),
    _loadRadarrResults(ref, query, settings),
    _loadSonarrResults(ref, query, settings),
    _loadLidarrResults(ref, query, settings),
  ]);
});

Future<GlobalSearchServiceResults> _loadSeerrResults(
  Ref ref,
  String query,
) async {
  try {
    final service = ref.read(seerrServiceProvider);
    final items = await service.search(query);
    return GlobalSearchServiceResults(
      service: ServiceKey.seerr,
      results: items.map(_seerrResult).toList(growable: false),
    );
  } catch (error) {
    return GlobalSearchServiceResults(
      service: ServiceKey.seerr,
      results: const [],
      error: error,
    );
  }
}

Future<GlobalSearchServiceResults> _loadRadarrResults(
  Ref ref,
  String query,
  SettingsModel settings,
) async {
  try {
    final service = ref.read(radarrServiceProvider);
    final items = await service.lookupMovies(query);
    return GlobalSearchServiceResults(
      service: ServiceKey.radarr,
      results: items
          .map((item) => _radarrResult(item, settings))
          .toList(growable: false),
    );
  } catch (error) {
    return GlobalSearchServiceResults(
      service: ServiceKey.radarr,
      results: const [],
      error: error,
    );
  }
}

Future<GlobalSearchServiceResults> _loadSonarrResults(
  Ref ref,
  String query,
  SettingsModel settings,
) async {
  try {
    final service = ref.read(sonarrServiceProvider);
    final items = await service.lookupSeries(query);
    return GlobalSearchServiceResults(
      service: ServiceKey.sonarr,
      results: items
          .map((item) => _sonarrResult(item, settings))
          .toList(growable: false),
    );
  } catch (error) {
    return GlobalSearchServiceResults(
      service: ServiceKey.sonarr,
      results: const [],
      error: error,
    );
  }
}

Future<GlobalSearchServiceResults> _loadLidarrResults(
  Ref ref,
  String query,
  SettingsModel settings,
) async {
  try {
    final service = ref.read(lidarrServiceProvider);
    final items = await service.lookupArtists(query);
    return GlobalSearchServiceResults(
      service: ServiceKey.lidarr,
      results: items
          .map((item) => _lidarrResult(item, settings))
          .toList(growable: false),
    );
  } catch (error) {
    return GlobalSearchServiceResults(
      service: ServiceKey.lidarr,
      results: const [],
      error: error,
    );
  }
}

GlobalSearchResult _seerrResult(MediaPreview item) {
  final type = item.mediaType == 'tv' ? 'Series' : 'Movie';
  final year = item.year;
  return GlobalSearchResult(
    service: ServiceKey.seerr,
    id: item.id,
    title: item.title,
    subtitle: [type, year].where((part) => part.isNotEmpty).join(' · '),
    imageUrl: ImageUtils.buildTmdbPosterUrl(item.posterPath),
    imageHeaders: null,
    tags: [type, if (year.isNotEmpty) year],
    route:
        '/services/seerr/${item.mediaType == 'tv' ? 'tv' : 'movie'}/${item.id}',
  );
}

GlobalSearchResult _radarrResult(RadarrMovie item, SettingsModel settings) {
  final image = ImageUtils.extractPosterUrl(
    item.images,
    baseUrl: settings.radarrUrl,
    apiKey: settings.radarrApiKey,
  );
  return GlobalSearchResult(
    service: ServiceKey.radarr,
    id: item.id,
    title: item.title,
    subtitle: [
      if (item.year > 0) item.year.toString(),
      item.hasFile ? 'Available' : 'Missing',
    ].join(' · '),
    imageUrl: image.url,
    imageHeaders: image.headers,
    tags: ['Movie', item.hasFile ? 'Available' : 'Missing'],
    route: '/services/radarr/movie/${item.id}',
  );
}

GlobalSearchResult _sonarrResult(SonarrSeries item, SettingsModel settings) {
  final image = ImageUtils.extractPosterUrl(
    item.images,
    baseUrl: settings.sonarrUrl,
    apiKey: settings.sonarrApiKey,
  );
  return GlobalSearchResult(
    service: ServiceKey.sonarr,
    id: item.id,
    title: item.title,
    subtitle: [
      if (item.year > 0) item.year.toString(),
      item.status,
    ].join(' · '),
    imageUrl: image.url,
    imageHeaders: image.headers,
    tags: ['Series', item.status],
    route: '/services/sonarr/series/${item.id}',
  );
}

GlobalSearchResult _lidarrResult(LidarrArtist item, SettingsModel settings) {
  final image = ImageUtils.extractPosterUrl(
    item.images,
    baseUrl: settings.lidarrUrl,
    apiKey: settings.lidarrApiKey,
    coverTypes: const ['poster', 'fanart', 'banner'],
  );
  final albumLabel = item.albumCount == 1
      ? '1 album'
      : '${item.albumCount} albums';
  return GlobalSearchResult(
    service: ServiceKey.lidarr,
    id: item.id,
    title: item.artistName,
    subtitle: albumLabel,
    imageUrl: image.url,
    imageHeaders: image.headers,
    tags: ['Artist', item.hasFiles ? 'Available' : 'Missing'],
    route: '/services/lidarr/artist/${item.id}',
  );
}
