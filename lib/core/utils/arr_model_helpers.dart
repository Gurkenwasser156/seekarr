import 'package:seekarr/core/models/rating_source.dart';

/// Parses *arr API ratings data into a list of [RatingSource].
List<RatingSource> parseArrRatings(
  dynamic ratingsData, {
  bool allowMultiSource = true,
  bool allowSingleSource = true,
  String singleSourceIcon = 'TVDB',
  String? singleSourceName,
}) {
  if (ratingsData is! Map<String, dynamic>) {
    return [];
  }

  final ratings = <RatingSource>[];
  final isMultiSource = ratingsData.values.any(
    (value) => value is Map && value['value'] != null,
  );

  if (allowMultiSource && isMultiSource) {
    ratingsData.forEach((source, data) {
      if (data is Map && data['value'] != null) {
        final value = (data['value'] as num?)?.toDouble();
        final votes = (data['votes'] as num?)?.toInt() ?? 0;

        if (value != null) {
          ratings.add(
            RatingSource(
              name: _displayNameForSource(source),
              value: value,
              votes: votes,
              icon: _iconForSource(source),
            ),
          );
        }
      }
    });

    return ratings;
  }

  if (!allowSingleSource || isMultiSource) {
    return ratings;
  }

  final value = (ratingsData['value'] as num?)?.toDouble();
  final votes = (ratingsData['votes'] as num?)?.toInt() ?? 0;

  if (value == null) {
    return ratings;
  }

  ratings.add(
    RatingSource(
      name: singleSourceName ?? '$votes voti',
      value: value,
      votes: votes,
      icon: singleSourceIcon,
    ),
  );

  return ratings;
}

/// Parses a JSON genres field into a typed `List<String>`.
List<String> parseGenreList(dynamic genres) {
  if (genres is! List) {
    return [];
  }

  return genres.map((genre) => genre.toString()).toList();
}

/// Extracts a poster URL string from an *arr images list for MediaPreview use.
String? extractPosterPathFromImages(List<dynamic> images) {
  try {
    final poster = images.firstWhere(
      (image) => image['coverType'] == 'poster',
      orElse: () => null,
    );

    return poster?['remoteUrl'] ?? poster?['url'];
  } catch (_) {
    return null;
  }
}

String _iconForSource(String source) {
  switch (source.toLowerCase()) {
    case 'tmdb':
      return 'TMDB';
    case 'imdb':
      return 'IMDb';
    case 'tvdb':
      return 'TVDB';
    case 'metacritic':
      return 'MC';
    case 'rotten':
      return 'RT';
    default:
      return source.toUpperCase().substring(0, 2);
  }
}

String _displayNameForSource(String source) {
  switch (source.toLowerCase()) {
    case 'tmdb':
      return 'TMDB';
    case 'imdb':
      return 'IMDb';
    case 'tvdb':
      return 'TVDB';
    case 'metacritic':
      return 'Metacritic';
    case 'rotten':
      return 'Rotten Tomatoes';
    default:
      return source.toUpperCase();
  }
}
