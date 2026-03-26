import 'package:seekarr/core/utils/image_utils.dart';

typedef DiscoverDetailRating = ({
  String name,
  double value,
  int votes,
  String icon,
});

typedef DiscoverCastMember = ({
  String name,
  String character,
  String? profilePath,
});

class DiscoverDetailViewModel {
  final String title;
  final String overview;
  final String posterUrl;
  final String jellyseerrStatus;
  final bool isAvailable;
  final int? statusCode;
  final Map<String, dynamic>? mediaInfo;
  final String genres;
  final String year;
  final String? runtimeStr;
  final int? numberOfSeasons;
  final String networks;
  final double? voteAverage;
  final int? voteCount;
  final List<DiscoverCastMember> cast;
  final List<String> directors;
  final List<String> writers;
  final List<String> keywords;
  final int? tvdbId;

  const DiscoverDetailViewModel({
    required this.title,
    required this.overview,
    required this.posterUrl,
    required this.jellyseerrStatus,
    required this.isAvailable,
    required this.statusCode,
    required this.mediaInfo,
    required this.genres,
    required this.year,
    required this.runtimeStr,
    required this.numberOfSeasons,
    required this.networks,
    required this.voteAverage,
    required this.voteCount,
    required this.cast,
    required this.directors,
    required this.writers,
    required this.keywords,
    required this.tvdbId,
  });

  String get metadataLine =>
      [genres, networks].where((value) => value.isNotEmpty).join(' • ');

  bool get hasCrew => directors.isNotEmpty || writers.isNotEmpty;

  bool get hasManageableMedia => mediaInfo?['id'] != null;

  String? get servicePath => mediaInfo?['path']?.toString();

  String get directorNames => directors.join(', ');

  String get writerNames => writers.join(', ');

  factory DiscoverDetailViewModel.fromResponse(
    Map<String, dynamic> details, {
    String? initialPosterUrl,
  }) {
    final mediaInfo = _asMap(details['mediaInfo']);
    final externalIds = _asMap(details['externalIds']);
    final statusCode = (mediaInfo?['status'] as num?)?.toInt();
    final releaseDate =
        details['releaseDate'] ??
        details['release_date'] ??
        details['firstAirDate'] ??
        details['first_air_date'];
    final runtime = (details['runtime'] as num?)?.toInt();
    final credits = _asMap(details['credits']);
    final crew = _asMapList(credits?['crew']);
    final cast = _asMapList(credits?['cast']);
    final posterPath =
        details['posterPath']?.toString() ?? details['poster_path']?.toString();

    return DiscoverDetailViewModel(
      title:
          details['title']?.toString() ??
          details['name']?.toString() ??
          'Unknown',
      overview: details['overview']?.toString() ?? '',
      posterUrl: initialPosterUrl != null && initialPosterUrl.isNotEmpty
          ? initialPosterUrl
          : ImageUtils.buildTmdbPosterUrl(posterPath, size: 'w500'),
      jellyseerrStatus: mapJellyseerrStatus(statusCode),
      isAvailable: statusCode == 4 || statusCode == 5,
      statusCode: statusCode,
      mediaInfo: mediaInfo,
      genres: _joinNamedValues(details['genres']),
      year: _extractYear(releaseDate),
      runtimeStr: runtime != null && runtime > 0 ? '${runtime}min' : null,
      numberOfSeasons: (details['numberOfSeasons'] as num?)?.toInt(),
      networks: _joinNamedValues(details['networks'], take: 2),
      voteAverage:
          (details['voteAverage'] as num?)?.toDouble() ??
          (details['vote_average'] as num?)?.toDouble(),
      voteCount:
          (details['voteCount'] as num?)?.toInt() ??
          (details['vote_count'] as num?)?.toInt(),
      cast: cast.take(20).map(_toCastMember).toList(growable: false),
      directors: _takeCrewNames(crew, jobs: const {'Director'}),
      writers: _takeCrewNames(crew, jobs: const {'Writer', 'Screenplay'}),
      keywords: _takeNames(_asMapList(details['keywords'])),
      tvdbId:
          (externalIds?['tvdbId'] as num?)?.toInt() ??
          (details['tvdbId'] as num?)?.toInt(),
    );
  }

  static String mapJellyseerrStatus(int? status) {
    if (status == null) return 'Available to Request';

    switch (status) {
      case 1:
        return 'Pending';
      case 2:
        return 'Processing';
      case 3:
        return 'Partial';
      case 4:
      case 5:
        return 'Available';
      default:
        return 'Unknown';
    }
  }
}

DiscoverCastMember _toCastMember(Map<String, dynamic> member) {
  return (
    name: member['name']?.toString() ?? '',
    character: member['character']?.toString() ?? '',
    profilePath:
        member['profilePath']?.toString() ?? member['profile_path']?.toString(),
  );
}

List<String> _takeCrewNames(
  List<Map<String, dynamic>> crew, {
  required Set<String> jobs,
  int limit = 2,
}) {
  return crew
      .where((member) => jobs.contains(member['job']))
      .map((member) => member['name']?.toString() ?? '')
      .where((name) => name.isNotEmpty)
      .take(limit)
      .toList(growable: false);
}

List<String> _takeNames(List<Map<String, dynamic>> items, {int limit = 8}) {
  return items
      .map((item) => item['name']?.toString() ?? '')
      .where((name) => name.isNotEmpty)
      .take(limit)
      .toList(growable: false);
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return null;
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map(_asMap)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

String _extractYear(Object? releaseDate) {
  final value = releaseDate?.toString() ?? '';
  return value.length >= 4 ? value.substring(0, 4) : '';
}

String _joinNamedValues(Object? value, {int? take}) {
  final labels = <String>[];

  if (value is List) {
    for (final item in value) {
      if (item is Map) {
        final label = item['name']?.toString();
        if (label != null && label.isNotEmpty) {
          labels.add(label);
        }
      } else if (item != null) {
        final label = item.toString();
        if (label.isNotEmpty) {
          labels.add(label);
        }
      }
    }
  }

  final limitedLabels = take != null ? labels.take(take) : labels;
  return limitedLabels.join(', ');
}
