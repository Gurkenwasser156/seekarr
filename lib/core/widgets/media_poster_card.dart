import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';

/// A reusable poster card for media detail screens.
///
/// Consolidates the previously duplicated poster card widgets
/// (`_MoviePosterCard`, `_SeriesPosterCard`, `_MusicPosterCard`,
/// `_DiscoverPosterCard`) into a single shared component.
///
/// The card fills its parent constraints — wrap in a [SizedBox] to
/// control dimensions externally (e.g. from [MediaDetailPosterRow]).
class MediaPosterCard extends StatelessWidget {
  final String heroTag;
  final String? imageUrl;
  final Map<String, String>? imageHeaders;
  final IconData fallbackIcon;

  const MediaPosterCard({
    super.key,
    required this.heroTag,
    this.imageUrl,
    this.imageHeaders,
    this.fallbackIcon = Icons.movie_outlined,
  });

  static const _shadowAlpha = 0.4;
  static const _shadowBlur = 16.0;
  static const _shadowSpread = 4.0;
  static const _fallbackIconSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Hero(
      tag: heroTag,
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderRadiusMd,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: _shadowAlpha),
                blurRadius: _shadowBlur,
                spreadRadius: _shadowSpread,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.borderRadiusMd,
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    httpHeaders: imageHeaders,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        Container(color: colorScheme.surfaceContainer),
                  )
                : Container(
                    color: colorScheme.surfaceContainer,
                    child: Center(
                      child: Icon(
                        fallbackIcon,
                        size: _fallbackIconSize,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
