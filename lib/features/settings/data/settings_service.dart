import 'dart:ui';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seekarr/features/settings/domain/nav_tab.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

abstract interface class SecureSettingsStore {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});

  Future<void> delete({required String key});
}

class FlutterSecureSettingsStore implements SecureSettingsStore {
  final FlutterSecureStorage _storage;

  const FlutterSecureSettingsStore(this._storage);

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }
}

class SettingsService {
  static const _kJellyseerrUrl = 'jellyseerr_url';
  static const _kRadarrUrl = 'radarr_url';
  static const _kSonarrUrl = 'sonarr_url';
  static const _kLidarrUrl = 'lidarr_url';
  static const _kRegion = 'region';
  static const _kThemeMode = 'theme_mode';
  static const _kHiddenTabs = 'hidden_tabs';

  static const _kLegacyJellyseerrApiKey = 'jellyseerr_api_key';
  static const _kLegacyRadarrApiKey = 'radarr_api_key';
  static const _kLegacySonarrApiKey = 'sonarr_api_key';
  static const _kLegacyLidarrApiKey = 'lidarr_api_key';

  static const _kSecureJellyseerrApiKey = 'secure_jellyseerr_api_key';
  static const _kSecureRadarrApiKey = 'secure_radarr_api_key';
  static const _kSecureSonarrApiKey = 'secure_sonarr_api_key';
  static const _kSecureLidarrApiKey = 'secure_lidarr_api_key';

  static const Map<String, String> _legacyApiKeyMigrations = {
    _kLegacyJellyseerrApiKey: _kSecureJellyseerrApiKey,
    _kLegacyRadarrApiKey: _kSecureRadarrApiKey,
    _kLegacySonarrApiKey: _kSecureSonarrApiKey,
    _kLegacyLidarrApiKey: _kSecureLidarrApiKey,
  };

  final SharedPreferences _prefs;
  final SecureSettingsStore _secureStore;

  SettingsService(this._prefs, this._secureStore);

  Future<void> migrateFromPlaintext() async {
    for (final entry in _legacyApiKeyMigrations.entries) {
      final plaintextValue = _prefs.getString(entry.key);
      if (plaintextValue == null) {
        continue;
      }

      final normalizedValue = plaintextValue.trim();
      final secureValue = await _secureStore.read(key: entry.value);

      if (normalizedValue.isNotEmpty &&
          (secureValue == null || secureValue.isEmpty)) {
        await _secureStore.write(key: entry.value, value: normalizedValue);
      }

      await _prefs.remove(entry.key);
    }
  }

  Future<SettingsModel> loadSettings() async {
    return SettingsModel(
      jellyseerrUrl: _loadString(_kJellyseerrUrl),
      jellyseerrApiKey: await _loadApiKey(_kSecureJellyseerrApiKey),
      radarrUrl: _loadString(_kRadarrUrl),
      radarrApiKey: await _loadApiKey(_kSecureRadarrApiKey),
      sonarrUrl: _loadString(_kSonarrUrl),
      sonarrApiKey: await _loadApiKey(_kSecureSonarrApiKey),
      lidarrUrl: _loadString(_kLidarrUrl),
      lidarrApiKey: await _loadApiKey(_kSecureLidarrApiKey),
      region: _loadRegion(),
      themeMode: AppThemeMode.fromName(_prefs.getString(_kThemeMode)),
      hiddenTabs: _loadHiddenTabs(),
    );
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final normalizedRegion = SettingsModel.normalizeRegion(settings.region);
    final hiddenTabs = SettingsModel.sanitizeHiddenTabs(settings.hiddenTabs);

    await _prefs.setString(_kJellyseerrUrl, settings.jellyseerrUrl);
    await _prefs.setString(_kRadarrUrl, settings.radarrUrl);
    await _prefs.setString(_kSonarrUrl, settings.sonarrUrl);
    await _prefs.setString(_kLidarrUrl, settings.lidarrUrl);
    await _prefs.setString(_kRegion, normalizedRegion);
    await _prefs.setString(_kThemeMode, settings.themeMode.name);
    await _prefs.setStringList(
      _kHiddenTabs,
      hiddenTabs.map((tab) => tab.name).toList(growable: false),
    );

    await _saveApiKey(_kSecureJellyseerrApiKey, settings.jellyseerrApiKey);
    await _saveApiKey(_kSecureRadarrApiKey, settings.radarrApiKey);
    await _saveApiKey(_kSecureSonarrApiKey, settings.sonarrApiKey);
    await _saveApiKey(_kSecureLidarrApiKey, settings.lidarrApiKey);
  }

  Set<NavTab> _loadHiddenTabs() {
    final storedNames =
        _prefs.getStringList(_kHiddenTabs) ?? _loadLegacyHiddenTabs();

    return SettingsModel.sanitizeHiddenTabs(
      storedNames
          .map((name) => NavTab.fromName(name.trim()))
          .whereType<NavTab>(),
    );
  }

  List<String> _loadLegacyHiddenTabs() {
    final legacyHiddenTabs = _prefs.getString(_kHiddenTabs);
    if (legacyHiddenTabs == null || legacyHiddenTabs.trim().isEmpty) {
      return const [];
    }

    return legacyHiddenTabs
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String _loadString(String key) {
    return _prefs.getString(key) ?? '';
  }

  String _loadRegion() {
    return SettingsModel.normalizeRegion(
      _prefs.getString(_kRegion) ??
          PlatformDispatcher.instance.locale.countryCode,
    );
  }

  Future<String> _loadApiKey(String key) async {
    return await _secureStore.read(key: key) ?? '';
  }

  Future<void> _saveApiKey(String key, String value) async {
    final normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      await _secureStore.delete(key: key);
      return;
    }

    await _secureStore.write(key: key, value: normalizedValue);
  }
}
