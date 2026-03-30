import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/utils/string_utils.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';

class MusicDetailViewModel {
  final String title;
  final String overview;
  final String posterUrl;
  final Map<String, String>? posterHeaders;
  final String? backdropUrl;
  final String status;
  final bool hasFiles;
  final List<String> genres;
  final List<RatingSource> ratings;
  final int? qualityProfileId;
  final int artistId;
  final int albumCount;
  final int trackCount;
  final String? artistType;
  final String? disambiguation;
  final String? path;

  const MusicDetailViewModel({
    required this.title,
    required this.overview,
    required this.posterUrl,
    this.posterHeaders,
    this.backdropUrl,
    required this.status,
    required this.hasFiles,
    required this.genres,
    required this.ratings,
    this.qualityProfileId,
    required this.artistId,
    required this.albumCount,
    required this.trackCount,
    this.artistType,
    this.disambiguation,
    this.path,
  });

  List<String> get metadataItems => [
    if (albumCount > 0) '$albumCount ${albumCount == 1 ? 'Album' : 'Albums'}',
    if (trackCount > 0) '$trackCount ${trackCount == 1 ? 'Track' : 'Tracks'}',
  ];

  List<MediaInfoGroup> buildInfoGroups() {
    return [
      if (artistType != null && artistType!.isNotEmpty)
        MediaInfoGroup(
          title: 'Artist Type',
          child: Text(capitalizeFirst(artistType!)),
        ),
      if (disambiguation != null && disambiguation!.isNotEmpty)
        MediaInfoGroup(title: 'Disambiguation', child: Text(disambiguation!)),
      if (genres.isNotEmpty)
        MediaInfoGroup(
          title: 'Genre',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: genres
                .map((genre) => GenreChip(genre: genre))
                .toList(growable: false),
          ),
        ),
      if (path != null && path!.isNotEmpty)
        MediaInfoGroup(title: 'Library Path', child: Text(path!)),
    ];
  }

  factory MusicDetailViewModel.fromArtist(
    LidarrArtist artist, {
    required String baseUrl,
    required String apiKey,
  }) {
    final posterSource = ImageUtils.extractPosterUrl(
      artist.images,
      baseUrl: baseUrl,
      apiKey: apiKey,
      coverTypes: const ['poster', 'fanart', 'banner', 'logo'],
    );
    final backdropSource = ImageUtils.extractPosterUrl(
      artist.images,
      baseUrl: baseUrl,
      apiKey: apiKey,
      coverTypes: const ['fanart'],
    );
    final stats = artist.statistics;

    return MusicDetailViewModel(
      title: artist.artistName,
      overview: artist.overview?.trim().isNotEmpty == true
          ? artist.overview!.trim()
          : 'No description available.',
      posterUrl: posterSource.url,
      posterHeaders: posterSource.headers,
      backdropUrl: ImageUtils.safeBackdropUrl(backdropSource),
      status: artist.status,
      hasFiles: ((stats?['trackFileCount'] as num?)?.toInt() ?? 0) > 0,
      genres: artist.genres,
      ratings: artist.ratings,
      qualityProfileId: artist.qualityProfileId,
      artistId: artist.id,
      albumCount: (stats?['albumCount'] as num?)?.toInt() ?? 0,
      trackCount: (stats?['trackCount'] as num?)?.toInt() ?? 0,
      artistType: artist.artistType,
      disambiguation: artist.disambiguation,
      path: artist.path,
    );
  }
}
