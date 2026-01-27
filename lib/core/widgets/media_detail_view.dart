import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';

/// A reusable view for displaying media details with hero poster,
/// and sliver-based scrollable content.
///
/// Follows Material Design 3 styling with proper color tokens.
class MediaDetailView extends StatelessWidget {
  final String title;
  final String heroTag;
  final String? posterUrl;
  final Widget? actions;
  final List<Widget> tags;
  final String overview;
  final List<Widget> slivers;
  final Widget? background;

  const MediaDetailView({
    super.key,
    required this.title,
    required this.heroTag,
    this.posterUrl,
    this.actions,
    this.tags = const [],
    required this.overview,
    this.slivers = const [],
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero poster image
                  Hero(
                    tag: heroTag,
                    child: Material(
                      type: MaterialType.transparency,
                      child: posterUrl != null && posterUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: posterUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: colorScheme.surfaceContainer,
                              ),
                            )
                          : Container(
                              color: colorScheme.surfaceContainer,
                              child: Icon(
                                Icons.movie_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  if (background != null) background!,
                ],
              ),
            ),
          ),

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Tags (genres, year, etc.)
                  if (tags.isNotEmpty) ...[
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: tags,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Actions (buttons)
                  if (actions != null) ...[
                    actions!,
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Overview section
                  if (overview.isNotEmpty) ...[
                    Text(
                      'Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      overview,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  // Bottom padding if no extra slivers
                  if (slivers.isEmpty)
                    SizedBox(
                      height: FloatingNavBarMetrics.getScrollViewBottomPadding(
                        context,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Additional slivers
          ...slivers,

          if (slivers.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: FloatingNavBarMetrics.getScrollViewBottomPadding(
                  context,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
