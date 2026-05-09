import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/media_metadata_line.dart';

class MediaDetailHeroSummaryCard extends StatelessWidget {
  final String title;
  final List<String> metadataItems;
  final List<Widget> tags;

  const MediaDetailHeroSummaryCard({
    super.key,
    required this.title,
    this.metadataItems = const [],
    this.tags = const [],
  });

  @override
  Widget build(BuildContext context) {
    return MediaDetailHeroSummary(
      title: title,
      metadataItems: metadataItems,
      tags: tags,
    );
  }
}

class MediaDetailHeroSummary extends StatelessWidget {
  final String title;
  final List<String> metadataItems;
  final List<Widget> tags;

  const MediaDetailHeroSummary({
    super.key,
    required this.title,
    this.metadataItems = const [],
    this.tags = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMetadata = metadataItems.any((item) => item.trim().isNotEmpty);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.3,
            ),
          ),
          if (hasMetadata) ...[
            const SizedBox(height: AppSpacing.xs),
            MediaMetadataLine(items: metadataItems, maxLines: 1),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: tags,
            ),
          ],
        ],
      ),
    );
  }
}
