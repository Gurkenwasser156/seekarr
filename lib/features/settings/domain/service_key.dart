import 'package:flutter/material.dart';

enum ServiceKey { jellyseerr, radarr, sonarr, lidarr }

extension ServiceKeyExtension on ServiceKey {
  String get title {
    switch (this) {
      case ServiceKey.jellyseerr:
        return 'Jellyseerr';
      case ServiceKey.radarr:
        return 'Radarr';
      case ServiceKey.sonarr:
        return 'Sonarr';
      case ServiceKey.lidarr:
        return 'Lidarr';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceKey.jellyseerr:
        return Icons.search_rounded;
      case ServiceKey.radarr:
        return Icons.movie_rounded;
      case ServiceKey.sonarr:
        return Icons.tv_rounded;
      case ServiceKey.lidarr:
        return Icons.music_note_rounded;
    }
  }

  String get routeParam {
    switch (this) {
      case ServiceKey.jellyseerr:
        return 'jellyseerr';
      case ServiceKey.radarr:
        return 'radarr';
      case ServiceKey.sonarr:
        return 'sonarr';
      case ServiceKey.lidarr:
        return 'lidarr';
    }
  }

  String? extractHost(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return null;
    }
  }
}
