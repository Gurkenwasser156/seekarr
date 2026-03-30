class SonarrEpisode {
  final int id;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final bool hasFile;
  final bool monitored;

  const SonarrEpisode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.hasFile,
    required this.monitored,
  });

  factory SonarrEpisode.fromJson(Map<String, dynamic> json) {
    final episodeNumber = (json['episodeNumber'] as num?)?.toInt() ?? 0;

    return SonarrEpisode(
      id: (json['id'] as num?)?.toInt() ?? 0,
      seasonNumber: (json['seasonNumber'] as num?)?.toInt() ?? 0,
      episodeNumber: episodeNumber,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Episode ${episodeNumber == 0 ? '?' : episodeNumber}',
      hasFile: json['hasFile'] as bool? ?? false,
      monitored: json['monitored'] as bool? ?? false,
    );
  }
}
