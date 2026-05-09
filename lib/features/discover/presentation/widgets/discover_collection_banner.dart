import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/widgets/media_detail_view.dart';
import 'package:seekarr/features/discover/domain/models/discover_detail_model.dart';

class DiscoverCollectionBanner extends StatelessWidget {
  final CollectionInfo collection;

  const DiscoverCollectionBanner({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backdropUrl = ImageUtils.buildTmdbPosterUrl(
      collection.backdropPath,
      size: 'w780',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MediaDetailSectionHeader(title: 'Collection'),
          ClipRRect(
            borderRadius: AppRadius.borderRadiusMd,
            child: SizedBox(
              height: 82,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (backdropUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: backdropUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          Container(color: colorScheme.surfaceContainerHigh),
                    )
                  else
                    Container(color: colorScheme.surfaceContainerHigh),
                  Container(color: Colors.black.withValues(alpha: 0.58)),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Part of ${collection.name}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
