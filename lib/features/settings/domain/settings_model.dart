import 'package:flutter/material.dart' show ThemeMode;

import 'package:seekarr/features/settings/domain/nav_tab.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

enum AppThemeMode {
  system(label: 'System'),
  light(label: 'Light'),
  dark(label: 'Dark');

  const AppThemeMode({required this.label});

  final String label;

  static final Map<String, AppThemeMode> _modesByName = {
    for (final mode in values) mode.name: mode,
  };

  ThemeMode get materialThemeMode {
    return switch (this) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }

  static AppThemeMode fromName(String? value) =>
      _modesByName[value] ?? AppThemeMode.system;
}

class SettingsModel {
  final String jellyseerrUrl;
  final String jellyseerrApiKey;
  final String radarrUrl;
  final String radarrApiKey;
  final String sonarrUrl;
  final String sonarrApiKey;
  final String lidarrUrl;
  final String lidarrApiKey;
  final String region;
  final AppThemeMode themeMode;
  final Set<NavTab> hiddenTabs;

  static final Map<ServiceKey, _ServiceSettingsAccess> _serviceSettingsAccess =
      {
        ServiceKey.jellyseerr: _ServiceSettingsAccess(
          url: (settings) => settings.jellyseerrUrl,
          apiKey: (settings) => settings.jellyseerrApiKey,
          update: (settings, {url, apiKey}) =>
              settings.copyWith(jellyseerrUrl: url, jellyseerrApiKey: apiKey),
        ),
        ServiceKey.radarr: _ServiceSettingsAccess(
          url: (settings) => settings.radarrUrl,
          apiKey: (settings) => settings.radarrApiKey,
          update: (settings, {url, apiKey}) =>
              settings.copyWith(radarrUrl: url, radarrApiKey: apiKey),
        ),
        ServiceKey.sonarr: _ServiceSettingsAccess(
          url: (settings) => settings.sonarrUrl,
          apiKey: (settings) => settings.sonarrApiKey,
          update: (settings, {url, apiKey}) =>
              settings.copyWith(sonarrUrl: url, sonarrApiKey: apiKey),
        ),
        ServiceKey.lidarr: _ServiceSettingsAccess(
          url: (settings) => settings.lidarrUrl,
          apiKey: (settings) => settings.lidarrApiKey,
          update: (settings, {url, apiKey}) =>
              settings.copyWith(lidarrUrl: url, lidarrApiKey: apiKey),
        ),
      };

  static String normalizeRegion(String? region) {
    final normalized = region?.trim().toUpperCase() ?? '';
    return normalized.isEmpty ? 'US' : normalized;
  }

  static Set<NavTab> sanitizeHiddenTabs(Iterable<NavTab> tabs) {
    return tabs.where((tab) => tab.canBeHidden).toSet();
  }

  const SettingsModel({
    this.jellyseerrUrl = '',
    this.jellyseerrApiKey = '',
    this.radarrUrl = '',
    this.radarrApiKey = '',
    this.sonarrUrl = '',
    this.sonarrApiKey = '',
    this.lidarrUrl = '',
    this.lidarrApiKey = '',
    this.region = 'US',
    this.themeMode = AppThemeMode.system,
    this.hiddenTabs = const <NavTab>{},
  });

  SettingsModel copyWith({
    String? jellyseerrUrl,
    String? jellyseerrApiKey,
    String? radarrUrl,
    String? radarrApiKey,
    String? sonarrUrl,
    String? sonarrApiKey,
    String? lidarrUrl,
    String? lidarrApiKey,
    String? region,
    AppThemeMode? themeMode,
    Set<NavTab>? hiddenTabs,
  }) {
    return SettingsModel(
      jellyseerrUrl: jellyseerrUrl ?? this.jellyseerrUrl,
      jellyseerrApiKey: jellyseerrApiKey ?? this.jellyseerrApiKey,
      radarrUrl: radarrUrl ?? this.radarrUrl,
      radarrApiKey: radarrApiKey ?? this.radarrApiKey,
      sonarrUrl: sonarrUrl ?? this.sonarrUrl,
      sonarrApiKey: sonarrApiKey ?? this.sonarrApiKey,
      lidarrUrl: lidarrUrl ?? this.lidarrUrl,
      lidarrApiKey: lidarrApiKey ?? this.lidarrApiKey,
      region: region ?? this.region,
      themeMode: themeMode ?? this.themeMode,
      hiddenTabs: hiddenTabs == null
          ? this.hiddenTabs
          : sanitizeHiddenTabs(hiddenTabs),
    );
  }

  ThemeMode get resolvedThemeMode => themeMode.materialThemeMode;

  bool isTabVisible(NavTab tab) {
    return !tab.canBeHidden || !hiddenTabs.contains(tab);
  }

  _ServiceSettingsAccess _serviceAccessFor(ServiceKey service) {
    return _serviceSettingsAccess[service]!;
  }

  /// Returns the URL configured for [service].
  String urlFor(ServiceKey service) {
    return _serviceAccessFor(service).url(this);
  }

  /// Returns the API key configured for [service].
  String apiKeyFor(ServiceKey service) {
    return _serviceAccessFor(service).apiKey(this);
  }

  /// Returns a copy with the URL and/or API key updated for [service].
  SettingsModel copyWithService(
    ServiceKey service, {
    String? url,
    String? apiKey,
  }) {
    return _serviceAccessFor(service).update(this, url: url, apiKey: apiKey);
  }
}

class _ServiceSettingsAccess {
  final String Function(SettingsModel settings) url;
  final String Function(SettingsModel settings) apiKey;
  final SettingsModel Function(
    SettingsModel settings, {
    String? url,
    String? apiKey,
  })
  update;

  const _ServiceSettingsAccess({
    required this.url,
    required this.apiKey,
    required this.update,
  });
}
