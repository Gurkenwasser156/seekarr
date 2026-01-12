import 'dart:isolate';
import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/core/api/base_arr_service.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sonarrServiceProvider = Provider<SonarrService>((ref) {
  final settings = ref.watch(settingsProvider);
  if (settings.sonarrUrl.isEmpty || settings.sonarrApiKey.isEmpty) {
    throw Exception('Sonarr not configured');
  }
  return SonarrService(
    ApiClient(baseUrl: settings.sonarrUrl, apiKey: settings.sonarrApiKey),
  );
});

/// Service for interacting with Sonarr API.
///
/// Provides series-specific operations plus shared activity operations
/// via [ArrActivityMixin].
class SonarrService with ArrActivityMixin {
  @override
  final ApiClient client;

  @override
  final ArrServiceConfig config = ArrServiceConfig.sonarr;

  SonarrService(this.client);

  /// Fetches all series from Sonarr.
  Future<List<SonarrSeries>> getSeries() async {
    try {
      final response = await client.get('/api/v3/series');
      final data = response.data as List<dynamic>;
      return await Isolate.run(
        () => data.map((e) => SonarrSeries.fromJson(e)).toList(),
      );
    } catch (e) {
      return [];
    }
  }

  /// Triggers an automatic search for the given series ID (entire series).
  Future<void> searchSeries(int seriesId) async {
    await client.post(
      '/api/v3/command',
      data: {'name': 'SeriesSearch', 'seriesId': seriesId},
    );
  }

  /// Triggers an automatic search for a specific season.
  Future<void> searchSeason(int seriesId, int seasonNumber) async {
    await client.post(
      '/api/v3/command',
      data: {
        'name': 'SeasonSearch',
        'seriesId': seriesId,
        'seasonNumber': seasonNumber,
      },
    );
  }

  /// Triggers an automatic search for specific episodes.
  Future<void> searchEpisodes(List<int> episodeIds) async {
    await client.post(
      '/api/v3/command',
      data: {'name': 'EpisodeSearch', 'episodeIds': episodeIds},
    );
  }

  /// Fetches all episodes for a series.
  Future<List<dynamic>> getEpisodes(int seriesId) async {
    final response = await client.get(
      '/api/v3/episode',
      queryParameters: {'seriesId': seriesId},
    );
    return response.data as List<dynamic>;
  }

  /// Fetches releases for interactive search.
  /// Note: Sonarr requires either episodeId or seriesId+seasonNumber for proper results.
  Future<List<dynamic>> getReleases({
    int? seriesId,
    int? seasonNumber,
    int? episodeId,
  }) async {
    final params = <String, dynamic>{};
    if (seriesId != null) params['seriesId'] = seriesId;
    if (seasonNumber != null) params['seasonNumber'] = seasonNumber;
    if (episodeId != null) params['episodeId'] = episodeId;

    final response = await client.get(
      '/api/v3/release',
      queryParameters: params,
    );
    return response.data as List<dynamic>;
  }

  /// Grabs a specific release for download.
  Future<void> grabRelease({
    required String guid,
    required int indexerId,
  }) async {
    await client.post(
      '/api/v3/release',
      data: {'guid': guid, 'indexerId': indexerId},
    );
  }

  /// Searches for series by term using the lookup API.
  Future<List<SonarrSeries>> lookupSeries(String term) async {
    if (term.isEmpty) return [];
    try {
      // URL-encode the term to handle spaces and special characters
      final encodedTerm = Uri.encodeComponent(term);
      final response = await client.get(
        '/api/v3/series/lookup',
        queryParameters: {'term': encodedTerm},
      );
      final data = response.data as List<dynamic>;
      return await Isolate.run(
        () => data.map((e) => SonarrSeries.fromJson(e)).toList(),
      );
    } catch (e) {
      return [];
    }
  }

  /// Finds a series in the library by its TVDB ID.
  /// Returns null if not found in the library.
  Future<SonarrSeries?> getSeriesByTvdbId(int tvdbId) async {
    try {
      final series = await getSeries();
      return series.where((s) => s.tvdbId == tvdbId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  /// Fetches all quality profiles.
  Future<List<Map<String, dynamic>>> getQualityProfiles() async {
    try {
      final response = await client.get('/api/v3/qualityprofile');
      final data = response.data as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Updates a series's quality profile.
  Future<void> updateSeriesProfile(int seriesId, int qualityProfileId) async {
    final response = await client.get('/api/v3/series/$seriesId');
    final series = response.data as Map<String, dynamic>;

    series['qualityProfileId'] = qualityProfileId;

    await client.put('/api/v3/series/$seriesId', data: series);
  }

  /// Deletes a series from Sonarr.
  Future<void> deleteSeries(
    int seriesId, {
    bool deleteFiles = false,
    bool addImportListExclusion = false,
  }) async {
    await client.delete(
      '/api/v3/series/$seriesId',
      queryParameters: {
        'deleteFiles': deleteFiles,
        'addImportListExclusion': addImportListExclusion,
      },
    );
  }
}
