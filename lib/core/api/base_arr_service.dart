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

/// Mixin providing shared activity methods for *arr services (Radarr, Sonarr, Lidarr).
///
/// This mixin eliminates ~80% code duplication by providing common implementations
/// for queue, history, blocklist, missing, and cutoff endpoints.
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
}
