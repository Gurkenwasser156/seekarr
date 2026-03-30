import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_extras_provider.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_view_model.dart';
import 'package:seekarr/features/discover/presentation/discover_details_provider.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_action_buttons.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_cast_list.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_collection_banner.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_release_facts.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_seasons_list.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_videos_button.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_watch_providers.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';

class DiscoverDetailScreen extends ConsumerWidget {
  final int mediaId;
  final String mediaType;
  final String heroTag;
  final String? initialPosterUrl;

  const DiscoverDetailScreen({
    super.key,
    required this.mediaId,
    required this.mediaType,
    required this.heroTag,
    this.initialPosterUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final normalizedMediaType = mediaType == 'movie' ? 'movie' : 'tv';
    final region = ref.watch(regionProvider);
    final detailsAsync = ref.watch(
      discoverDetailProvider((id: mediaId, type: normalizedMediaType)),
    );

    return detailsAsync.when(
      loading: () => _DiscoverDetailLoadingState(
        heroTag: heroTag,
        initialPosterUrl: initialPosterUrl,
      ),
      error: (error, stackTrace) => _DiscoverDetailErrorState(error: error),
      data: (details) {
        final viewModel = DiscoverDetailViewModel.fromResponse(
          details,
          initialPosterUrl: initialPosterUrl,
        );
        final isMovie = normalizedMediaType == 'movie';
        final extrasAsync = ref.watch(
          discoverDetailExtrasProvider((
            mediaId: mediaId,
            mediaType: normalizedMediaType,
            tvdbId: viewModel.tvdbId,
            voteAverage: viewModel.voteAverage,
          )),
        );
        final extras =
            extrasAsync.asData?.value ??
            (isInLibrary: null, libraryCheckDone: false, lookupRatings: null);
        final hasBackdrop = (viewModel.backdropUrl ?? '').isNotEmpty;
        final statusColor = _statusColor(viewModel);
        final watchProviders = viewModel.watchProvidersForRegion(region);
        final contentRating = isMovie
            ? viewModel.movieContentRatingForRegion(region)
            : viewModel.tvContentRatingForRegion(region);
        final regionReleases = viewModel.releasesForRegion(region);
        final metadataLine = [
          viewModel.year,
          if (isMovie) viewModel.runtimeStr,
          if (!isMovie) viewModel.episodeSummary,
          if (!isMovie && viewModel.runtimeStr != null) viewModel.runtimeStr,
        ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
        final titleTextAlign = hasBackdrop ? TextAlign.center : TextAlign.start;
        final tagAlignment = hasBackdrop
            ? WrapAlignment.center
            : WrapAlignment.start;
        final sectionAlignment = hasBackdrop
            ? WrapAlignment.center
            : WrapAlignment.start;

        final isInService = extras.libraryCheckDone
            ? extras.isInLibrary ?? false
            : false;

        final tags = <Widget>[
          if (!hasBackdrop)
            TagChip(text: viewModel.jellyseerrStatus, color: statusColor),
          if (contentRating != null && contentRating.isNotEmpty)
            _CertificationChip(text: contentRating),
        ];
        final ratingWidgets = _buildRatingWidgets(
          viewModel,
          extras.lookupRatings,
        );
        final posterOverlay = hasBackdrop
            ? _DiscoverPosterOverlay(
                heroTag: heroTag,
                posterUrl: viewModel.posterUrl,
                statusText: viewModel.jellyseerrStatus,
                statusColor: statusColor,
              )
            : null;

        return MediaDetailView(
          heroTag: heroTag,
          posterUrl: viewModel.posterUrl,
          backdropUrl: viewModel.backdropUrl,
          posterOverlay: posterOverlay,
          contentSections: [
            MediaDetailTitleSection(
              title: viewModel.title,
              textAlign: titleTextAlign,
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              MediaDetailTagSection(tags: tags, alignment: tagAlignment),
            ],
            if (metadataLine.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: Text(
                  metadataLine,
                  textAlign: titleTextAlign,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (ratingWidgets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: sectionAlignment,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: ratingWidgets,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: DiscoverActionButtons(
                mediaId: mediaId,
                mediaType: normalizedMediaType,
                hasManageableMedia: viewModel.hasManageableMedia,
                isInService: isInService,
                isAvailable: viewModel.isAvailable,
                tvdbId: viewModel.tvdbId,
                mediaInfo: viewModel.mediaInfo,
                title: viewModel.title,
                voteAverage: viewModel.voteAverage,
                secondaryAction: viewModel.hasRelatedVideos
                    ? DiscoverVideosButton(videos: viewModel.playableVideos)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: isMovie
                  ? DiscoverReleaseInfoCard.movie(
                      releases: regionReleases,
                      region: region,
                      genresList: viewModel.genresList,
                      studios: viewModel.studios,
                      directors: viewModel.directors,
                      writers: viewModel.writers,
                    )
                  : DiscoverReleaseInfoCard.tv(
                      firstAirDate: viewModel.firstAirDate,
                      lastAirDate: viewModel.lastAirDate,
                      nextEpisodeToAir: viewModel.nextEpisodeToAir,
                      genresList: viewModel.genresList,
                      studios: viewModel.studios,
                      directors: viewModel.directors,
                      writers: viewModel.writers,
                      networks: viewModel.networks,
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: DiscoverWatchProviders(
                providers: watchProviders,
                region: region,
              ),
            ),
            if (viewModel.overview.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              MediaDetailOverviewSection(overview: viewModel.overview),
            ],
          ],
          slivers: [
            if (viewModel.keywords.isNotEmpty)
              SliverToBoxAdapter(
                child: _DiscoverKeywordsSection(keywords: viewModel.keywords),
              ),
            if (viewModel.cast.isNotEmpty)
              _DetailSectionSliver(
                child: Text('Cast', style: theme.textTheme.titleLarge),
              ),
            if (viewModel.cast.isNotEmpty)
              SliverToBoxAdapter(child: DiscoverCastList(cast: viewModel.cast)),
            if (viewModel.hasCollection)
              _DetailSectionSliver(
                child: DiscoverCollectionBanner(
                  collection: viewModel.collection!,
                ),
              ),
            if (viewModel.hasSeasons)
              _DetailSectionSliver(
                child: DiscoverSeasonsList(
                  seasons: viewModel.seasons,
                  mediaInfo: viewModel.mediaInfo,
                ),
              ),
          ],
        );
      },
    );
  }

  Color _statusColor(DiscoverDetailViewModel viewModel) {
    if (viewModel.isAvailable) {
      return AppColors.success;
    }

    if (viewModel.isPartiallyAvailable) {
      return AppColors.warning;
    }

    return AppColors.info;
  }

  List<Widget> _buildRatingWidgets(
    DiscoverDetailViewModel viewModel,
    List<DiscoverDetailRating>? lookupRatings,
  ) {
    if (lookupRatings != null) {
      return lookupRatings
          .map(
            (rating) => RatingChip(
              value: rating.value.toStringAsFixed(1),
              votes: rating.votes,
              sourceName: rating.name,
              sourceIcon: rating.icon,
            ),
          )
          .toList(growable: false);
    }

    if (viewModel.voteAverage == null) {
      return const [];
    }

    return [
      RatingChip(
        value: viewModel.voteAverage!.toStringAsFixed(1),
        votes: viewModel.voteCount ?? 0,
        sourceName: 'TMDB',
        sourceIcon: 'TMDB',
      ),
    ];
  }
}

class _DiscoverDetailLoadingState extends StatelessWidget {
  final String heroTag;
  final String? initialPosterUrl;

  const _DiscoverDetailLoadingState({
    required this.heroTag,
    required this.initialPosterUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const expandedHeight = 380.0;

    return Material(
      color: colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            pinned: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: LayoutBuilder(
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
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Opacity(
                            opacity: overlayOpacity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _DiscoverPosterCard(
                                  heroTag: heroTag,
                                  posterUrl: initialPosterUrl,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  height: 28,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: AppRadius.borderRadiusLg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    height: 32,
                    width: 200,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadius.borderRadiusSm,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    height: 16,
                    width: 150,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadius.borderRadiusSm,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadius.borderRadiusMd,
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

class _DiscoverDetailErrorState extends StatelessWidget {
  final Object error;

  const _DiscoverDetailErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(pinned: true, backgroundColor: colorScheme.surface),
          SliverFillRemaining(child: Center(child: Text('Error: $error'))),
        ],
      ),
    );
  }
}

class _DiscoverKeywordsSection extends StatelessWidget {
  final List<String> keywords;

  const _DiscoverKeywordsSection({required this.keywords});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tags', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: keywords
                .map(
                  (keyword) => Chip(
                    label: Text(keyword),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _DiscoverPosterOverlay extends StatelessWidget {
  final String heroTag;
  final String posterUrl;
  final String statusText;
  final Color statusColor;

  const _DiscoverPosterOverlay({
    required this.heroTag,
    required this.posterUrl,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DiscoverPosterCard(heroTag: heroTag, posterUrl: posterUrl),
        const SizedBox(height: AppSpacing.sm),
        TagChip(text: statusText, color: statusColor),
      ],
    );
  }
}

class _DiscoverPosterCard extends StatelessWidget {
  final String heroTag;
  final String? posterUrl;

  const _DiscoverPosterCard({required this.heroTag, this.posterUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Hero(
      tag: heroTag,
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderRadiusMd,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.borderRadiusMd,
            child: SizedBox(
              width: 120,
              height: 180,
              child: posterUrl != null && posterUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: posterUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          Container(color: colorScheme.surfaceContainer),
                    )
                  : Container(color: colorScheme.surfaceContainer),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSectionSliver extends StatelessWidget {
  final Widget child;

  const _DetailSectionSliver({required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        child: child,
      ),
    );
  }
}

class _CertificationChip extends StatelessWidget {
  final String text;

  const _CertificationChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
