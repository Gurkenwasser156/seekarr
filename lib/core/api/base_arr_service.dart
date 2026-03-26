import 'dart:isolate';

import 'package:seekarr/core/api/api_client.dart';

/// Configuration for *arr service activity endpoints.
class ArrServiceConfig {
  /// API version string (e.g., 'v3' for Radarr/Sonarr, 'v1' for Lidarr)
  final String apiVersion;

  /// Sort key for wanted endpoints (e.g., 'airDateUtc' for Radarr/Sonarr, 'releaseDate' for Lidarr)
  final String sortKey;

  const ArrServiceConfig({required this.apiVersion, required this.sortKey});

  static const radarr = ArrServiceConfig(
    apiVersion: 'v3',
    sortKey: 'airDateUtc',
  );
  static const sonarr = ArrServiceConfig(
    apiVersion: 'v3',
    sortKey: 'airDateUtc',
  );
  static const lidarr = ArrServiceConfig(
    apiVersion: 'v1',
    sortKey: 'releaseDate',
  );
}

/// Mixin providing shared activity endpoints and common service helpers for
/// *arr services (Radarr, Sonarr, Lidarr).
mixin ArrActivityMixin {
  /// The API client used for requests.
  ApiClient get client;

  /// The service configuration (API version, sort key).
  ArrServiceConfig get config;

  /// Fetches the download queue.
  Future<List<dynamic>> getQueue() async {
    final response = await client.get('/api/${config.apiVersion}/queue');
    return response.data['records'] as List<dynamic>;
  }

  /// Fetches recent history.
  Future<List<dynamic>> getHistory({int page = 1, int pageSize = 20}) async {
    final response = await client.get(
      '/api/${config.apiVersion}/history',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data['records'] as List<dynamic>;
  }

  /// Fetches the blocklist.
  Future<List<dynamic>> getBlocklist() async {
    final response = await client.get('/api/${config.apiVersion}/blocklist');
    return response.data['records'] as List<dynamic>;
  }

  /// Fetches missing items (wanted).
  Future<List<dynamic>> getMissing({int page = 1, int pageSize = 20}) async {
    final response = await client.get(
      '/api/${config.apiVersion}/wanted/missing',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'sortKey': config.sortKey,
        'sortDirection': 'descending',
        'includeSeries': true, // Include series data in response
      },
    );
    return response.data['records'] as List<dynamic>;
  }

  /// Fetches items with cutoff unmet.
  Future<List<dynamic>> getCutoff({int page = 1, int pageSize = 20}) async {
    try {
      final response = await client.get(
        '/api/${config.apiVersion}/wanted/cutoff',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          'sortKey': config.sortKey,
          'sortDirection': 'descending',
          'includeSeries': true, // Include series data in response
        },
      );
      return response.data['records'] as List<dynamic>;
    } catch (e) {
      // Cutoff endpoint may not be available on all *arr variants
      return [];
    }
  }

  /// Fetches all items from a list endpoint and maps them in an isolate.
  Future<List<T>> fetchAllItems<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await client.get('/api/${config.apiVersion}/$endpoint');
      final data = response.data as List<dynamic>;
      return await Isolate.run(
        () =>
            data.map((item) => fromJson(item as Map<String, dynamic>)).toList(),
      );
    } catch (_) {
      return [];
    }
  }

  /// Searches by term using a lookup endpoint and maps results in an isolate.
  Future<List<T>> lookupItems<T>(
    String endpoint,
    String term,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (term.isEmpty) {
      return [];
    }

    try {
      final encodedTerm = Uri.encodeComponent(term);
      final response = await client.get(
        '/api/${config.apiVersion}/$endpoint',
        queryParameters: {'term': encodedTerm},
      );
      final data = response.data as List<dynamic>;
      return await Isolate.run(
        () =>
            data.map((item) => fromJson(item as Map<String, dynamic>)).toList(),
      );
    } catch (_) {
      return [];
    }
  }

  /// Fetches all quality profiles.
  Future<List<Map<String, dynamic>>> fetchQualityProfiles() async {
    try {
      final response = await client.get(
        '/api/${config.apiVersion}/qualityprofile',
      );
      final data = response.data as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Updates an item's quality profile.
  Future<void> updateItemProfile(
    String resourcePath,
    int itemId,
    int qualityProfileId,
  ) async {
    final response = await client.get(
      '/api/${config.apiVersion}/$resourcePath/$itemId',
    );
    final item = response.data as Map<String, dynamic>;
    item['qualityProfileId'] = qualityProfileId;
    await client.put(
      '/api/${config.apiVersion}/$resourcePath/$itemId',
      data: item,
    );
  }

  /// Grabs a specific release for download.
  Future<void> grabReleaseByGuid({
    required String guid,
    required int indexerId,
  }) async {
    await client.post(
      '/api/${config.apiVersion}/release',
      data: {'guid': guid, 'indexerId': indexerId},
    );
  }
}
