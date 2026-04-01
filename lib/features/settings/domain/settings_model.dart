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

  /// Returns the URL configured for [service].
  String urlFor(ServiceKey service) {
    return switch (service) {
      ServiceKey.jellyseerr => jellyseerrUrl,
      ServiceKey.radarr => radarrUrl,
      ServiceKey.sonarr => sonarrUrl,
      ServiceKey.lidarr => lidarrUrl,
    };
  }

  /// Returns the API key configured for [service].
  String apiKeyFor(ServiceKey service) {
    return switch (service) {
      ServiceKey.jellyseerr => jellyseerrApiKey,
      ServiceKey.radarr => radarrApiKey,
      ServiceKey.sonarr => sonarrApiKey,
      ServiceKey.lidarr => lidarrApiKey,
    };
  }

  /// Returns a copy with the URL and/or API key updated for [service].
  SettingsModel copyWithService(
    ServiceKey service, {
    String? url,
    String? apiKey,
  }) {
    return switch (service) {
      ServiceKey.jellyseerr => copyWith(
        jellyseerrUrl: url,
        jellyseerrApiKey: apiKey,
      ),
      ServiceKey.radarr => copyWith(radarrUrl: url, radarrApiKey: apiKey),
      ServiceKey.sonarr => copyWith(sonarrUrl: url, sonarrApiKey: apiKey),
      ServiceKey.lidarr => copyWith(lidarrUrl: url, lidarrApiKey: apiKey),
    };
  }
}
