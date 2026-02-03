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

class RadarrMovie {
  final int id;
  final String title;
  final String sortTitle;
  final int sizeOnDisk;
  final String status;
  final String? overview;
  final String? path;
  final bool hasFile;
  final bool monitored;
  final int year;
  final List<dynamic> images;
  final int tmdbId;
  final int runtime;
  final String? studio;
  final List<String> genres;
  final int? qualityProfileId;
  final List<RatingSource> ratings;

  const RadarrMovie({
    required this.id,
    required this.title,
    required this.sortTitle,
    required this.sizeOnDisk,
    required this.status,
    this.overview,
    this.path,
    required this.hasFile,
    required this.monitored,
    required this.year,
    required this.images,
    required this.tmdbId,
    required this.runtime,
    this.studio,
    required this.genres,
    this.qualityProfileId,
    this.ratings = const [],
  });

  factory RadarrMovie.fromJson(Map<String, dynamic> json) {
    final ratingsData = json['ratings'] as Map<String, dynamic>?;
    final List<RatingSource> ratings = [];

    if (ratingsData != null) {
      ratingsData.forEach((source, data) {
        if (data is Map<String, dynamic> && data['value'] != null) {
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
    }

    return RadarrMovie(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown',
      sortTitle: json['sortTitle'] ?? '',
      sizeOnDisk: json['sizeOnDisk'] ?? 0,
      status: json['status'] ?? 'unknown',
      overview: json['overview'],
      path: json['path'],
      hasFile: json['hasFile'] ?? false,
      monitored: json['monitored'] ?? false,
      year: json['year'] ?? 0,
      images: json['images'] ?? [],
      tmdbId: json['tmdbId'] ?? 0,
      runtime: json['runtime'] ?? 0,
      studio: json['studio'],
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      qualityProfileId: json['qualityProfileId'],
      ratings: ratings,
    );
  }

  /// Converts to the shared [MediaPreview] model for generic lists
  MediaPreview toMediaPreview() {
    String? posterPath;
    try {
      final poster = images.firstWhere(
        (img) => img['coverType'] == 'poster',
        orElse: () => null,
      );
      posterPath = poster?['remoteUrl'] ?? poster?['url'];
      // Note: remoteUrl usually is full URL (image.tmdb.org/...)
      // But MediaPreview expects a path to append to base, OR we adjust logic.
      // However MediaPreview.fromJson expects a partial path for TMDB usually.
      // Let's assume for now we use the remoteUrl if available but we might need to handle it.
      // Actually MediaPreview expects a TMDB path (starting with /).
      // Radarr might give full URLs or relative paths.
    } catch (_) {}

    return MediaPreview(
      id: id,
      title: title,
      posterPath:
          posterPath, // This might need logic adjustment in UI if it's a full URL
      overview: overview,
      releaseDate: year.toString(),
      mediaType: 'movie',
    );
  }
}
