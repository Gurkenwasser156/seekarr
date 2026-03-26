import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

void main() {
  group('SettingsModel.urlFor', () {
    const settings = SettingsModel(
      jellyseerrUrl: 'https://jelly.example.com',
      radarrUrl: 'https://radarr.example.com',
      sonarrUrl: 'https://sonarr.example.com',
      lidarrUrl: 'https://lidarr.example.com',
    );

    test('returns correct URL for each ServiceKey', () {
      expect(
        settings.urlFor(ServiceKey.jellyseerr),
        'https://jelly.example.com',
      );
      expect(settings.urlFor(ServiceKey.radarr), 'https://radarr.example.com');
      expect(settings.urlFor(ServiceKey.sonarr), 'https://sonarr.example.com');
      expect(settings.urlFor(ServiceKey.lidarr), 'https://lidarr.example.com');
    });
  });

  group('SettingsModel.apiKeyFor', () {
    const settings = SettingsModel(
      jellyseerrApiKey: 'jkey',
      radarrApiKey: 'rkey',
      sonarrApiKey: 'skey',
      lidarrApiKey: 'lkey',
    );

    test('returns correct API key for each ServiceKey', () {
      expect(settings.apiKeyFor(ServiceKey.jellyseerr), 'jkey');
      expect(settings.apiKeyFor(ServiceKey.radarr), 'rkey');
      expect(settings.apiKeyFor(ServiceKey.sonarr), 'skey');
      expect(settings.apiKeyFor(ServiceKey.lidarr), 'lkey');
    });
  });

  group('SettingsModel.copyWithService', () {
    const base = SettingsModel();

    test('updates only the targeted service URL and API key', () {
      final updated = base.copyWithService(
        ServiceKey.radarr,
        url: 'https://new.radarr',
        apiKey: 'new-key',
      );

      expect(updated.radarrUrl, 'https://new.radarr');
      expect(updated.radarrApiKey, 'new-key');
      expect(updated.jellyseerrUrl, '');
      expect(updated.sonarrUrl, '');
      expect(updated.lidarrUrl, '');
    });

    test('partial update only changes provided fields', () {
      final updated = base.copyWithService(
        ServiceKey.sonarr,
        url: 'https://sonarr.local',
      );

      expect(updated.sonarrUrl, 'https://sonarr.local');
      expect(updated.sonarrApiKey, '');
    });

    test('works for all four ServiceKey values', () {
      for (final key in ServiceKey.values) {
        final updated = base.copyWithService(key, url: 'https://test');
        expect(updated.urlFor(key), 'https://test');
      }
    });
  });

  group('ServiceKey.routeParam', () {
    test('matches enum name for all values', () {
      for (final key in ServiceKey.values) {
        expect(key.routeParam, key.name);
      }
    });
  });
}
