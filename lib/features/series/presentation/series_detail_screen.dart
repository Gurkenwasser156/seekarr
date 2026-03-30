import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/api/quality_profile_mixin.dart';
import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:seekarr/features/series/presentation/series_detail_provider.dart';
import 'package:seekarr/features/series/presentation/series_detail_view_model.dart';
import 'package:seekarr/features/series/presentation/series_provider.dart';
import 'package:seekarr/features/series/presentation/widgets/series_seasons_list.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final int seriesId;
  final String heroTag;
  final SonarrSeries? initialSeries;

  const SeriesDetailScreen({
    super.key,
    required this.seriesId,
    required this.heroTag,
    this.initialSeries,
  });

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen>
    with QualityProfileMixin<SeriesDetailScreen> {
  bool _isSearching = false;
  bool _isLoadingReleases = false;
  bool _isDeleting = false;
  final Set<int> _searchingSeasons = {};
  final Set<int> _searchingEpisodes = {};
  bool _profilesRequested = false;
  int? _boundProfileId;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(currentSettingsProvider);
    final seriesAsync = ref.watch(seriesDetailProvider(widget.seriesId));
    final episodesAsync = ref.watch(seriesEpisodesProvider(widget.seriesId));
    final series = seriesAsync.asData?.value ?? widget.initialSeries;

    if (series == null) {
      if (seriesAsync.isLoading) {
        return const _SeriesDetailLoadingState();
      }

      return _SeriesDetailErrorState(
        error: seriesAsync.asError?.error ?? 'Series not found.',
        serviceName: 'Sonarr',
      );
    }

    _ensureQualityProfiles(series.qualityProfileId);

    final viewModel = SeriesDetailViewModel.fromSeries(
      series,
      baseUrl: settings.sonarrUrl,
      apiKey: settings.sonarrApiKey,
    );
    final hasBackdrop = (viewModel.backdropUrl ?? '').isNotEmpty;
    final titleTextAlign = hasBackdrop ? TextAlign.center : TextAlign.start;
    final tagAlignment = hasBackdrop
        ? WrapAlignment.center
        : WrapAlignment.start;
    final tags = <Widget>[
      if (!hasBackdrop)
        StatusBadge.fromMedia(
          hasFile: viewModel.hasFiles,
          status: viewModel.status,
        ),
    ];
    final infoGroups = viewModel.buildInfoGroups();

    return MediaDetailView(
      heroTag: widget.heroTag,
      posterUrl: viewModel.posterUrl,
      posterHeaders: viewModel.posterHeaders,
      backdropUrl: viewModel.backdropUrl,
      posterOverlay: hasBackdrop
          ? _SeriesPosterOverlay(
              heroTag: widget.heroTag,
              posterUrl: viewModel.posterUrl,
              posterHeaders: viewModel.posterHeaders,
              hasFiles: viewModel.hasFiles,
              status: viewModel.status,
            )
          : null,
      contentSections: [
        MediaDetailTitleSection(
          title: viewModel.title,
          textAlign: titleTextAlign,
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          MediaDetailTagSection(tags: tags, alignment: tagAlignment),
        ],
        if (viewModel.metadataItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          MediaMetadataLine(
            items: viewModel.metadataItems,
            textAlign: titleTextAlign,
          ),
        ],
        if (viewModel.ratings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: RatingChipsRow(ratings: viewModel.ratings),
          ),
        ],
        if (infoGroups.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: MediaInfoCard(groups: infoGroups),
          ),
        ],
        if (viewModel.overview.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          MediaDetailOverviewSection(overview: viewModel.overview),
        ],
        if (viewModel.hasFiles && viewModel.path != null) ...[
          const SizedBox(height: AppSpacing.xl),
          FileInfoSection(path: viewModel.path),
        ],
        if (currentProfileName != null) ...[
          const SizedBox(height: AppSpacing.lg),
          MediaManagementRow(
            currentProfileName: currentProfileName!,
            currentProfileId: currentProfileId,
            qualityProfiles: qualityProfiles,
            onProfileSelected: _updateProfile,
            isDeleting: _isDeleting,
            onDelete: () => _confirmDelete(context, title: viewModel.title),
            deleteTooltip: 'Delete Series',
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        MediaSearchActionRow(
          isSearching: _isSearching,
          isLoadingReleases: _isLoadingReleases,
          onAutomaticSearch: () => _triggerSearch(context),
          onInteractiveSearch: () =>
              _showInteractiveSearch(context, title: viewModel.title),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seasons', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                SeriesSeasonsList(
                  seasons: viewModel.seasons,
                  episodesAsync: episodesAsync,
                  onSearchSeason: (seasonNumber) =>
                      _searchSeason(context, seasonNumber),
                  onInteractiveSearchSeason: (seasonNumber) =>
                      _interactiveSearchSeason(
                        context,
                        seasonNumber,
                        title: viewModel.title,
                      ),
                  onSearchEpisode: (episodeId) =>
                      _searchEpisode(context, episodeId),
                  onInteractiveSearchEpisode: (episodeId) =>
                      _interactiveSearchEpisode(context, episodeId),
                  searchingSeasons: _searchingSeasons,
                  searchingEpisodes: _searchingEpisodes,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _ensureQualityProfiles(int? profileId) {
    if (!_profilesRequested) {
      _profilesRequested = true;
      _boundProfileId = profileId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        loadQualityProfiles(
          fetchProfiles: () =>
              ref.read(sonarrServiceProvider).getQualityProfiles(),
          initialProfileId: profileId,
        );
      });
      return;
    }

    if (qualityProfiles.isNotEmpty && _boundProfileId != profileId) {
      _boundProfileId = profileId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          currentProfileId = profileId;
          currentProfileName = getProfileName(profileId);
        });
      });
    }
  }

  Future<void> _triggerSearch(BuildContext context) async {
    setState(() => _isSearching = true);
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      await sonarrService.searchSeries(widget.seriesId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search started for entire series')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _showInteractiveSearch(
    BuildContext context, {
    required String title,
    int? seasonNumber,
  }) async {
    final sonarrService = ref.read(sonarrServiceProvider);
    await InteractiveSearchSheet.showAsync(
      context: context,
      title: seasonNumber != null
          ? 'Releases for $title - Season $seasonNumber'
          : 'Releases for $title',
      fetchReleases: (token) => sonarrService.getReleases(
        seriesId: widget.seriesId,
        seasonNumber: seasonNumber ?? 1,
        cancelToken: token,
      ),
      onGrabRelease: (guid, indexerId) async {
        await sonarrService.grabRelease(guid: guid, indexerId: indexerId);
      },
    );
  }

  Future<void> _searchSeason(BuildContext context, int seasonNumber) async {
    setState(() => _searchingSeasons.add(seasonNumber));
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      await sonarrService.searchSeason(widget.seriesId, seasonNumber);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search started for Season $seasonNumber')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _searchingSeasons.remove(seasonNumber));
    }
  }

  Future<void> _interactiveSearchSeason(
    BuildContext context,
    int seasonNumber, {
    required String title,
  }) async {
    setState(() => _searchingSeasons.add(seasonNumber));
    try {
      await _showInteractiveSearch(
        context,
        title: title,
        seasonNumber: seasonNumber,
      );
    } finally {
      if (mounted) setState(() => _searchingSeasons.remove(seasonNumber));
    }
  }

  Future<void> _searchEpisode(BuildContext context, int episodeId) async {
    setState(() => _searchingEpisodes.add(episodeId));
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      await sonarrService.searchEpisodes([episodeId]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Episode search started')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _searchingEpisodes.remove(episodeId));
    }
  }

  Future<void> _interactiveSearchEpisode(
    BuildContext context,
    int episodeId,
  ) async {
    final sonarrService = ref.read(sonarrServiceProvider);
    await InteractiveSearchSheet.showAsync(
      context: context,
      title: 'Episode Releases',
      fetchReleases: (token) =>
          sonarrService.getReleases(episodeId: episodeId, cancelToken: token),
      onGrabRelease: (guid, indexerId) async {
        await sonarrService.grabRelease(guid: guid, indexerId: indexerId);
      },
    );
  }

  Future<void> _updateProfile(int profileId) async {
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      await sonarrService.updateSeriesProfile(widget.seriesId, profileId);
      if (mounted) {
        updateProfileState(profileId);
        // Invalidate series provider so list refreshes with new data
        ref.invalidate(seriesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quality profile updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String title,
  }) async {
    final result = await showDeleteMediaDialog(
      context: context,
      title: title,
      mediaType: 'series',
    );

    if (!result.confirmed || !context.mounted) return;

    setState(() => _isDeleting = true);
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      await sonarrService.deleteSeries(
        widget.seriesId,
        deleteFiles: result.deleteFiles,
        addImportListExclusion: result.addExclusion,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Series deleted')));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete series: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}

class _SeriesDetailLoadingState extends StatelessWidget {
  const _SeriesDetailLoadingState();

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
                                ShimmerPlaceholder.card(
                                  width: 120,
                                  height: 180,
                                ),
                                SizedBox(height: AppSpacing.sm),
                                ShimmerPlaceholder(
                                  width: 96,
                                  height: 28,
                                  borderRadius: AppRadius.borderRadiusLg,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerPlaceholder.text(width: 220, height: 32),
                  SizedBox(height: AppSpacing.sm),
                  ShimmerPlaceholder.text(width: 180),
                  SizedBox(height: AppSpacing.xl),
                  ShimmerPlaceholder.card(height: 48),
                  SizedBox(height: AppSpacing.xl),
                  ShimmerPlaceholder.card(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesDetailErrorState extends StatelessWidget {
  final Object error;
  final String serviceName;

  const _SeriesDetailErrorState({
    required this.error,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNotConfigured = error.toString().contains('not configured');

    return Material(
      color: colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(pinned: true, backgroundColor: colorScheme.surface),
          SliverFillRemaining(
            child: isNotConfigured
                ? NotConfiguredPlaceholder(serviceName: serviceName)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'Error: $error',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SeriesPosterOverlay extends StatelessWidget {
  final String heroTag;
  final String posterUrl;
  final Map<String, String>? posterHeaders;
  final bool hasFiles;
  final String status;

  const _SeriesPosterOverlay({
    required this.heroTag,
    required this.posterUrl,
    required this.posterHeaders,
    required this.hasFiles,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SeriesPosterCard(
          heroTag: heroTag,
          posterUrl: posterUrl,
          posterHeaders: posterHeaders,
        ),
        const SizedBox(height: AppSpacing.sm),
        StatusBadge.fromMedia(hasFile: hasFiles, status: status),
      ],
    );
  }
}

class _SeriesPosterCard extends StatelessWidget {
  final String heroTag;
  final String? posterUrl;
  final Map<String, String>? posterHeaders;

  const _SeriesPosterCard({
    required this.heroTag,
    required this.posterUrl,
    required this.posterHeaders,
  });

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
                      httpHeaders: posterHeaders,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          Container(color: colorScheme.surfaceContainer),
                    )
                  : Container(
                      color: colorScheme.surfaceContainer,
                      child: Icon(
                        Icons.tv_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
