import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_view_model.dart';

class DiscoverCastList extends StatelessWidget {
  final List<DiscoverCastMember> cast;

  const DiscoverCastList({super.key, required this.cast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: cast.length,
        itemBuilder: (context, index) {
          final member = cast[index];
          final name = member.name;
          final character = member.character;
          final profilePath = member.profilePath;
          final imageUrl = profilePath != null && profilePath.isNotEmpty
              ? 'https://image.tmdb.org/t/p/w185$profilePath'
              : null;

          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.surfaceContainer,
                  backgroundImage: imageUrl != null
                      ? CachedNetworkImageProvider(imageUrl)
                      : null,
                  child: imageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  character,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
