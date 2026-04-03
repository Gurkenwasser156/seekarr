import 'package:seekarr/core/utils/release_utils.dart';
import 'package:seekarr/core/utils/string_utils.dart';
import 'package:seekarr/core/widgets/status_badge.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';

export 'package:seekarr/core/utils/string_utils.dart' show formatIsoDate;

Map<String, dynamic>? asActivityMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(key.toString(), nestedValue),
    );
  }
  return null;
}

String? stringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return null;
  return int.tryParse(value.toString());
}

String joinActivityParts(Iterable<String?> parts, {String separator = ' · '}) {
  return parts
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(separator);
}

String formatActivityBytes(dynamic bytes) {
  if (bytes == null) return '—';
  if (bytes is num) return formatReleaseSize(bytes.toInt());
  final parsed = int.tryParse(bytes.toString());
  return parsed == null ? bytes.toString() : formatReleaseSize(parsed);
}

String formatActivityDuration(String? value) {
  if (value == null || value.trim().isEmpty) return '—';

  final parts = value.split(':');
  if (parts.length != 3) return value;

  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  final seconds = int.tryParse(parts[2].split('.').first) ?? 0;
  final labels = <String>[];

  if (hours > 0) labels.add('${hours}h');
  if (minutes > 0) labels.add('${minutes}m');
  if (hours == 0 && minutes == 0) labels.add('${seconds}s');

  return labels.join(' ');
}

String formatRelativeActivityDate(String? isoDate, {DateTime? now}) {
  if (isoDate == null || isoDate.trim().isEmpty) return '—';

  try {
    final date = DateTime.parse(isoDate).toLocal();
    final reference = (now ?? DateTime.now()).toLocal();
    final difference = reference.difference(date);
    final isFuture = difference.isNegative;
    final delta = isFuture ? date.difference(reference) : difference;

    if (delta < const Duration(minutes: 1)) {
      return isFuture ? 'in <1m' : 'just now';
    }
    if (delta < const Duration(hours: 1)) {
      final minutes = delta.inMinutes;
      return isFuture ? 'in ${minutes}m' : '${minutes}m ago';
    }
    if (delta < const Duration(days: 1)) {
      final hours = delta.inHours;
      return isFuture ? 'in ${hours}h' : '${hours}h ago';
    }
    if (delta < const Duration(days: 7)) {
      final days = delta.inDays;
      return isFuture ? 'in ${days}d' : '${days}d ago';
    }

    return formatIsoDate(isoDate);
  } catch (_) {
    return isoDate;
  }
}

String formatActivityDateTime(String? isoDate) {
  if (isoDate == null || isoDate.trim().isEmpty) return '—';

  try {
    final date = DateTime.parse(isoDate).toLocal();
    final datePart = formatIsoDate(date.toIso8601String());
    final timePart =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$datePart $timePart';
  } catch (_) {
    return isoDate;
  }
}

String formatDateOnly(String? isoDate) {
  if (isoDate == null || isoDate.trim().isEmpty) return '—';
  return formatIsoDate(isoDate);
}

String formatSizeInGb(dynamic bytes) {
  if (bytes == null) return '—';

  final value = switch (bytes) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text),
    _ => null,
  };

  if (value == null) return '—';

  const bytesPerGb = 1024 * 1024 * 1024;
  return '${(value / bytesPerGb).toStringAsFixed(2)} GB';
}

String humanizeCamelCase(String value) {
  if (value.trim().isEmpty) return value;

  final normalized = value.replaceAll('_', ' ').replaceAll('-', ' ');
  final withSpaces = normalized.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match[1]} ${match[2]}',
  );

  return withSpaces
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String humanizeEventType(String value) {
  switch (value) {
    case 'grabbed':
      return 'Grabbed';
    case 'downloadFolderImported':
    case 'downloadImported':
      return 'Imported';
    case 'downloadFailed':
      return 'Failed';
    case 'episodeFileDeleted':
    case 'movieFileDeleted':
      return 'Deleted';
    case 'episodeFileRenamed':
    case 'movieFileRenamed':
      return 'Renamed';
    default:
      return humanizeCamelCase(value);
  }
}

