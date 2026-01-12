import 'package:flutter/material.dart';

/// Sort options for releases in Interactive Search.
enum ReleaseSortType {
  score('CF Score', Icons.star_rounded),
  size('Size', Icons.storage_rounded),
  seeders('Seeders', Icons.arrow_upward_rounded),
  age('Age', Icons.schedule_rounded);

  final String label;
  final IconData icon;
  const ReleaseSortType(this.label, this.icon);
}

/// Pure function that filters and sorts releases.
///
/// This function is extracted from InteractiveSearchSheet to enable
/// unit testing without widget context.
///
/// Parameters:
/// - [releases]: List of release maps from *Arr APIs
/// - [sortType]: The field to sort by
/// - [sortAscending]: Whether to reverse the default sort order
/// - [hideRejected]: Whether to filter out releases with rejections
/// - [selectedIndexer]: Optional indexer name to filter by
///
/// Returns a new filtered and sorted list (does not modify the original).
List<dynamic> filterAndSortReleases(
  List<dynamic> releases, {
  required ReleaseSortType sortType,
  required bool sortAscending,
  required bool hideRejected,
  String? selectedIndexer,
}) {
  var result = List<dynamic>.from(releases);

  // Apply filters
  if (hideRejected) {
    result = result.where((r) {
      final rejections = r['rejections'] as List<dynamic>? ?? [];
      return rejections.isEmpty;
    }).toList();
  }

  if (selectedIndexer != null) {
    result = result.where((r) {
      return r['indexer'] == selectedIndexer;
    }).toList();
  }

  // Apply sorting
  result.sort((a, b) {
    int comparison;
    switch (sortType) {
      case ReleaseSortType.score:
        final aScore = (a['customFormatScore'] as num?)?.toInt() ?? 0;
        final bScore = (b['customFormatScore'] as num?)?.toInt() ?? 0;
        comparison = bScore.compareTo(aScore); // Default desc for score
      case ReleaseSortType.size:
        final aSize = (a['size'] as num?)?.toInt() ?? 0;
        final bSize = (b['size'] as num?)?.toInt() ?? 0;
        comparison = bSize.compareTo(aSize); // Default desc for size
      case ReleaseSortType.seeders:
        final aSeeders = (a['seeders'] as num?)?.toInt() ?? 0;
        final bSeeders = (b['seeders'] as num?)?.toInt() ?? 0;
        comparison = bSeeders.compareTo(aSeeders); // Default desc
      case ReleaseSortType.age:
        final aAge = (a['ageMinutes'] as num?)?.toInt() ?? 0;
        final bAge = (b['ageMinutes'] as num?)?.toInt() ?? 0;
        comparison = aAge.compareTo(bAge); // Default asc (newest first)
    }
    return sortAscending ? -comparison : comparison;
  });

  return result;
}

/// Extracts unique indexer names from a list of releases.
///
/// Returns a Set of indexer names. Null or missing indexers are
/// replaced with 'Unknown'.
Set<String> extractAvailableIndexers(List<dynamic> releases) {
  return releases.map((r) => r['indexer'] as String? ?? 'Unknown').toSet();
}

/// Formats a byte size into a human-readable string.
///
/// Examples:
/// - 512 -> "512 B"
/// - 1024 -> "1.0 KB"
/// - 1073741824 -> "1.00 GB"
String formatReleaseSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Formats age in minutes into a human-readable string.
///
/// Examples:
/// - 30 -> "30m"
/// - 120 -> "2h"
/// - 2880 -> "2d"
String formatReleaseAge(int minutes) {
  if (minutes < 60) return '${minutes}m';
  if (minutes < 1440) return '${(minutes / 60).round()}h';
  return '${(minutes / 1440).round()}d';
}
