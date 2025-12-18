import 'package:seekarr/core/models/media_preview.dart';

class LidarrArtist {
  final int id;
  final String artistName;
  final String status;
  final String? overview;
  final bool monitored;
  final List<dynamic> images;
  final Map<String, dynamic>? statistics;
  final List<String> genres;
  final int? qualityProfileId;

  const LidarrArtist({
    required this.id,
    required this.artistName,
    required this.status,
    this.overview,
    required this.monitored,
    required this.images,
    this.statistics,
    required this.genres,
    this.qualityProfileId,
  });

  factory LidarrArtist.fromJson(Map<String, dynamic> json) {
    return LidarrArtist(
      id: json['id'] ?? 0,
      artistName: json['artistName'] ?? 'Unknown',
      status: json['status'] ?? 'unknown',
      overview: json['overview'],
      monitored: json['monitored'] ?? false,
      images: json['images'] ?? [],
      statistics: json['statistics'],
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      qualityProfileId: json['qualityProfileId'],
    );
  }

  MediaPreview toMediaPreview() {
    String? posterPath;
    try {
      final poster = images.firstWhere(
        (img) => img['coverType'] == 'poster',
        orElse: () => null,
      );
      posterPath = poster?['remoteUrl'] ?? poster?['url'];
    } catch (_) {}

    return MediaPreview(
      id: id,
      title: artistName,
      posterPath: posterPath,
      overview: overview,
      // Lidarr artists don't have a single "year" usually, maybe started/ended?
      // Leaving releaseDate null or empty.
      mediaType: 'music',
    );
  }
}
