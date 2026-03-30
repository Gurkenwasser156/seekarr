class LidarrTrack {
  final int id;
  final int? mediumNumber;
  final dynamic trackNumber;
  final String title;
  final bool hasFile;
  final int duration;

  const LidarrTrack({
    required this.id,
    this.mediumNumber,
    this.trackNumber,
    required this.title,
    required this.hasFile,
    required this.duration,
  });

  String get formattedDuration {
    final seconds = (duration / 1000).round();
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  int get sortableTrackNumber {
    if (trackNumber == null) {
      return 0;
    }

    if (trackNumber is num) {
      return (trackNumber as num).toInt();
    }

    if (trackNumber is String) {
      final rawValue = trackNumber as String;
      final parsed = int.tryParse(rawValue);
      if (parsed != null) {
        return parsed;
      }

      final match = RegExp(r'\d+').firstMatch(rawValue);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 0;
      }
    }

    return 0;
  }

  String get displayTrackNumber => trackNumber?.toString() ?? '?';

  factory LidarrTrack.fromJson(Map<String, dynamic> json) {
    final trackNumber = json['trackNumber'];

    return LidarrTrack(
      id: (json['id'] as num?)?.toInt() ?? 0,
      mediumNumber: (json['mediumNumber'] as num?)?.toInt(),
      trackNumber: trackNumber,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Track ${trackNumber ?? '?'}',
      hasFile: json['hasFile'] as bool? ?? false,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }
}
