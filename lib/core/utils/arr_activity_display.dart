import 'package:seekarr/core/utils/dynamic_map_utils.dart';

String joinDisplayParts(Iterable<String?> parts, {String separator = ' · '}) {
  return parts
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(separator);
}

String? formatArrEpisodeCode(int? seasonNumber, int? episodeNumber) {
  if (seasonNumber == null || episodeNumber == null) return null;

  final season = seasonNumber.toString().padLeft(2, '0');
  final episode = episodeNumber.toString().padLeft(2, '0');
  return 'S$season'
      'E$episode';
}

List<String> extractArrStatusMessages(dynamic rawMessages) {
  if (rawMessages is! List || rawMessages.isEmpty) return const [];

  final messages = <String>[];
  for (final entry in rawMessages) {
    final map = mapOrNull(entry);
    if (map == null) {
      final text = stringOrNull(entry);
      if (text != null) messages.add(text);
      continue;
    }

    final title = stringOrNull(map['title']);
    final nestedMessages = map['messages'];
    if (nestedMessages is List && nestedMessages.isNotEmpty) {
      for (final nested in nestedMessages) {
        final body = stringOrNull(nested);
        if (body != null) {
          messages.add(title == null ? body : '$title: $body');
        }
      }
      continue;
    }

    final text = stringOrNull(map['message'] ?? map['text'] ?? map['title']);
    if (text != null) messages.add(text);
  }

  return messages;
}

String? arrReleaseTitle(Map<String, dynamic> item) {
  return stringOrNull(item['title'] ?? item['sourceTitle']);
}

String? arrMovieTitle(Map<String, dynamic> item, {bool includeYear = false}) {
  final movie = mapOrNull(item['movie']);
  final title = stringOrNull(movie?['title']);
  final year = intOrNull(movie?['year'] ?? item['year']);
  if (title == null) return null;
  if (!includeYear || year == null) return title;
  return '$title ($year)';
}

String? arrSeriesTitle(Map<String, dynamic> item) {
  return stringOrNull(
    mapOrNull(item['series'])?['title'] ?? item['seriesTitle'],
  );
}

String? arrEpisodeTitle(Map<String, dynamic> item) {
  return stringOrNull(
    mapOrNull(item['episode'])?['title'] ?? item['episodeTitle'],
  );
}

String? arrEpisodeCode(Map<String, dynamic> item) {
  final episode = mapOrNull(item['episode']);
  return formatArrEpisodeCode(
    intOrNull(episode?['seasonNumber'] ?? item['seasonNumber']),
    intOrNull(episode?['episodeNumber'] ?? item['episodeNumber']),
  );
}

String? arrArtistName(Map<String, dynamic> item) {
  return stringOrNull(mapOrNull(item['artist'])?['artistName']);
}

String? arrAlbumTitle(Map<String, dynamic> item) {
  return stringOrNull(mapOrNull(item['album'])?['title']);
}

String? arrPrimaryMediaTitle(
  Map<String, dynamic> item, {
  bool includeMovieYear = false,
}) {
  return arrMovieTitle(item, includeYear: includeMovieYear) ??
      arrSeriesTitle(item) ??
      arrAlbumTitle(item) ??
      arrArtistName(item);
}

bool arrQueueHasWarning(Map<String, dynamic> item) {
  final trackedStatus = stringOrNull(
    item['trackedDownloadStatus'],
  )?.toLowerCase();
  return trackedStatus == 'warning' ||
      extractArrStatusMessages(item['statusMessages']).isNotEmpty;
}

String? arrQueueWarningMessage(Map<String, dynamic> item) {
  final messages = extractArrStatusMessages(item['statusMessages']);
  if (messages.isNotEmpty) return messages.first;
  return arrQueueHasWarning(item) ? 'Warning' : null;
}