({String label, MediaStatus badge}) resolveQueueDisplayStatus(
  Map<String, dynamic> item,
) {
  final trackedState = stringOrNull(
    item['trackedDownloadState'],
  )?.toLowerCase();
  final status = stringOrNull(item['status'])?.toLowerCase();
  final trackedStatus = stringOrNull(
    item['trackedDownloadStatus'],
  )?.toLowerCase();

  ({String label, MediaStatus badge})? resolved;

  switch (trackedState) {
    case 'downloading':
      resolved = (label: 'Downloading', badge: MediaStatus.downloading);
    case 'importpending':
    case 'importblocked':
      resolved = (label: 'Import Pending', badge: MediaStatus.queued);
    case 'importing':
      resolved = (label: 'Importing', badge: MediaStatus.downloading);
    case 'failedpending':
      resolved = (label: 'Failed', badge: MediaStatus.missing);
  }

  resolved ??= switch (status) {
    'completed' => (label: 'Completed', badge: MediaStatus.available),
    'delay' || 'queued' => (label: 'Queued', badge: MediaStatus.queued),
    'downloading' => (label: 'Downloading', badge: MediaStatus.downloading),
    'paused' => (label: 'Paused', badge: MediaStatus.queued),
    final String value when value.isNotEmpty => (
      label: humanizeCamelCase(value),
      badge: MediaStatus.unknown,
    ),
    _ => (label: 'Unknown', badge: MediaStatus.unknown),
  };

  if (trackedStatus == 'warning') {
    return (label: '${resolved.label} (Warning)', badge: resolved.badge);
  }

  return resolved;
}

String? wantedStatusText(Map<String, dynamic> item, ServiceType serviceType) {
  final normalizedStatus = stringOrNull(item['status'])?.toLowerCase();
  final hasFile = item['hasFile'] == true;

  switch (serviceType) {
    case ServiceType.movies:
      if (!hasFile &&
          (normalizedStatus == 'released' || normalizedStatus == 'incinemas')) {
        return 'Movie missing from disk';
      }
      if (normalizedStatus == 'announced') {
        return 'Movie not available yet';
      }
      return normalizedStatus == null
          ? null
          : humanizeCamelCase(normalizedStatus);
    case ServiceType.series:
      if (!hasFile) {
        return 'Episode missing from disk';
      }
      return normalizedStatus == null
          ? null
          : humanizeCamelCase(normalizedStatus);
    case ServiceType.music:
      final statistics = asActivityMap(item['statistics']);
      final trackFileCount = intOrNull(statistics?['trackFileCount']) ?? 0;
      if (!hasFile || trackFileCount == 0) {
        return 'Album missing from disk';
      }
      return normalizedStatus == null
          ? null
          : humanizeCamelCase(normalizedStatus);
    case ServiceType.discover:
      return null;
  }
}

String formatActivityValue(dynamic value) {
  if (value == null) return '—';
  if (value is bool) return value ? 'Yes' : 'No';

  if (value is num || value is String) {
    final text = value.toString().trim();
    return text.isEmpty ? '—' : text;
  }

  if (value is List) {
    if (value.isEmpty) return '—';
    return value.map(formatActivityValue).join(', ');
  }

  if (value is Map) {
    if (value.isEmpty) return '—';

    return value.entries
        .where((entry) => entry.value != null)
        .map(
          (entry) =>
              '${humanizeCamelCase(entry.key.toString())}: ${formatActivityValue(entry.value)}',
        )
        .join(' • ');
  }

  return value.toString();
}

List<String> extractStatusMessages(dynamic rawMessages) {
  if (rawMessages is! List || rawMessages.isEmpty) return const [];

  final messages = <String>[];
  for (final entry in rawMessages) {
    final map = asActivityMap(entry);
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

String? extractQualityName(Map<String, dynamic> item, {String? fileKey}) {
  final source = fileKey == null ? item : asActivityMap(item[fileKey]);
  final quality = asActivityMap(source?['quality']);
  final nestedQuality = asActivityMap(quality?['quality']);
  return stringOrNull(nestedQuality?['name'] ?? quality?['name']);
}

String? formatEpisodeCode(int? seasonNumber, int? episodeNumber) {
  if (seasonNumber == null && episodeNumber == null) return null;

  final season = (seasonNumber ?? 0).toString().padLeft(2, '0');
  final episode = (episodeNumber ?? 0).toString().padLeft(2, '0');
  return 'S${season}E${episode}';
}
