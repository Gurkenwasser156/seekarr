import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/widgets/delete_media_dialog.dart';
import 'package:seekarr/core/widgets/file_info_section.dart';
import 'package:seekarr/core/widgets/interactive_search_sheet.dart';
import 'package:seekarr/core/widgets/media_detail_view.dart';
import 'package:seekarr/core/widgets/media_profile_selector.dart';
import 'package:seekarr/core/widgets/status_badge.dart';
import 'package:seekarr/core/widgets/tag_chip.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/features/movies/presentation/movies_provider.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';

/// Detail screen for a Radarr movie with M3 styling.
class MovieDetailScreen extends ConsumerStatefulWidget {
  final RadarrMovie movie;
  final String heroTag;

  const MovieDetailScreen({
    super.key,
    required this.movie,
    required this.heroTag,
  });

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  bool _isSearching = false;
  bool _isLoadingReleases = false;
  bool _isDeleting = false;
  List<Map<String, dynamic>> _qualityProfiles = [];
  String? _currentProfileName;
  int? _currentProfileId;

  @override
  void initState() {
    super.initState();
    _loadQualityProfiles();
  }

  Future<void> _loadQualityProfiles() async {
    try {
      final radarrService = ref.read(radarrServiceProvider);
      final profiles = await radarrService.getQualityProfiles();
      if (mounted) {
        setState(() {
          _qualityProfiles = profiles;
          _currentProfileId = widget.movie.qualityProfileId;
          _currentProfileName = _getProfileName(_currentProfileId);
        });
      }
    } catch (e) {
      // Ignore profile loading errors
    }
  }

  String? _getProfileName(int? profileId) {
    if (profileId == null) return null;
    final profile = _qualityProfiles
        .where((p) => p['id'] == profileId)
        .firstOrNull;
    return profile?['name'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final movie = widget.movie;
    final colorScheme = Theme.of(context).colorScheme;

    final title = movie.title;
    final year = movie.year.toString();
    final overview = movie.overview ?? 'No description available.';
    final runtime = movie.runtime > 0 ? '${movie.runtime} min' : '';
    final studio = movie.studio ?? '';
    final status = movie.status;

    final imageUrl = ImageUtils.extractPosterUrl(
      movie.images,
      baseUrl: settings.radarrUrl,
      apiKey: settings.radarrApiKey,
    );

    // Build tags with status badge and metadata
    final tags = <Widget>[
      StatusBadge.fromMedia(hasFile: movie.hasFile, status: status),
      if (year.isNotEmpty) TagChip(text: year),
      if (runtime.isNotEmpty)
        TagChip(text: runtime, icon: Icons.schedule_rounded),
      // Genre chips
      ...movie.genres.take(3).map((genre) => GenreChip(genre: genre)),
    ];

    // Extract filename from path
    String? filename;
    if (movie.hasFile && movie.path != null) {
      filename = movie.path!.split('/').last;
    }

    return MediaDetailView(
      title: title,
      heroTag: widget.heroTag,
      posterUrl: imageUrl,
      overview: overview,
      tags: tags,
      actions: _buildActions(context, colorScheme, movie, filename, studio),
    );
  }

  Widget _buildActions(
    BuildContext context,
    ColorScheme colorScheme,
    RadarrMovie movie,
    String? filename,
    String studio,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Studio info
        if (studio.isNotEmpty) ...[
          Text(
            studio,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSearching
                    ? null
                    : () => _triggerSearch(context, movie.id),
                icon: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: const Text(
                  'Automatic Search',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoadingReleases
                    ? null
                    : () => _showInteractiveSearch(context, movie.id),
                icon: _isLoadingReleases
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.list_rounded),
                label: const Text(
                  'Interactive Search',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),

        // File info section
        if (movie.hasFile && movie.path != null) ...[
          const SizedBox(height: AppSpacing.xl),
          FileInfoSection(path: movie.path, filename: filename),
        ],

        // Profile selector (split button) + delete button
        if (_currentProfileName != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: MediaProfileSelector.split(
                  currentProfileName: _currentProfileName!,
                  currentProfileId: _currentProfileId,
                  qualityProfiles: _qualityProfiles,
                  onProfileSelected: _updateProfile,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                onPressed: _isDeleting ? null : () => _confirmDelete(context),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                ),
                tooltip: 'Delete Movie',
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _updateProfile(int profileId) async {
    try {
      final radarrService = ref.read(radarrServiceProvider);
      await radarrService.updateMovieProfile(widget.movie.id, profileId);
      if (mounted) {
        setState(() {
          _currentProfileId = profileId;
          _currentProfileName = _getProfileName(profileId);
        });
        ref.invalidate(moviesProvider);
        _showSnackBar('Quality profile updated');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to update profile: $e');
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final result = await showDeleteMediaDialog(
      context: context,
      title: widget.movie.title,
      mediaType: 'movie',
    );

    if (!result.confirmed || !context.mounted) return;

    setState(() => _isDeleting = true);
    try {
      final radarrService = ref.read(radarrServiceProvider);
      await radarrService.deleteMovie(
        widget.movie.id,
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

  Future<void> _triggerSearch(BuildContext context, int movieId) async {
    HapticFeedback.selectionClick();
    setState(() => _isSearching = true);
    try {
      final radarrService = ref.read(radarrServiceProvider);
      await radarrService.searchMovie(movieId);
      if (!context.mounted) return;
      _showSnackBar('Search started');
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar('Search failed: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _showInteractiveSearch(BuildContext context, int movieId) async {
    HapticFeedback.selectionClick();
    setState(() => _isLoadingReleases = true);
    try {
      final radarrService = ref.read(radarrServiceProvider);
      final releases = await radarrService.getReleases(movieId);
      if (!context.mounted) return;

      await InteractiveSearchSheet.show(
        context: context,
        releases: releases,
        title: 'Releases for ${widget.movie.title}',
        onGrabRelease: (guid, indexerId) async {
          await radarrService.grabRelease(guid: guid, indexerId: indexerId);
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar('Failed to load releases: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReleases = false);
    }
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
