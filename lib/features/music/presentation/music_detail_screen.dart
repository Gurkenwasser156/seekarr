import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/api/quality_profile_mixin.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';
import 'package:seekarr/features/music/presentation/music_detail_provider.dart';
import 'package:seekarr/features/music/presentation/music_detail_view_model.dart';
import 'package:seekarr/features/music/presentation/music_provider.dart';
import 'package:seekarr/features/music/presentation/widgets/music_albums_list.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';

class MusicDetailScreen extends ConsumerStatefulWidget {
  final int artistId;
  final String heroTag;
  final LidarrArtist? initialArtist;

  const MusicDetailScreen({
    super.key,
    required this.artistId,
    required this.heroTag,
    this.initialArtist,
  });

  @override
  ConsumerState<MusicDetailScreen> createState() => _MusicDetailScreenState();
}

class _MusicDetailScreenState extends ConsumerState<MusicDetailScreen>
    with QualityProfileMixin<MusicDetailScreen> {
  bool _isSearching = false;
  bool _isDeleting = false;
  final Set<int> _searchingAlbums = {};
  bool _profilesRequested = false;
  int? _boundProfileId;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(currentSettingsProvider);
    final artistAsync = ref.watch(musicDetailProvider(widget.artistId));
    final albumsAsync = ref.watch(musicAlbumsProvider(widget.artistId));
    final artist = artistAsync.asData?.value ?? widget.initialArtist;

    if (artist == null) {
      if (artistAsync.isLoading) {
        return const _MusicDetailLoadingState();
      }

      return _MusicDetailErrorState(
        error: artistAsync.asError?.error ?? 'Artist not found.',
        serviceName: 'Lidarr',
      );
    }

    _ensureQualityProfiles(artist.qualityProfileId);

    final viewModel = MusicDetailViewModel.fromArtist(
      artist,
      baseUrl: settings.lidarrUrl,
      apiKey: settings.lidarrApiKey,
    );
    final tags = <Widget>[
      if (viewModel.albumCount > 0)
        TagChip(
          text:
              '${viewModel.albumCount} ${viewModel.albumCount == 1 ? 'Album' : 'Albums'}',
        ),
      if (viewModel.trackCount > 0)
        TagChip(
          text:
              '${viewModel.trackCount} ${viewModel.trackCount == 1 ? 'Track' : 'Tracks'}',
        ),
    ];
    final infoGroups = viewModel.buildInfoGroups();

    return MediaDetailView(
      heroTag: widget.heroTag,
      posterUrl: viewModel.posterUrl,
      posterHeaders: viewModel.posterHeaders,
      backdropUrl: viewModel.backdropUrl,
      posterRow: (collapseFactor) => MediaDetailPosterRow(
        collapseFactor: collapseFactor,
        statusBadge: StatusBadge.fromMedia(
          hasFile: viewModel.hasFiles,
          status: viewModel.status,
        ),
        posterCard: MediaPosterCard(
          heroTag: widget.heroTag,
          imageUrl: viewModel.posterUrl,
          imageHeaders: viewModel.posterHeaders,
          fallbackIcon: Icons.album_outlined,
        ),
        actions: LibraryDetailActions(
          collapseFactor: collapseFactor,
          isSearching: _isSearching,
          isDeleting: _isDeleting,
          currentProfileName: currentProfileName,
          currentProfileId: currentProfileId,
          qualityProfiles: qualityProfiles,
          onInteractiveSearch: () =>
              _showInteractiveSearch(context, title: viewModel.title),
          onAutoSearch: () => _triggerSearch(context),
          onProfileSelected: _updateProfile,
          onDelete: () => _confirmDelete(context, title: viewModel.title),
        ),
      ),
      contentSections: [
        MediaDetailTitleSection(title: viewModel.title),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          MediaDetailTagSection(tags: tags),
        ],
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
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Albums', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                albumsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => Text(
                    'Failed to load albums.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  data: (albums) => MusicAlbumsList(
                    albums: albums,
                    lidarrService: ref.read(lidarrServiceProvider),
                    baseUrl: settings.lidarrUrl,
                    apiKey: settings.lidarrApiKey,
                    onSearchAlbum: (albumId) => _searchAlbum(context, albumId),
                    onInteractiveSearchAlbum: (albumId) =>
                        _interactiveSearchAlbum(context, albumId),
                    searchingAlbums: _searchingAlbums,
                  ),
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
              ref.read(lidarrServiceProvider).getQualityProfiles(),
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
      final lidarrService = ref.read(lidarrServiceProvider);
      await lidarrService.updateArtistProfile(widget.artistId, profileId);
      if (mounted) {
        updateProfileState(profileId);
        ref.invalidate(musicProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quality profile updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _triggerSearch(BuildContext context) async {
    setState(() => _isSearching = true);
    try {
      final lidarrService = ref.read(lidarrServiceProvider);
      await lidarrService.searchArtist(widget.artistId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search started for artist')),
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
  }) async {
    final lidarrService = ref.read(lidarrServiceProvider);
    await InteractiveSearchSheet.showAsync(
      context: context,
      title: 'Releases for $title',
      fetchReleases: (token) => lidarrService.getReleases(
        artistId: widget.artistId,
        cancelToken: token,
      ),
      onGrabRelease: (guid, indexerId) async {
        await lidarrService.grabRelease(guid: guid, indexerId: indexerId);
      },
    );
  }

  Future<void> _searchAlbum(BuildContext context, int albumId) async {
    setState(() => _searchingAlbums.add(albumId));
    try {
      final lidarrService = ref.read(lidarrServiceProvider);
      await lidarrService.searchAlbums([albumId]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Album search started')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _searchingAlbums.remove(albumId));
    }
  }

  Future<void> _interactiveSearchAlbum(
    BuildContext context,
    int albumId,
  ) async {
    final lidarrService = ref.read(lidarrServiceProvider);
    await InteractiveSearchSheet.showAsync(
      context: context,
      title: 'Album Releases',
      fetchReleases: (token) =>
          lidarrService.getReleases(albumId: albumId, cancelToken: token),
      onGrabRelease: (guid, indexerId) async {
        await lidarrService.grabRelease(guid: guid, indexerId: indexerId);
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String title,
  }) async {
    final result = await showDeleteMediaDialog(
      context: context,
      title: title,
      mediaType: 'artist',
    );

    if (!result.confirmed || !context.mounted) return;

    setState(() => _isDeleting = true);
    try {
      final lidarrService = ref.read(lidarrServiceProvider);
      await lidarrService.deleteArtist(
        widget.artistId,
        deleteFiles: result.deleteFiles,
        addImportListExclusion: result.addExclusion,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Artist deleted')));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete artist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}

class _MusicDetailLoadingState extends StatelessWidget {
  const _MusicDetailLoadingState();

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

class _MusicDetailErrorState extends StatelessWidget {
  final Object error;
  final String serviceName;

  const _MusicDetailErrorState({
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
