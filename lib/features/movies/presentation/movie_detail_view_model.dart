import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/utils/string_utils.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';

class MovieDetailViewModel {
  final String title;
  final String overview;
  final String posterUrl;
  final Map<String, String>? posterHeaders;
  final String? backdropUrl;
  final String status;
  final bool hasFile;
  final String year;
  final String? runtimeStr;
  final String? studio;
  final List<String> genres;
  final List<RatingSource> ratings;
  final String? path;
  final String? filename;
  final int? qualityProfileId;
  final int movieId;
  final String? certification;
  final String? originalLanguage;
  final String? inCinemas;
  final String? digitalRelease;
  final String? physicalRelease;

  const MovieDetailViewModel({
    required this.title,
    required this.overview,
    required this.posterUrl,
    this.posterHeaders,
    this.backdropUrl,
    required this.status,
    required this.hasFile,
    required this.year,
    this.runtimeStr,
    this.studio,
    required this.genres,
    required this.ratings,
    this.path,
    this.filename,
    this.qualityProfileId,
    required this.movieId,
    this.certification,
    this.originalLanguage,
    this.inCinemas,
    this.digitalRelease,
    this.physicalRelease,
  });

  List<String> get metadataItems => [
    year,
    if (runtimeStr != null) runtimeStr!,
  ].where((item) => item.isNotEmpty).toList(growable: false);

  List<MediaInfoGroup> buildInfoGroups() {
    final releaseFacts = <MediaFact>[
      if (inCinemas != null && inCinemas!.isNotEmpty)
        MediaFact('In Cinemas', formatIsoDate(inCinemas!)),
      if (digitalRelease != null && digitalRelease!.isNotEmpty)
        MediaFact('Digital', formatIsoDate(digitalRelease!)),
      if (physicalRelease != null && physicalRelease!.isNotEmpty)
        MediaFact('Physical', formatIsoDate(physicalRelease!)),
    ];

    return [
      if (certification != null && certification!.isNotEmpty)
        MediaInfoGroup(title: 'Certification', child: Text(certification!)),
      if (originalLanguage != null && originalLanguage!.isNotEmpty)
        MediaInfoGroup(
          title: 'Original Language',
          child: Text(originalLanguage!),
        ),
      if (releaseFacts.isNotEmpty)
        MediaInfoGroup(
          title: 'Release Dates',
          child: MediaFactsList(facts: releaseFacts),
        ),
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
      if (studio != null && studio!.isNotEmpty)
        MediaInfoGroup(title: 'Studio', child: Text(studio!)),
    ];
  }

  factory MovieDetailViewModel.fromMovie(
    RadarrMovie movie, {
    required String baseUrl,
    required String apiKey,
  }) {
    final posterSource = ImageUtils.extractPosterUrl(
      movie.images,
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
    final backdropSource = ImageUtils.extractPosterUrl(
      movie.images,
      baseUrl: baseUrl,
      apiKey: apiKey,
      coverTypes: const ['fanart'],
    );
    final path = movie.path;

    return MovieDetailViewModel(
      title: movie.title,
      overview: movie.overview?.trim().isNotEmpty == true
          ? movie.overview!.trim()
          : 'No description available.',
      posterUrl: posterSource.url,
      posterHeaders: posterSource.headers,
      backdropUrl: ImageUtils.safeBackdropUrl(backdropSource),
      status: movie.status,
      hasFile: movie.hasFile,
      year: movie.year > 0 ? movie.year.toString() : '',
      runtimeStr: movie.runtime > 0 ? '${movie.runtime} min' : null,
      studio: movie.studio,
      genres: movie.genres,
      ratings: movie.ratings,
      path: path,
      filename: movie.hasFile && path != null
          ? path.split(RegExp(r'[\\/]')).last
          : null,
      qualityProfileId: movie.qualityProfileId,
      movieId: movie.id,
      certification: movie.certification,
      originalLanguage: movie.originalLanguage?['name'] as String?,
      inCinemas: movie.inCinemas,
      digitalRelease: movie.digitalRelease,
      physicalRelease: movie.physicalRelease,
    );
  }
}
