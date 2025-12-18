import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A card widget for displaying media content with cached images.
/// Designed to work seamlessly with Hero transitions.
class ContentCard extends StatelessWidget {
  final String? imageUrl;

  /// Optional badge widget to display in the corner (e.g., status badge).
  final Widget? badge;

  const ContentCard({super.key, required this.imageUrl, this.badge});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) {
                      return Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.movie, color: Colors.white54),
                  ),
            // Badge overlay
            if (badge != null) Positioned(top: 4, right: 4, child: badge!),
          ],
        ),
      ),
    );
  }
}
