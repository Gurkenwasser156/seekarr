import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/widgets/content_card.dart';
import 'package:seekarr/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';

/// Callback signature for when a media item is tapped.
typedef OnMediaItemTap<T> = void Function(T item, String heroTag);

/// Callback signature for extracting status from a media item.
typedef StatusExtractor<T> = ({bool hasFile, String status})? Function(T item);

/// A reusable grid widget for displaying media items (movies, series, music).
///
/// This widget provides a consistent 3-column grid layout with poster images,
/// status badges, and Hero transition support. Following Material Design 3.
class MediaGrid<T> extends StatelessWidget {
  /// The list of media items to display.
  final List<T> items;

  /// Extracts the images list from an item for poster URL resolution.
  final List<dynamic>? Function(T item) imagesExtractor;

  /// Extracts a unique ID from an item for Hero tags.
  final int Function(T item) idExtractor;

  /// Optional: Extracts status info for badge display.
  final StatusExtractor<T>? statusExtractor;

  /// Base URL for authenticated image URLs.
  final String baseUrl;

  /// API key for authenticated image URLs.
  final String apiKey;

  /// Prefix for Hero tags (e.g., 'movie', 'series', 'artist').
  final String heroTagPrefix;

  /// Callback when an item is tapped.
  final OnMediaItemTap<T>? onItemTap;

  /// Cover types to search for in images.
  final List<String> coverTypes;

  /// Scroll physics. Use AlwaysScrollableScrollPhysics for RefreshIndicator.
  final ScrollPhysics? physics;

  /// Number of columns in the grid
  final int crossAxisCount;

  const MediaGrid({
    super.key,
    required this.items,
    required this.imagesExtractor,
    required this.idExtractor,
    this.statusExtractor,
    required this.baseUrl,
    required this.apiKey,
    required this.heroTagPrefix,
    this.onItemTap,
    this.coverTypes = const ['poster', 'cover'],
    this.physics,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No items found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: AppSpacing.gridGap,
        mainAxisSpacing: AppSpacing.gridGap,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final images = imagesExtractor(item);
        final itemId = idExtractor(item);

        final imageUrl = ImageUtils.extractPosterUrl(
          images,
          baseUrl: baseUrl,
          apiKey: apiKey,
          coverTypes: coverTypes,
        );

        // Include index to ensure uniqueness for search results where id may be 0
        final heroTag = '${heroTagPrefix}_${itemId}_$index';

        // Extract status for badge
        Widget? badge;
        if (statusExtractor != null) {
          final statusInfo = statusExtractor!(item);
          if (statusInfo != null) {
            badge = StatusBadge.fromMedia(
              hasFile: statusInfo.hasFile,
              status: statusInfo.status,
              compact: true,
            );
          }
        }

        return GestureDetector(
          onTap: onItemTap != null ? () => onItemTap!(item, heroTag) : null,
          child: Hero(
            tag: heroTag,
            child: ContentCard(imageUrl: imageUrl, badge: badge),
          ),
        );
      },
    );
  }
}
