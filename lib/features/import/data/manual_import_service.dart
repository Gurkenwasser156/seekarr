import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/core/utils/dynamic_map_utils.dart';
import 'package:seekarr/features/import/domain/manual_import_models.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

final manualImportServiceProvider =
    Provider.family<ManualImportService, ServiceKey>((ref, service) {
      if (service == ServiceKey.seerr) {
        throw Exception('Seerr does not support manual import');
      }

      final settings = ref.watch(currentSettingsProvider);
      final baseUrl = settings.urlFor(service);
      final apiKey = settings.apiKeyFor(service);
      if (baseUrl.isEmpty || apiKey.isEmpty) {
        throw Exception('${service.title} not configured');
      }

      return ManualImportService(
        client: ApiClient(baseUrl: baseUrl, apiKey: apiKey),
        service: service,
      );
    });

class ManualImportService {
  final ApiClient client;
  final ServiceKey service;

  const ManualImportService({required this.client, required this.service});

  String get _prefix => '/api/${service.apiVersion}';

  Future<List<ManualImportRootFolder>> getRootFolders() async {
    final response = await client.get('$_prefix/rootfolder');
    return _listData(response.data)
        .map(ManualImportRootFolder.fromJson)
        .where((folder) => folder.path.isNotEmpty)
        .toList(growable: false);
  }

  Future<ManualImportFileSystemResult> getFileSystem(String path) async {
    final response = await client.get(
      '$_prefix/filesystem',
      queryParameters: {
        'path': path,
        'includeFiles': false,
        'allowFoldersWithoutTrailingSlashes': true,
      },
    );
    return ManualImportFileSystemResult.fromJson(stringKeyMap(response.data));
  }

  Future<List<ManualImportItem>> getManualImportItems({
    required String folder,
  }) async {
    final response = await client.get(
      '$_prefix/manualimport',
      queryParameters: {
        'folder': folder,
        'filterExistingFiles': true,
        if (service == ServiceKey.lidarr) 'replaceExistingFiles': false,
      },
    );
    return _listData(
      response.data,
    ).map(ManualImportItem.fromJson).toList(growable: false);
  }

  Future<List<ManualImportLookupResult>> lookup(String term) async {
    final normalized = term.trim();
    if (normalized.isEmpty) return const [];

    final response = await client.get(
      '$_prefix/${_lookupEndpoint()}',
      queryParameters: {'term': normalized},
    );
    return _listData(response.data)
        .map((item) => ManualImportLookupResult.fromJson(service, item))
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<ManualImportLookupResult>> getLibraryMatches() async {
    final response = await client.get('$_prefix/${_libraryEndpoint()}');
    return _listData(response.data)
        .map((item) => ManualImportLookupResult.fromJson(service, item))
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<ManualImportItem> reprocessItem({
    required ManualImportItem item,
    required ManualImportFixAssignment assignment,
  }) async {
    final response = await client.post(
      '$_prefix/manualimport',
      data: [item.toReprocessJson(service, assignment: assignment)],
    );
    final items = _listData(
      response.data,
    ).map(ManualImportItem.fromJson).toList(growable: false);
    return items.isEmpty ? item : items.first;
  }

  Future<List<ManualImportEpisode>> getEpisodes({
    required int seriesId,
    int? seasonNumber,
  }) async {
    final response = await client.get(
      '$_prefix/episode',
      queryParameters: {
        'seriesId': seriesId,
        if (seasonNumber != null) 'seasonNumber': seasonNumber,
      },
    );
    return _listData(response.data)
        .map(ManualImportEpisode.fromJson)
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<ManualImportAlbum>> getAlbums(int artistId) async {
    final response = await client.get(
      '$_prefix/album',
      queryParameters: {'artistId': artistId},
    );
    return _listData(response.data)
        .map(ManualImportAlbum.fromJson)
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<ManualImportTrack>> getTracks({required int albumId}) async {
    final response = await client.get(
      '$_prefix/track',
      queryParameters: {'albumId': albumId},
    );
    return _listData(response.data)
        .map(ManualImportTrack.fromJson)
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<ManualImportQualityOption>> getQualityOptions() async {
    final response = await client.get('$_prefix/qualitydefinition');
    return _listData(response.data)
        .map(ManualImportQualityOption.fromJson)
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<ManualImportLanguageOption>> getLanguageOptions() async {
    final response = await client.get('$_prefix/language');
    return _listData(response.data)
        .map(ManualImportLanguageOption.fromJson)
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<ManualImportCommandStatus> startManualImport(
    List<ManualImportItem> files, {
    required ManualImportMode importMode,
  }) async {
    final response = await client.post(
      '$_prefix/command',
      data: {
        'name': 'ManualImport',
        'importMode': importMode.apiValue,
        if (service == ServiceKey.lidarr) 'replaceExistingFiles': false,
        'files': files
            .map((item) => item.toCommandFileJson(service))
            .toList(growable: false),
      },
    );
    return ManualImportCommandStatus.fromJson(stringKeyMap(response.data));
  }

  Future<ManualImportCommandStatus> getCommand(int commandId) async {
    final response = await client.get('$_prefix/command/$commandId');
    return ManualImportCommandStatus.fromJson(stringKeyMap(response.data));
  }

  String _lookupEndpoint() {
    return switch (service) {
      ServiceKey.radarr => 'movie/lookup',
      ServiceKey.sonarr => 'series/lookup',
      ServiceKey.lidarr => 'artist/lookup',
      ServiceKey.seerr => throw ArgumentError('Seerr does not support lookup'),
    };
  }

  String _libraryEndpoint() {
    return switch (service) {
      ServiceKey.radarr => 'movie',
      ServiceKey.sonarr => 'series',
      ServiceKey.lidarr => 'artist',
      ServiceKey.seerr => throw ArgumentError('Seerr does not support lookup'),
    };
  }
}

List<Map<String, dynamic>> _listData(dynamic data) {
  final list = data is List ? data : const [];
  return list
      .map(mapOrNull)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}
