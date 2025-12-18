import 'package:shared_preferences/shared_preferences.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

class SettingsService {
  static const _kJellyseerrUrl = 'jellyseerr_url';
  static const _kJellyseerrApiKey = 'jellyseerr_api_key';
  static const _kRadarrUrl = 'radarr_url';
  static const _kRadarrApiKey = 'radarr_api_key';
  static const _kSonarrUrl = 'sonarr_url';
  static const _kSonarrApiKey = 'sonarr_api_key';
  static const _kLidarrUrl = 'lidarr_url';
  static const _kLidarrApiKey = 'lidarr_api_key';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  SettingsModel loadSettings() {
    return SettingsModel(
      jellyseerrUrl: _prefs.getString(_kJellyseerrUrl) ?? '',
      jellyseerrApiKey: _prefs.getString(_kJellyseerrApiKey) ?? '',
      radarrUrl: _prefs.getString(_kRadarrUrl) ?? '',
      radarrApiKey: _prefs.getString(_kRadarrApiKey) ?? '',
      sonarrUrl: _prefs.getString(_kSonarrUrl) ?? '',
      sonarrApiKey: _prefs.getString(_kSonarrApiKey) ?? '',
      lidarrUrl: _prefs.getString(_kLidarrUrl) ?? '',
      lidarrApiKey: _prefs.getString(_kLidarrApiKey) ?? '',
    );
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _prefs.setString(_kJellyseerrUrl, settings.jellyseerrUrl);
    await _prefs.setString(_kJellyseerrApiKey, settings.jellyseerrApiKey);
    await _prefs.setString(_kRadarrUrl, settings.radarrUrl);
    await _prefs.setString(_kRadarrApiKey, settings.radarrApiKey);
    await _prefs.setString(_kSonarrUrl, settings.sonarrUrl);
    await _prefs.setString(_kSonarrApiKey, settings.sonarrApiKey);
    await _prefs.setString(_kLidarrUrl, settings.lidarrUrl);
    await _prefs.setString(_kLidarrApiKey, settings.lidarrApiKey);
  }
}
