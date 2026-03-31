import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/api/quality_profile_mixin.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/features/movies/presentation/movie_detail_provider.dart';
import 'package:seekarr/features/movies/presentation/movie_detail_view_model.dart';
import 'package:seekarr/features/movies/presentation/movies_provider.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';

/// Detail screen for a Radarr movie with M3 styling.
class MovieDetailScreen extends ConsumerStatefulWidget {
  final int movieId;
  final String heroTag;
  final RadarrMovie? initialMovie;

  const MovieDetailScreen({
    super.key,
    required this.movieId,
    required this.heroTag,
    this.initialMovie,
  });

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen>
    with QualityProfileMixin<MovieDetailScreen> {
  bool _isSearching = false;
  bool _isLoadingReleases = false;
  bool _isDeleting = false;
  bool _profilesRequested = false;
  int? _boundProfileId;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(currentSettingsProvider);
    final movieAsync = ref.watch(movieDetailProvider(widget.movieId));
    final movie = movieAsync.asData?.value ?? widget.initialMovie;

    if (movie == null) {
      if (movieAsync.isLoading) {
        return const _MovieDetailLoadingState();
      }

      return _MovieDetailErrorState(
        error: movieAsync.asError?.error ?? 'Movie not found.',
        serviceName: 'Radarr',
      );
    }

    _ensureQualityProfiles(movie.qualityProfileId);

    final viewModel = MovieDetailViewModel.fromMovie(
      movie,
      baseUrl: settings.radarrUrl,
      apiKey: settings.radarrApiKey,
    );
    final infoGroups = viewModel.buildInfoGroups();

    return MediaDetailView(
      heroTag: widget.heroTag,
      posterUrl: viewModel.posterUrl,
      posterHeaders: viewModel.posterHeaders,
      backdropUrl: viewModel.backdropUrl,
      posterRow: (collapseFactor) => MediaDetailPosterRow(
        collapseFactor: collapseFactor,
        statusBadge: StatusBadge.fromMedia(
          hasFile: viewModel.hasFile,
          status: viewModel.status,
        ),
        posterCard: MediaPosterCard(
          heroTag: widget.heroTag,
          imageUrl: viewModel.posterUrl,
          imageHeaders: viewModel.posterHeaders,
          fallbackIcon: Icons.movie_outlined,
        ),
        actionButtons: [
          if (currentProfileName != null)
            MediaManagementRow(
              currentProfileName: currentProfileName!,
              currentProfileId: currentProfileId,
              qualityProfiles: qualityProfiles,
              onProfileSelected: _updateProfile,
              isDeleting: _isDeleting,
              onDelete: () => _confirmDelete(context, title: viewModel.title),
              deleteTooltip: 'Delete Movie',
            ),
          MediaSearchActionRow(
            isSearching: _isSearching,
            isLoadingReleases: _isLoadingReleases,
            onAutomaticSearch: () => _triggerSearch(context),
            onInteractiveSearch: () =>
                _showInteractiveSearch(context, title: viewModel.title),
          ),
        ],
      ),
      contentSections: [
        MediaDetailTitleSection(title: viewModel.title),
        if (viewModel.metadataItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          MediaMetadataLine(items: viewModel.metadataItems),
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
        if (viewModel.hasFile && viewModel.path != null) ...[
          const SizedBox(height: AppSpacing.xl),
          FileInfoSection(path: viewModel.path, filename: viewModel.filename),
        ],
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
              ref.read(radarrServiceProvider).getQualityProfiles(),
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

  Future<void> _updateProfile(int profileId) async {
    try {
      final radarrService = ref.read(radarrServiceProvider);
      await radarrService.updateMovieProfile(widget.movieId, profileId);
      if (mounted) {
        updateProfileState(profileId);
        ref.invalidate(moviesProvider);
        _showSnackBar('Quality profile updated');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to update profile: $e');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String title,
  }) async {
    HapticFeedback.mediumImpact();

    final result = await showDeleteMediaDialog(
      context: context,
      title: title,
      mediaType: 'movie',
    );

    if (!result.confirmed || !context.mounted) return;

    setState(() => _isDeleting = true);
    try {
      final radarrService = ref.read(radarrServiceProvider);
      await radarrService.deleteMovie(
        widget.movieId,
        deleteFiles: result.deleteFiles,
        addImportExclusion: result.addExclusion,
      );
      if (!context.mounted) return;
      _showSnackBar('Movie deleted');
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar('Failed to delete movie: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _triggerSearch(BuildContext context) async {
    HapticFeedback.selectionClick();
    setState(() => _isSearching = true);
    try {
      final radarrService = ref.read(radarrServiceProvider);
      await radarrService.searchMovie(widget.movieId);
      if (!context.mounted) return;
      _showSnackBar('Search started');
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar('Search failed: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _showInteractiveSearch(
    BuildContext context, {
    required String title,
  }) async {
    HapticFeedback.selectionClick();
    final radarrService = ref.read(radarrServiceProvider);
    await InteractiveSearchSheet.showAsync(
      context: context,
      title: 'Releases for $title',
      fetchReleases: (token) =>
          radarrService.getReleases(widget.movieId, cancelToken: token),
      onGrabRelease: (guid, indexerId) async {
        await radarrService.grabRelease(guid: guid, indexerId: indexerId);
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _MovieDetailLoadingState extends StatelessWidget {
  const _MovieDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaDetailView.expandedHeight,
            pinned: true,
            backgroundColor: colorScheme.surface,
            collapsedHeight: MediaDetailView.collapsedHeight,
            flexibleSpace: const MediaDetailLoadingHeader(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerPlaceholder.text(width: 220, height: 32),
                  SizedBox(height: AppSpacing.sm),
                  ShimmerPlaceholder.text(width: 160),
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

class _MovieDetailErrorState extends StatelessWidget {
  final Object error;
  final String serviceName;

  const _MovieDetailErrorState({
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
