import 'dart:ui';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seekarr/features/settings/domain/nav_tab.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

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
  static const _kRegion = 'region';
  static const _kThemeMode = 'theme_mode';
  static const _kHiddenTabs = 'hidden_tabs';

  static const Map<ServiceKey, _ServiceStorageKeys> _serviceStorageKeys = {
    ServiceKey.jellyseerr: _ServiceStorageKeys(
      url: 'jellyseerr_url',
      legacyApiKey: 'jellyseerr_api_key',
      secureApiKey: 'secure_jellyseerr_api_key',
    ),
    ServiceKey.radarr: _ServiceStorageKeys(
      url: 'radarr_url',
      legacyApiKey: 'radarr_api_key',
      secureApiKey: 'secure_radarr_api_key',
    ),
    ServiceKey.sonarr: _ServiceStorageKeys(
      url: 'sonarr_url',
      legacyApiKey: 'sonarr_api_key',
      secureApiKey: 'secure_sonarr_api_key',
    ),
    ServiceKey.lidarr: _ServiceStorageKeys(
      url: 'lidarr_url',
      legacyApiKey: 'lidarr_api_key',
      secureApiKey: 'secure_lidarr_api_key',
    ),
  };

  final SharedPreferences _prefs;
  final SecureSettingsStore _secureStore;

  SettingsService(this._prefs, this._secureStore);

  Future<void> migrateFromPlaintext() async {
    for (final storageKeys in _serviceStorageKeys.values) {
      final plaintextValue = _prefs.getString(storageKeys.legacyApiKey);
      if (plaintextValue == null) {
        continue;
      }

      final normalizedValue = plaintextValue.trim();
      final secureValue = await _secureStore.read(
        key: storageKeys.secureApiKey,
      );

      if (normalizedValue.isNotEmpty &&
          (secureValue == null || secureValue.isEmpty)) {
        await _secureStore.write(
          key: storageKeys.secureApiKey,
          value: normalizedValue,
        );
      }

      await _prefs.remove(storageKeys.legacyApiKey);
    }
  }

  Future<SettingsModel> loadSettings() async {
    final serviceSettings = await _loadServiceSettings();

    return SettingsModel(
      jellyseerrUrl: serviceSettings[ServiceKey.jellyseerr]!.$1,
      jellyseerrApiKey: serviceSettings[ServiceKey.jellyseerr]!.$2,
      radarrUrl: serviceSettings[ServiceKey.radarr]!.$1,
      radarrApiKey: serviceSettings[ServiceKey.radarr]!.$2,
      sonarrUrl: serviceSettings[ServiceKey.sonarr]!.$1,
      sonarrApiKey: serviceSettings[ServiceKey.sonarr]!.$2,
      lidarrUrl: serviceSettings[ServiceKey.lidarr]!.$1,
      lidarrApiKey: serviceSettings[ServiceKey.lidarr]!.$2,
      region: _loadRegion(),
      themeMode: AppThemeMode.fromName(_prefs.getString(_kThemeMode)),
      hiddenTabs: _loadHiddenTabs(),
    );
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final normalizedRegion = SettingsModel.normalizeRegion(settings.region);
    final hiddenTabs = SettingsModel.sanitizeHiddenTabs(settings.hiddenTabs);

    await _saveServiceUrls(settings);
    await _prefs.setString(_kRegion, normalizedRegion);
    await _prefs.setString(_kThemeMode, settings.themeMode.name);
    await _prefs.setStringList(
      _kHiddenTabs,
      hiddenTabs.map((tab) => tab.name).toList(growable: false),
    );

    await _saveServiceApiKeys(settings);
  }

  Future<Map<ServiceKey, (String, String)>> _loadServiceSettings() async {
    final settingsByService = <ServiceKey, (String, String)>{};

    for (final service in ServiceKey.values) {
      final storageKeys = _serviceStorageKeys[service]!;
      settingsByService[service] = (
        _loadString(storageKeys.url),
        await _loadApiKey(storageKeys.secureApiKey),
      );
    }

    return settingsByService;
  }

  Future<void> _saveServiceUrls(SettingsModel settings) async {
    for (final service in ServiceKey.values) {
      final storageKeys = _serviceStorageKeys[service]!;
      await _prefs.setString(storageKeys.url, settings.urlFor(service));
    }
  }

  Future<void> _saveServiceApiKeys(SettingsModel settings) async {
    for (final service in ServiceKey.values) {
      final storageKeys = _serviceStorageKeys[service]!;
      await _saveApiKey(storageKeys.secureApiKey, settings.apiKeyFor(service));
    }
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

class _ServiceStorageKeys {
  final String url;
  final String legacyApiKey;
  final String secureApiKey;

  const _ServiceStorageKeys({
    required this.url,
    required this.legacyApiKey,
    required this.secureApiKey,
  });
}
