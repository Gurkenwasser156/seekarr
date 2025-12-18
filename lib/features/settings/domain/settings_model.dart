class SettingsModel {
  final String jellyseerrUrl;
  final String jellyseerrApiKey;
  final String radarrUrl;
  final String radarrApiKey;
  final String sonarrUrl;
  final String sonarrApiKey;
  final String lidarrUrl;
  final String lidarrApiKey;

  const SettingsModel({
    this.jellyseerrUrl = '',
    this.jellyseerrApiKey = '',
    this.radarrUrl = '',
    this.radarrApiKey = '',
    this.sonarrUrl = '',
    this.sonarrApiKey = '',
    this.lidarrUrl = '',
    this.lidarrApiKey = '',
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
    );
  }
}
