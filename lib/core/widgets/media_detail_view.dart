import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/core/widgets/media_detail_poster_row.dart';
import 'package:seekarr/core/widgets/shimmer_placeholder.dart';

/// A reusable view for displaying media details with hero poster,
/// backdrop parallax, and sliver-based scrollable content.
///
/// The [posterRow] builder receives a `collapseFactor` (0.0 = expanded,
/// 1.0 = collapsed) and should return a [MediaDetailPosterRow] that
/// stays pinned when the user scrolls.
class MediaDetailView extends StatelessWidget {
  final String heroTag;
  final String? posterUrl;
  final Map<String, String>? posterHeaders;

  /// Optional backdrop image shown in the expanded header.
  final String? backdropUrl;

  /// Builder for the poster row that stays pinned on scroll.
  ///
  /// Receives a `collapseFactor` from 0.0 (fully expanded) to 1.0
  /// (fully collapsed) for smooth interpolation of sizes.
  final Widget Function(double collapseFactor)? posterRow;

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
    this.posterRow,
    this.slivers = const [],
    this.background,
  });

  /// Height of the SliverAppBar when fully collapsed.
  ///
  /// Must accommodate: toolbar (kToolbarHeight) + collapsed poster row
  /// + vertical padding.
  static const collapsedHeight =
      kToolbarHeight +
      MediaDetailPosterRow.collapsedHeight +
      AppSpacing.sm +
      AppSpacing.lg;

  /// Height of the SliverAppBar when fully expanded.
  static const expandedHeight = 380.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPosterRow = posterRow != null;
    final hasBackdrop = backdropUrl != null && backdropUrl!.isNotEmpty;
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
            collapsedHeight: hasPosterRow ? collapsedHeight : null,
            flexibleSpace: hasPosterRow
                ? _PinnedPosterRowFlexibleSpace(
                    backdropUrl: hasBackdrop ? backdropUrl : null,
                    posterRow: posterRow!,
                    background: background,
                    surfaceColor: colorScheme.surface,
                    collapsedHeight: collapsedHeight,
                    expandedHeight: expandedHeight,
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

/// Internal widget that manages the flexible space with a pinned poster row.
///
/// Uses [LayoutBuilder] to calculate the collapse progress and positions
/// the backdrop (with parallax) behind the poster row.
class _PinnedPosterRowFlexibleSpace extends StatelessWidget {
  final String? backdropUrl;
  final Widget Function(double collapseFactor) posterRow;
  final Widget? background;
  final Color surfaceColor;
  final double collapsedHeight;
  final double expandedHeight;

  const _PinnedPosterRowFlexibleSpace({
    required this.posterRow,
    required this.surfaceColor,
    required this.collapsedHeight,
    required this.expandedHeight,
    this.backdropUrl,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final hasBackdrop = backdropUrl != null && backdropUrl!.isNotEmpty;
    final topPadding = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = collapsedHeight + topPadding;
        final maxHeight = expandedHeight + topPadding;
        final range = maxHeight - minHeight;

        final collapseFactor = range > 0
            ? (1.0 - ((constraints.maxHeight - minHeight) / range)).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Backdrop or gradient background
              if (hasBackdrop)
                _BackdropHeader(
                  backdropUrl: backdropUrl!,
                  surfaceColor: surfaceColor,
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        surfaceColor,
                      ],
                    ),
                  ),
                ),

              if (background != null) background!,

              // Smooth transition overlay at the bottom edge
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: AppSpacing.xxl,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [surfaceColor.withValues(alpha: 0), surfaceColor],
                    ),
                  ),
                ),
              ),

              // Poster row — pinned at bottom
              Positioned(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.lg,
                child: posterRow(collapseFactor),
              ),
            ],
          ),
        );
      },
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

/// Shared loading-state flexible space for detail screen shimmer skeletons.
///
/// Encapsulates the LayoutBuilder + gradient + [MediaDetailPosterRow]
/// pattern used identically in all four detail-screen loading states.
///
/// Provide a custom [posterCard] widget (e.g. a [MediaPosterCard] with
/// an initial URL for hero animation) or leave `null` for the default
/// [ShimmerPlaceholder.card].
class MediaDetailLoadingHeader extends StatelessWidget {
  final Widget? posterCard;

  const MediaDetailLoadingHeader({super.key, this.posterCard});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = MediaDetailView.collapsedHeight + topPadding;
        final maxHeight = MediaDetailView.expandedHeight + topPadding;
        final range = maxHeight - minHeight;
        final collapseFactor = range > 0
            ? (1.0 - ((constraints.maxHeight - minHeight) / range)).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surfaceContainerHighest,
                      colorScheme.surface,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.lg,
                child: MediaDetailPosterRow(
                  collapseFactor: collapseFactor,
                  posterCard:
                      posterCard ??
                      ShimmerPlaceholder.card(
                        height: MediaDetailPosterRow.expandedHeight,
                      ),
                  statusBadge: ShimmerPlaceholder(
                    width: 96,
                    height: 28,
                    borderRadius: AppRadius.borderRadiusLg,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
