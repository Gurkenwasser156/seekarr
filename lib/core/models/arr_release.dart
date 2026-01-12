/// Model representing a release from *Arr APIs (Radarr/Sonarr/Lidarr).
///
/// This provides type-safe access to release data used in Interactive Search.
/// All fields handle null/missing values gracefully with sensible defaults.
class ArrRelease {
  final String title;
  final String indexer;
  final int indexerId;
  final String guid;
  final int size;
  final int seeders;
  final int leechers;
  final int ageMinutes;
  final int customFormatScore;
  final List<CustomFormat> customFormats;
  final List<String> rejections;
  final String qualityName;
  final bool approved;

  const ArrRelease({
    required this.title,
    required this.indexer,
    required this.indexerId,
    required this.guid,
    required this.size,
    required this.seeders,
    required this.leechers,
    required this.ageMinutes,
    required this.customFormatScore,
    required this.customFormats,
    required this.rejections,
    required this.qualityName,
    required this.approved,
  });

  /// Creates an ArrRelease from JSON response.
  ///
  /// Handles both Radarr/Sonarr v3 API and Lidarr v1 API formats.
  factory ArrRelease.fromJson(Map<String, dynamic> json) {
    return ArrRelease(
      title: json['title'] as String? ?? 'Unknown',
      indexer: json['indexer'] as String? ?? 'Unknown',
      indexerId: (json['indexerId'] as num?)?.toInt() ?? 0,
      guid: json['guid'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      seeders: (json['seeders'] as num?)?.toInt() ?? 0,
      leechers: (json['leechers'] as num?)?.toInt() ?? 0,
      ageMinutes: (json['ageMinutes'] as num?)?.toInt() ?? 0,
      customFormatScore: (json['customFormatScore'] as num?)?.toInt() ?? 0,
      customFormats: _parseCustomFormats(json['customFormats']),
      rejections: _parseRejections(json['rejections']),
      qualityName: _parseQualityName(json['quality']),
      approved: json['approved'] as bool? ?? false,
    );
  }

  /// Parses custom formats from API response.
  static List<CustomFormat> _parseCustomFormats(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw
        .map((e) => CustomFormat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Parses rejections which can be either strings or objects with 'reason' field.
  static List<String> _parseRejections(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw.map((e) {
      if (e is String) return e;
      if (e is Map) return e['reason']?.toString() ?? 'Unknown reason';
      return e.toString();
    }).toList();
  }

  /// Parses quality name from nested quality object.
  static String _parseQualityName(dynamic quality) {
    if (quality == null) return '';
    if (quality is! Map) return '';
    final innerQuality = quality['quality'];
    if (innerQuality == null) return '';
    if (innerQuality is! Map) return '';
    return innerQuality['name'] as String? ?? '';
  }

  /// Whether this release has any rejections.
  bool get isRejected => rejections.isNotEmpty;

  /// Converts back to a Map for compatibility with existing code.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'indexer': indexer,
      'indexerId': indexerId,
      'guid': guid,
      'size': size,
      'seeders': seeders,
      'leechers': leechers,
      'ageMinutes': ageMinutes,
      'customFormatScore': customFormatScore,
      'customFormats': customFormats.map((cf) => cf.toJson()).toList(),
      'rejections': rejections,
      'quality': {
        'quality': {'name': qualityName},
      },
      'approved': approved,
    };
  }

  @override
  String toString() =>
      'ArrRelease(title: $title, indexer: $indexer, size: $size)';
}

/// Model representing a custom format with name and score.
class CustomFormat {
  final String name;
  final int score;

  const CustomFormat({required this.name, required this.score});

  factory CustomFormat.fromJson(Map<String, dynamic> json) {
    return CustomFormat(
      name: json['name'] as String? ?? 'Unknown',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'score': score};
  }
}
