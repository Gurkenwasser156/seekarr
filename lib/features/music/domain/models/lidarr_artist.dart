import 'package:seekarr/core/models/media_preview.dart';
import 'package:seekarr/core/models/rating_source.dart';
import 'package:seekarr/core/utils/arr_model_helpers.dart';

export 'package:seekarr/core/models/rating_source.dart';

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
  final List<RatingSource> ratings;

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
    this.ratings = const [],
  });

  factory LidarrArtist.fromJson(Map<String, dynamic> json) {
    final ratings = parseArrRatings(
      json['ratings'],
      allowMultiSource: false,
      singleSourceIcon: 'MB',
    );

    return LidarrArtist(
      id: json['id'] ?? 0,
      artistName: json['artistName'] ?? 'Unknown',
      status: json['status'] ?? 'unknown',
      overview: json['overview'],
      monitored: json['monitored'] ?? false,
      images: json['images'] ?? [],
      statistics: json['statistics'],
      genres: parseGenreList(json['genres']),
      qualityProfileId: json['qualityProfileId'],
      ratings: ratings,
    );
  }

  MediaPreview toMediaPreview() {
    final posterPath = extractPosterPathFromImages(images);

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
