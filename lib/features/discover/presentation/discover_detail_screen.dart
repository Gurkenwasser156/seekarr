import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_extras_provider.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_view_model.dart';
import 'package:seekarr/features/discover/presentation/discover_details_provider.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_action_buttons.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_cast_list.dart';

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
    final normalizedMediaType = mediaType == 'movie' ? 'movie' : 'tv';
    final detailsAsync = ref.watch(
      discoverDetailProvider((id: mediaId, type: normalizedMediaType)),
    );

    return detailsAsync.when(
      loading: () => _DiscoverDetailLoadingState(
        heroTag: heroTag,
        initialPosterUrl: initialPosterUrl,
      ),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (details) {
        final viewModel = DiscoverDetailViewModel.fromResponse(
          details,
          initialPosterUrl: initialPosterUrl,
        );
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

        final isInService =
            normalizedMediaType == 'movie' && extras.libraryCheckDone
            ? extras.isInLibrary ?? false
            : viewModel.statusCode != null &&
                  viewModel.statusCode! >= 1 &&
                  viewModel.statusCode! <= 5;

        final tags = <Widget>[
          if (viewModel.year.isNotEmpty) TagChip(text: viewModel.year),
          if (viewModel.runtimeStr != null)
            TagChip(text: viewModel.runtimeStr!),
          if (viewModel.numberOfSeasons != null)
            TagChip(text: '${viewModel.numberOfSeasons} Seasons'),
          TagChip(
            text: viewModel.jellyseerrStatus,
            color: viewModel.isAvailable ? AppColors.success : AppColors.info,
          ),
        ];
        final ratingWidgets = _buildRatingWidgets(
          viewModel,
          extras.lookupRatings,
        );

        return MediaDetailView(
          title: viewModel.title,
          heroTag: heroTag,
          posterUrl: viewModel.posterUrl,
          overview: viewModel.overview,
          tags: tags,
          actions: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewModel.metadataLine.isNotEmpty) ...[
                Text(
                  viewModel.metadataLine,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (ratingWidgets.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: ratingWidgets,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              DiscoverActionButtons(
                mediaId: mediaId,
                mediaType: normalizedMediaType,
                hasManageableMedia: viewModel.hasManageableMedia,
                isInService: isInService,
                isAvailable: viewModel.isAvailable,
                tvdbId: viewModel.tvdbId,
                servicePath: viewModel.servicePath,
                mediaInfo: viewModel.mediaInfo,
                title: viewModel.title,
                voteAverage: viewModel.voteAverage,
              ),
              if (viewModel.hasCrew) ...[
                const SizedBox(height: AppSpacing.xl),
                _DiscoverCrewSection(
                  directorNames: viewModel.directorNames,
                  writerNames: viewModel.writerNames,
                ),
              ],
            ],
          ),
          slivers: [
            if (viewModel.keywords.isNotEmpty)
              SliverToBoxAdapter(
                child: _DiscoverKeywordsSection(keywords: viewModel.keywords),
              ),
            if (viewModel.cast.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Text(
                    'Cast',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            if (viewModel.cast.isNotEmpty)
              SliverToBoxAdapter(child: DiscoverCastList(cast: viewModel.cast)),
          ],
        );
      },
    );
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag,
                child: Material(
                  type: MaterialType.transparency,
                  child:
                      initialPosterUrl != null && initialPosterUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: initialPosterUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              Container(color: colorScheme.surfaceContainer),
                        )
                      : Container(
                          color: colorScheme.surfaceContainer,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverCrewSection extends StatelessWidget {
  final String directorNames;
  final String writerNames;

  const _DiscoverCrewSection({
    required this.directorNames,
    required this.writerNames,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        if (directorNames.isNotEmpty)
          _DiscoverCrewLabel(label: 'Director', names: directorNames),
        if (writerNames.isNotEmpty)
          _DiscoverCrewLabel(label: 'Writer', names: writerNames),
      ],
    );
  }
}

class _DiscoverCrewLabel extends StatelessWidget {
  final String label;
  final String names;

  const _DiscoverCrewLabel({required this.label, required this.names});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Flexible(child: Text(names)),
      ],
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
