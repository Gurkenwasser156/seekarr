import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/core/api/base_arr_service.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lidarrServiceProvider = Provider<LidarrService>((ref) {
  final settings = ref.watch(currentSettingsProvider);
  if (settings.lidarrUrl.isEmpty || settings.lidarrApiKey.isEmpty) {
    throw Exception('Lidarr not configured');
  }
  return LidarrService(
    ApiClient(baseUrl: settings.lidarrUrl, apiKey: settings.lidarrApiKey),
  );
});

/// Service for interacting with Lidarr API.
///
/// Provides artist-specific operations plus shared activity operations
/// via [ArrActivityMixin].
class LidarrService with ArrActivityMixin {
  @override
  final ApiClient client;

  @override
  final ArrServiceConfig config = ArrServiceConfig.lidarr;

  LidarrService(this.client);

  /// Fetches all artists from Lidarr.
  Future<List<LidarrArtist>> getArtists() async {
    try {
      final response = await client.get('/api/v1/artist');
      final data = response.data as List<dynamic>;
      return await Isolate.run(
        () => data.map((e) => LidarrArtist.fromJson(e)).toList(),
      );
    } catch (e) {
      return [];
    }
  }

  /// Fetches a single artist by ID.
  Future<Map<String, dynamic>?> getArtist(int artistId) async {
    try {
      final response = await client.get('/api/v1/artist/$artistId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Fetches all albums for an artist.
  Future<List<dynamic>> getAlbums(int artistId) async {
    final response = await client.get(
      '/api/v1/album',
      queryParameters: {'artistId': artistId},
    );
    return response.data as List<dynamic>;
  }

  /// Fetches all tracks for an album.
  Future<List<dynamic>> getTracks(int albumId) async {
    final response = await client.get(
      '/api/v1/track',
      queryParameters: {'albumId': albumId},
    );
    return response.data as List<dynamic>;
  }

  /// Triggers an automatic search for an artist.
  Future<void> searchArtist(int artistId) async {
    await client.post(
      '/api/v1/command',
      data: {'name': 'ArtistSearch', 'artistId': artistId},
    );
  }

  /// Triggers an automatic search for albums.
  Future<void> searchAlbums(List<int> albumIds) async {
    await client.post(
      '/api/v1/command',
      data: {'name': 'AlbumSearch', 'albumIds': albumIds},
    );
  }

  /// Fetches releases for interactive search.
  Future<List<dynamic>> getReleases({
    int? artistId,
    int? albumId,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{};
    if (artistId != null) params['artistId'] = artistId;
    if (albumId != null) params['albumId'] = albumId;

    final response = await client.get(
      '/api/v1/release',
      queryParameters: params,
      cancelToken: cancelToken,
    );
    return response.data as List<dynamic>;
  }

  /// Grabs a specific release for download.
  Future<void> grabRelease({
    required String guid,
    required int indexerId,
  }) async {
    await client.post(
      '/api/v1/release',
      data: {'guid': guid, 'indexerId': indexerId},
    );
  }

  /// Searches for artists by term using the lookup API.
  Future<List<LidarrArtist>> lookupArtists(String term) async {
    if (term.isEmpty) return [];
    try {
      // URL-encode the term to handle spaces and special characters
      final encodedTerm = Uri.encodeComponent(term);
      final response = await client.get(
        '/api/v1/artist/lookup',
        queryParameters: {'term': encodedTerm},
      );
      final data = response.data as List<dynamic>;
      return await Isolate.run(
        () => data.map((e) => LidarrArtist.fromJson(e)).toList(),
      );
    } catch (e) {
      return [];
    }
  }

  /// Fetches all quality profiles.
  Future<List<Map<String, dynamic>>> getQualityProfiles() async {
    try {
      final response = await client.get('/api/v1/qualityprofile');
      final data = response.data as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Updates an artist's quality profile.
  Future<void> updateArtistProfile(int artistId, int qualityProfileId) async {
    final response = await client.get('/api/v1/artist/$artistId');
    final artist = response.data as Map<String, dynamic>;

    artist['qualityProfileId'] = qualityProfileId;

    await client.put('/api/v1/artist/$artistId', data: artist);
  }

  /// Deletes an artist from Lidarr.
  Future<void> deleteArtist(
    int artistId, {
    bool deleteFiles = false,
    bool addImportListExclusion = false,
  }) async {
    await client.delete(
      '/api/v1/artist/$artistId',
      queryParameters: {
        'deleteFiles': deleteFiles,
        'addImportListExclusion': addImportListExclusion,
      },
    );
  }
}
