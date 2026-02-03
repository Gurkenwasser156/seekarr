import 'package:seekarr/core/models/media_preview.dart';

class RatingSource {
  final String name;
  final double value;
  final int votes;
  final String icon;

  RatingSource({
    required this.name,
    required this.value,
    required this.votes,
    required this.icon,
  });
}

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
  final List<RatingSource> ratings;

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
    this.ratings = const [],
  });

  factory SonarrSeries.fromJson(Map<String, dynamic> json) {
    final ratingsData = json['ratings'];
    final List<RatingSource> ratings = [];

    if (ratingsData != null) {
      // Handle both map of sources and single ratings object
      if (ratingsData is Map<String, dynamic>) {
        bool isMultiSource = ratingsData.values.any(
          (v) => v is Map && v['value'] != null,
        );
        if (isMultiSource) {
          // Multi-source ratings (like Radarr: { tmdb: {value, votes}, imdb: {value, votes} })
          ratingsData.forEach((source, data) {
            if (data is Map && data['value'] != null) {
              final value = (data['value'] as num?)?.toDouble();
              final votes = (data['votes'] as num?)?.toInt() ?? 0;
              if (value != null) {
                String icon;
                String displayName;
                switch (source.toLowerCase()) {
                  case 'tmdb':
                    icon = 'TMDB';
                    displayName = 'TMDB';
                    break;
                  case 'imdb':
                    icon = 'IMDb';
                    displayName = 'IMDb';
                    break;
                  case 'tvdb':
                    icon = 'TVDB';
                    displayName = 'TVDB';
                    break;
                  case 'metacritic':
                    icon = 'MC';
                    displayName = 'Metacritic';
                    break;
                  case 'rotten':
                    icon = 'RT';
                    displayName = 'Rotten Tomatoes';
                    break;
                  default:
                    icon = source.toUpperCase().substring(0, 2);
                    displayName = source.toUpperCase();
                }
                ratings.add(
                  RatingSource(
                    name: displayName,
                    value: value,
                    votes: votes,
                    icon: icon,
                  ),
                );
              }
            }
          });
        } else {
          // Single ratings object (like Sonarr: { value: 8.4, votes: 145000 })
          final value = (ratingsData['value'] as num?)?.toDouble();
          final votes = (ratingsData['votes'] as num?)?.toInt() ?? 0;
          if (value != null) {
            ratings.add(
              RatingSource(
                name: '${votes} voti',
                value: value,
                votes: votes,
                icon: 'TVDB',
              ),
            );
          }
        }
      }
    }

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
      ratings: ratings,
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
