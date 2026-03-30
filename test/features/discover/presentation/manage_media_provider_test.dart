import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/features/discover/data/jellyseerr_service.dart';
import 'package:seekarr/features/discover/presentation/manage_media_provider.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

void main() {
  group('ManageMediaState', () {
    test('default state has correct defaults', () {
      const state = ManageMediaState();

      expect(state.requests, isEmpty);
      expect(state.isLoading, isTrue);
      expect(state.isDeleting, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const state = ManageMediaState(
        requests: [],
        isLoading: false,
        isDeleting: true,
        error: 'boom',
      );

      final updated = state.copyWith(isLoading: true);

      expect(updated.requests, same(state.requests));
      expect(updated.isLoading, isTrue);
      expect(updated.isDeleting, isTrue);
      expect(updated.error, 'boom');
    });

    test('copyWith clearError removes error', () {
      const state = ManageMediaState(error: 'boom');

      final updated = state.copyWith(clearError: true);

      expect(updated.error, isNull);
    });
  });

  group('manageMediaProvider', () {
    ProviderContainer createContainer({
      required ManageMediaArgs args,
      FakeJellyseerrService? service,
      SettingsModel? settings,
    }) {
      final container = ProviderContainer(
        overrides: [
          if (settings != null)
            currentSettingsProvider.overrideWith((ref) => settings),
          if (service != null)
            jellyseerrServiceProvider.overrideWith((ref) => service),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => container.invalidate(manageMediaProvider(args)));
      return container;
    }

    test('parses valid requests from mediaInfo', () {
      final args = _buildArgs(
        mediaInfo: {
          'id': 101,
          'externalServiceId': 202,
          'requests': [_validRequestJson(id: 7)],
        },
      );
      final container = createContainer(args: args);

      final state = container.read(manageMediaProvider(args));

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.requests, hasLength(1));
      expect(state.requests.single.id, 7);
      expect(state.requests.single.requestedBy?.displayName, 'Matt');
    });

    test('handles empty requests list', () {
      final args = _buildArgs(mediaInfo: {'requests': const []});
      final container = createContainer(args: args);

      final state = container.read(manageMediaProvider(args));

      expect(state.requests, isEmpty);
      expect(state.error, isNull);
    });

    test('filters malformed request entries', () {
      final args = _buildArgs(
        mediaInfo: {
          'requests': [_validRequestJson(id: 3), 'bad entry', 42],
        },
      );
      final container = createContainer(args: args);

      final state = container.read(manageMediaProvider(args));

      expect(state.requests, hasLength(1));
      expect(state.requests.single.id, 3);
    });

    test('handles missing requests key', () {
      final args = _buildArgs(mediaInfo: {'id': 10});
      final container = createContainer(args: args);

      final state = container.read(manageMediaProvider(args));

      expect(state.requests, isEmpty);
      expect(state.error, isNull);
    });

    test('exposes media ids through notifier getters', () {
      final args = _buildArgs(
        mediaInfo: {'id': 10, 'externalServiceId': 20, 'requests': const []},
      );
      final container = createContainer(args: args);
      final notifier = container.read(manageMediaProvider(args).notifier);

      expect(notifier.jellyseerrMediaId, 10);
      expect(notifier.externalServiceId, 20);
      expect(notifier.hasExternalService, isTrue);
    });

    test('returns null ids when missing', () {
      final args = _buildArgs(mediaInfo: {'requests': const []});
      final container = createContainer(args: args);
      final notifier = container.read(manageMediaProvider(args).notifier);

      expect(notifier.jellyseerrMediaId, isNull);
      expect(notifier.externalServiceId, isNull);
      expect(notifier.hasExternalService, isFalse);
    });

    test(
      'isServiceConfigured returns true when radarr is configured for movie type',
      () {
        final args = _buildArgs(
          mediaInfo: {'externalServiceId': 42, 'requests': const []},
        );
        final container = createContainer(
          args: args,
          settings: const SettingsModel(
            radarrUrl: 'https://radarr.example.com',
            radarrApiKey: 'key',
          ),
        );
        final notifier = container.read(manageMediaProvider(args).notifier);

        expect(notifier.isServiceConfigured, isTrue);
      },
    );

    test(
      'isServiceConfigured returns false when radarr is not configured for movie type',
      () {
        final args = _buildArgs(
          mediaInfo: {'externalServiceId': 42, 'requests': const []},
        );
        final container = createContainer(
          args: args,
          settings: const SettingsModel(),
        );
        final notifier = container.read(manageMediaProvider(args).notifier);

        expect(notifier.isServiceConfigured, isFalse);
      },
    );

    test(
      'isServiceConfigured returns true when sonarr is configured for tv type',
      () {
        final args = _buildArgs(
          mediaInfo: {'externalServiceId': 42, 'requests': const []},
          mediaType: 'tv',
          tvdbId: 555,
        );
        final container = createContainer(
          args: args,
          settings: const SettingsModel(
            sonarrUrl: 'https://sonarr.example.com',
            sonarrApiKey: 'key',
          ),
        );
        final notifier = container.read(manageMediaProvider(args).notifier);

        expect(notifier.isServiceConfigured, isTrue);
      },
    );

    test(
      'isServiceConfigured returns false when sonarr is not configured for tv type',
      () {
        final args = _buildArgs(
          mediaInfo: {'externalServiceId': 42, 'requests': const []},
          mediaType: 'tv',
          tvdbId: 555,
        );
        final container = createContainer(
          args: args,
          settings: const SettingsModel(),
        );
        final notifier = container.read(manageMediaProvider(args).notifier);

        expect(notifier.isServiceConfigured, isFalse);
      },
    );

    test('showMediaSection returns true only when both signals are true', () {
      final args = _buildArgs(
        mediaInfo: {'externalServiceId': 42, 'requests': const []},
      );
      final container = createContainer(
        args: args,
        settings: const SettingsModel(
          radarrUrl: 'https://radarr.example.com',
          radarrApiKey: 'key',
        ),
      );
      final notifier = container.read(manageMediaProvider(args).notifier);

      expect(notifier.showMediaSection, isTrue);
    });

    test(
      'showMediaSection returns false when externalServiceId is null despite configured service',
      () {
        final args = _buildArgs(mediaInfo: {'requests': const []});
        final container = createContainer(
          args: args,
          settings: const SettingsModel(
            radarrUrl: 'https://radarr.example.com',
            radarrApiKey: 'key',
          ),
        );
        final notifier = container.read(manageMediaProvider(args).notifier);

        expect(notifier.showMediaSection, isFalse);
      },
    );

    test(
      'showMediaSection returns false when service is not configured despite having externalServiceId',
      () {
        final args = _buildArgs(
          mediaInfo: {'externalServiceId': 42, 'requests': const []},
        );
        final container = createContainer(
          args: args,
          settings: const SettingsModel(),
        );
        final notifier = container.read(manageMediaProvider(args).notifier);

        expect(notifier.showMediaSection, isFalse);
      },
    );

    test('deleteRequest removes request from state', () async {
      final service = FakeJellyseerrService();
      final args = _buildArgs(
        mediaInfo: {
          'id': 11,
          'requests': [_validRequestJson(id: 1), _validRequestJson(id: 2)],
        },
      );
      final container = createContainer(args: args, service: service);
      final notifier = container.read(manageMediaProvider(args).notifier);

      final error = await notifier.deleteRequest(1);
      final state = container.read(manageMediaProvider(args));

      expect(error, isNull);
      expect(service.deletedRequestIds, [1]);
      expect(state.requests.map((request) => request.id), [2]);
    });

    test('deleteRequest returns error when service throws', () async {
      final service = FakeJellyseerrService(throwOnDeleteRequest: true);
      final args = _buildArgs(
        mediaInfo: {
          'id': 11,
          'requests': [_validRequestJson(id: 1)],
        },
      );
      final container = createContainer(args: args, service: service);
      final notifier = container.read(manageMediaProvider(args).notifier);

      final error = await notifier.deleteRequest(1);

      expect(error, contains('Failed to delete request'));
      expect(container.read(manageMediaProvider(args)).requests, hasLength(1));
    });

    test('removeFromService returns no media id when missing', () async {
      final args = _buildArgs(mediaInfo: {'requests': const []});
      final container = createContainer(args: args);
      final notifier = container.read(manageMediaProvider(args).notifier);

      final error = await notifier.removeFromService();

      expect(error, 'No media ID');
    });

    test('removeFromService calls deleteMediaFile and resets state', () async {
      final service = FakeJellyseerrService();
      final args = _buildArgs(mediaInfo: {'id': 44, 'requests': const []});
      final container = createContainer(args: args, service: service);
      final notifier = container.read(manageMediaProvider(args).notifier);

      final error = await notifier.removeFromService();
      final state = container.read(manageMediaProvider(args));

      expect(error, isNull);
      expect(service.deletedMediaFileIds, [44]);
      expect(state.isDeleting, isFalse);
    });

    test('removeFromService returns error when service throws', () async {
      final service = FakeJellyseerrService(throwOnDeleteMediaFile: true);
      final args = _buildArgs(mediaInfo: {'id': 44, 'requests': const []});
      final container = createContainer(args: args, service: service);
      final notifier = container.read(manageMediaProvider(args).notifier);

      final error = await notifier.removeFromService();
      final state = container.read(manageMediaProvider(args));

      expect(error, contains('Failed to remove'));
      expect(state.isDeleting, isFalse);
      expect(service.deletedMediaFileIds, isEmpty);
    });

    test('clearAllData calls deleteMedia and resets state', () async {
      final service = FakeJellyseerrService();
      final args = _buildArgs(mediaInfo: {'id': 55, 'requests': const []});
      final container = createContainer(args: args, service: service);
      final notifier = container.read(manageMediaProvider(args).notifier);

      final error = await notifier.clearAllData();
      final state = container.read(manageMediaProvider(args));

      expect(error, isNull);
      expect(service.deletedMediaIds, [55]);
      expect(state.isDeleting, isFalse);
    });

    test('clearAllData returns error when service throws', () async {
      final service = FakeJellyseerrService(throwOnDeleteMedia: true);
      final args = _buildArgs(mediaInfo: {'id': 55, 'requests': const []});
      final container = createContainer(args: args, service: service);
      final notifier = container.read(manageMediaProvider(args).notifier);

      final error = await notifier.clearAllData();
      final state = container.read(manageMediaProvider(args));

      expect(error, contains('Failed to clear data'));
      expect(state.isDeleting, isFalse);
      expect(service.deletedMediaIds, isEmpty);
    });
  });
}

ManageMediaArgs _buildArgs({
  required Map<String, dynamic> mediaInfo,
  String mediaType = 'movie',
  int? tvdbId,
}) {
  return (
    mediaInfo: mediaInfo,
    mediaType: mediaType,
    tmdbId: 123,
    tvdbId: tvdbId,
  );
}

Map<String, dynamic> _validRequestJson({required int id}) {
  return {
    'id': id,
    'status': 2,
    'createdAt': '2024-01-02T00:00:00.000Z',
    'type': 'movie',
    'is4k': false,
    'canRemove': true,
    'requestedBy': {'id': 1, 'displayName': 'Matt'},
    'media': {
      'id': 101,
      'tmdbId': 123,
      'status': 5,
      'mediaType': 'movie',
      'title': 'Movie',
    },
  };
}

class FakeJellyseerrService extends JellyseerrService {
  final bool throwOnDeleteRequest;
  final bool throwOnDeleteMediaFile;
  final bool throwOnDeleteMedia;

  final List<int> deletedRequestIds = <int>[];
  final List<int> deletedMediaFileIds = <int>[];
  final List<int> deletedMediaIds = <int>[];

  FakeJellyseerrService({
    this.throwOnDeleteRequest = false,
    this.throwOnDeleteMediaFile = false,
    this.throwOnDeleteMedia = false,
  }) : super(ApiClient(baseUrl: 'https://jellyseerr.example.com', apiKey: 'k'));

  @override
  Future<void> deleteRequest(int requestId) async {
    if (throwOnDeleteRequest) {
      throw Exception('delete request failed');
    }

    deletedRequestIds.add(requestId);
  }

  @override
  Future<void> deleteMediaFile(int mediaId) async {
    if (throwOnDeleteMediaFile) {
      throw Exception('delete media file failed');
    }

    deletedMediaFileIds.add(mediaId);
  }

  @override
  Future<void> deleteMedia(int mediaId) async {
    if (throwOnDeleteMedia) {
      throw Exception('delete media failed');
    }

    deletedMediaIds.add(mediaId);
  }
}
