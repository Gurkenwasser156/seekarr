import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';

/// A reusable view for displaying media details with hero poster,
/// and sliver-based scrollable content.
///
/// Follows Material Design 3 styling with proper color tokens.
class MediaDetailView extends StatelessWidget {
  final String heroTag;
  final String? posterUrl;
  final Map<String, String>? posterHeaders;

  /// Optional backdrop image shown in the expanded header.
  final String? backdropUrl;

  /// Optional overlay shown above the backdrop header while expanded.
  ///
  /// This is only used when [backdropUrl] is also provided.
  final Widget? posterOverlay;
  final List<Widget> contentSections;
  final List<Widget> slivers;
  final Widget? background;

  const MediaDetailView({
    super.key,
    required this.heroTag,
    required this.contentSections,
    this.posterUrl,
    this.posterHeaders,
    this.backdropUrl,
    this.posterOverlay,
    this.slivers = const [],
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasBackdrop = backdropUrl != null && backdropUrl!.isNotEmpty;
    final usesBackdropOverlay = hasBackdrop && posterOverlay != null;
    final expandedHeight = hasBackdrop ? 380.0 : 500.0;
    final scrollBottomPadding =
        FloatingNavBarMetrics.getScrollViewBottomPadding(context);

    return Material(
      color: colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            pinned: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: usesBackdropOverlay
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final overlayOpacity = mediaDetailOverlayCollapseOpacity(
                        context,
                        currentHeight: constraints.maxHeight,
                        expandedHeight: expandedHeight,
                      );

                      return ClipRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _BackdropHeader(
                              backdropUrl: backdropUrl!,
                              surfaceColor: colorScheme.surface,
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xl,
                                ),
                                child: Opacity(
                                  opacity: overlayOpacity,
                                  child: posterOverlay!,
                                ),
                              ),
                            ),
                            if (background != null) background!,
                          ],
                        ),
                      );
                    },
                  )
                : FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasBackdrop)
                          _BackdropHeader(
                            backdropUrl: backdropUrl!,
                            surfaceColor: colorScheme.surface,
                          )
                        else
                          Hero(
                            tag: heroTag,
                            child: Material(
                              type: MaterialType.transparency,
                              child: posterUrl != null && posterUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: posterUrl!,
                                      httpHeaders: posterHeaders,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          Container(
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
                  ...contentSections,
                  if (slivers.isEmpty) SizedBox(height: scrollBottomPadding),
                ],
              ),
            ),
          ),

          ...slivers,

          if (slivers.isNotEmpty)
            SliverToBoxAdapter(child: SizedBox(height: scrollBottomPadding)),
        ],
      ),
    );
  }
}

class MediaDetailTitleSection extends StatelessWidget {
  final String title;
  final TextAlign textAlign;

  const MediaDetailTitleSection({
    super.key,
    required this.title,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        textAlign: textAlign,
      ),
    );
  }
}

class MediaDetailTagSection extends StatelessWidget {
  final List<Widget> tags;
  final WrapAlignment alignment;

  const MediaDetailTagSection({
    super.key,
    required this.tags,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: alignment,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: tags,
      ),
    );
  }
}

class MediaDetailOverviewSection extends StatelessWidget {
  final String overview;
  final String heading;

  const MediaDetailOverviewSection({
    super.key,
    required this.overview,
    this.heading = 'Overview',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (overview.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
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
          textAlign: TextAlign.start,
        ),
      ],
    );
  }
}

double mediaDetailOverlayCollapseOpacity(
  BuildContext context, {
  required double currentHeight,
  required double expandedHeight,
}) {
  final collapsedHeight = kToolbarHeight + MediaQuery.paddingOf(context).top;
  final availableHeight = expandedHeight - collapsedHeight;
  if (availableHeight <= 0) {
    return 0;
  }

  final progress = ((currentHeight - collapsedHeight) / availableHeight).clamp(
    0.0,
    1.0,
  );
  return Curves.easeOut.transform(progress);
}

class _BackdropHeader extends StatelessWidget {
  final String backdropUrl;
  final Color surfaceColor;

  const _BackdropHeader({
    required this.backdropUrl,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: backdropUrl,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) =>
              Container(color: Theme.of(context).colorScheme.surfaceContainer),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                surfaceColor.withValues(alpha: 0.6),
                surfaceColor,
              ],
              stops: const [0.2, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
