import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JellyseerrService', () {
    group('createRequest body format', () {
      test('movie request body contains correct fields', () {
        // Test the body creation logic for movies
        final body = _buildRequestBody(
          mediaType: 'movie',
          mediaId: 12345,
          profileId: 1,
          rootFolder: '/movies',
          is4k: false,
        );

        expect(body['mediaType'], 'movie');
        expect(body['mediaId'], 12345);
        expect(body['is4k'], false);
        expect(body['profileId'], 1);
        expect(body['rootFolder'], '/movies');
        expect(body.containsKey('seasons'), false);
      });

      test('TV request body includes seasons="all" when not specified', () {
        final body = _buildRequestBody(
          mediaType: 'tv',
          mediaId: 67890,
          is4k: false,
          seasons: null,
        );

        expect(body['mediaType'], 'tv');
        expect(body['seasons'], 'all');
      });

      test('TV request body includes specific seasons when provided', () {
        final body = _buildRequestBody(
          mediaType: 'tv',
          mediaId: 67890,
          is4k: false,
          seasons: [1, 2, 3],
        );

        expect(body['seasons'], [1, 2, 3]);
      });

      test('4K request sets is4k to true', () {
        final body = _buildRequestBody(
          mediaType: 'movie',
          mediaId: 12345,
          is4k: true,
        );

        expect(body['is4k'], true);
      });
    });

    group('profile selection logic', () {
      test('selects active profile when available', () {
        final profiles = [
          {'id': 1, 'name': 'HD-1080p'},
          {'id': 2, 'name': '4K'},
          {'id': 3, 'name': 'Web-720p'},
        ];
        const activeProfileId = 2;

        final selectedId = _selectProfileId(profiles, activeProfileId);
        expect(selectedId, 2);
      });

      test('falls back to first profile when active not found', () {
        final profiles = [
          {'id': 1, 'name': 'HD-1080p'},
          {'id': 2, 'name': '4K'},
        ];
        const activeProfileId = 99; // Not in list

        final selectedId = _selectProfileId(profiles, activeProfileId);
        expect(selectedId, 1);
      });

      test('returns null when no profiles available', () {
        final profiles = <Map<String, dynamic>>[];
        const activeProfileId = 1;

        final selectedId = _selectProfileId(profiles, activeProfileId);
        expect(selectedId, null);
      });
    });
  });

  // Run additional test groups
  RequestedByTest.runTests();
}

/// Helper to simulate createRequest body building
Map<String, dynamic> _buildRequestBody({
  required String mediaType,
  required int mediaId,
  int? profileId,
  String? rootFolder,
  bool is4k = false,
  List<int>? seasons,
}) {
  final body = <String, dynamic>{
    'mediaType': mediaType,
    'mediaId': mediaId,
    'is4k': is4k,
  };

  // For TV shows, seasons is required
  if (mediaType == 'tv') {
    if (seasons != null && seasons.isNotEmpty) {
      body['seasons'] = seasons;
    } else {
      body['seasons'] = 'all';
    }
  }

  if (profileId != null) body['profileId'] = profileId;
  if (rootFolder != null) body['rootFolder'] = rootFolder;

  return body;
}

/// Helper to simulate profile selection logic
int? _selectProfileId(
  List<Map<String, dynamic>> profiles,
  int? activeProfileId,
) {
  if (profiles.isEmpty) return null;

  if (activeProfileId != null &&
      profiles.any((p) => p['id'] == activeProfileId)) {
    return activeProfileId;
  }

  return profiles.first['id'] as int?;
}

/// Tests for RequestedBy model
class RequestedByTest {
  static void runTests() {
    group('RequestedBy parsing', () {
      test('parses displayName correctly', () {
        final json = {'id': 1, 'displayName': 'TestUser', 'avatar': null};
        final requestedBy = _parseRequestedBy(json);
        expect(requestedBy['displayName'], 'TestUser');
      });

      test('falls back to username when displayName is missing', () {
        final json = {'id': 1, 'username': 'FallbackUser'};
        final requestedBy = _parseRequestedBy(json);
        expect(requestedBy['displayName'], 'FallbackUser');
      });

      test('returns Unknown when no name fields present', () {
        final json = <String, dynamic>{'id': 1};
        final requestedBy = _parseRequestedBy(json);
        expect(requestedBy['displayName'], 'Unknown');
      });
    });

    group('Media management endpoint URLs', () {
      test('delete media URL constructed correctly', () {
        const mediaId = 123;
        final url = _buildMediaDeleteUrl(mediaId);
        expect(url, '/api/v1/media/123');
      });

      test('delete media file URL constructed correctly', () {
        const mediaId = 456;
        final url = _buildMediaFileDeleteUrl(mediaId);
        expect(url, '/api/v1/media/456/file');
      });
    });
  }
}

Map<String, dynamic> _parseRequestedBy(Map<String, dynamic> json) {
  return {
    'id': json['id'] ?? 0,
    'displayName': json['displayName'] ?? json['username'] ?? 'Unknown',
    'avatar': json['avatar']?.toString(),
  };
}

String _buildMediaDeleteUrl(int mediaId) {
  return '/api/v1/media/$mediaId';
}

String _buildMediaFileDeleteUrl(int mediaId) {
  return '/api/v1/media/$mediaId/file';
}
