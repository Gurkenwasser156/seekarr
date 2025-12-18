import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/widgets/media_detail_view.dart';
import 'package:seekarr/core/widgets/tag_chip.dart';
import 'package:seekarr/core/widgets/status_badge.dart';
import 'package:seekarr/core/widgets/file_info_section.dart';
import 'package:seekarr/core/widgets/interactive_search_sheet.dart';
import 'package:seekarr/core/widgets/delete_media_dialog.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/presentation/movies_provider.dart';
import 'package:seekarr/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final title = movie.title;
    final year = movie.year.toString();
    final overview = movie.overview ?? 'No description available.';
    final runtime = movie.runtime > 0 ? '${movie.runtime} min' : '';
    final studio = movie.studio ?? '';
    final status = movie.status;
    final genres = movie.genres.join(', ');

    final imageUrl = ImageUtils.extractPosterUrl(
      movie.images,
      baseUrl: settings.radarrUrl,
      apiKey: settings.radarrApiKey,
    );

    // Build tags with status badge
    final tags = <Widget>[];

    // Status badge first
    tags.add(StatusBadge.fromMedia(hasFile: movie.hasFile, status: status));

    if (year.isNotEmpty) tags.add(TagChip(text: year));
    if (runtime.isNotEmpty) tags.add(TagChip(text: runtime));
    tags.add(
      Text(
        genres,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
      ),
    );
    if (studio.isNotEmpty) {
      tags.add(
        Text(
          studio,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      );
    }

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
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quality Profile (tappable)
          if (_currentProfileName != null) ...[
            GestureDetector(
              onTap: () => _showProfileSelector(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.high_quality,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentProfileName!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Search buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _isSearching
                    ? null
                    : () => _triggerSearch(context, movie.id),
                icon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Automatic Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isLoadingReleases
                    ? null
                    : () => _showInteractiveSearch(context, movie.id),
                icon: _isLoadingReleases
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.list),
                label: const Text('Interactive Search'),
              ),
            ],
          ),

          // File info section (only when available)
          if (movie.hasFile && movie.path != null) ...[
            const SizedBox(height: 16),
            FileInfoSection(path: movie.path, filename: filename),
          ],

          // Delete button
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _isDeleting ? null : () => _confirmDelete(context),
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: const Text('Delete Movie'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileSelector(BuildContext context) async {
    if (_qualityProfiles.isEmpty) return;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Quality Profile'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _qualityProfiles.length,
            itemBuilder: (context, index) {
              final profile = _qualityProfiles[index];
              final id = profile['id'] as int;
              final name = profile['name'] as String;
              final isSelected = id == _currentProfileId;

              return ListTile(
                title: Text(name),
                leading: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : const Icon(Icons.circle_outlined),
                onTap: () => Navigator.pop(context, id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedId != null && selectedId != _currentProfileId) {
      await _updateProfile(selectedId);
    }
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
        // Invalidate movies provider so list refreshes with new data
        ref.invalidate(moviesProvider);
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

  Future<void> _confirmDelete(BuildContext context) async {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Movie deleted')));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete movie: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _triggerSearch(BuildContext context, int movieId) async {
    setState(() => _isSearching = true);
    try {
      final radarrService = ref.read(radarrServiceProvider);
      await radarrService.searchMovie(movieId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Search started')));
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

  Future<void> _showInteractiveSearch(BuildContext context, int movieId) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load releases: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingReleases = false);
    }
  }
}
