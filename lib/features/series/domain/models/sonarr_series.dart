import 'package:seekarr/core/models/media_preview.dart';

class SonarrSeries {
  final int id;
  final String title;
  final String sortTitle;
  final String status;
  final String? overview;
  final String? path;
  final bool monitored;
  final int year;
  final List<dynamic> images;
  final int tvdbId;
  final int runtime;
  final String? network;
  final List<String> genres;
  final List<dynamic> seasons;
  final Map<String, dynamic>? statistics;
  final int? qualityProfileId;

  const SonarrSeries({
    required this.id,
    required this.title,
    required this.sortTitle,
    required this.status,
    this.overview,
    this.path,
    required this.monitored,
    required this.year,
    required this.images,
    required this.tvdbId,
    required this.runtime,
    this.network,
    required this.genres,
    required this.seasons,
    this.statistics,
    this.qualityProfileId,
  });

  factory SonarrSeries.fromJson(Map<String, dynamic> json) {
    return SonarrSeries(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown',
      sortTitle: json['sortTitle'] ?? '',
      status: json['status'] ?? 'unknown',
      overview: json['overview'],
      path: json['path'],
      monitored: json['monitored'] ?? false,
      year: json['year'] ?? 0,
      images: json['images'] ?? [],
      tvdbId: json['tvdbId'] ?? 0,
      runtime: json['runtime'] ?? 0,
      network: json['network'],
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      seasons: json['seasons'] ?? [],
      statistics: json['statistics'],
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
      title: title,
      posterPath: posterPath,
      overview: overview,
      releaseDate: year.toString(),
      mediaType: 'tv',
    );
  }
}
