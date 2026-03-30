import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/music/domain/models/lidarr_album.dart';
import 'package:seekarr/features/music/domain/models/lidarr_track.dart';

class MusicAlbumsList extends StatefulWidget {
  final List<LidarrAlbum> albums;
  final LidarrService lidarrService;
  final String baseUrl;
  final String apiKey;
  final void Function(int albumId) onSearchAlbum;
  final void Function(int albumId) onInteractiveSearchAlbum;
  final Set<int> searchingAlbums;

  const MusicAlbumsList({
    super.key,
    required this.albums,
    required this.lidarrService,
    required this.baseUrl,
    required this.apiKey,
    required this.onSearchAlbum,
    required this.onInteractiveSearchAlbum,
    required this.searchingAlbums,
  });

  @override
  State<MusicAlbumsList> createState() => _MusicAlbumsListState();
}

class _MusicAlbumsListState extends State<MusicAlbumsList> {
  final Map<int, List<LidarrTrack>?> _tracksByAlbum = {};
  final Set<int> _tracksLoadingError = {};

  Future<void> _loadTracksForAlbum(int albumId) async {
    if (_tracksByAlbum.containsKey(albumId) &&
        !_tracksLoadingError.contains(albumId)) {
      return;
    }

    setState(() {
      _tracksByAlbum[albumId] = null;
      _tracksLoadingError.remove(albumId);
    });

    try {
      final tracks = await widget.lidarrService.getTracks(albumId);
      if (!mounted) {
        return;
      }

      setState(() {
        _tracksByAlbum[albumId] = tracks;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _tracksLoadingError.add(albumId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.albums.isEmpty) {
      return Text(
        'No albums found.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: widget.albums
          .map((album) => _buildAlbumTile(context, album))
          .toList(growable: false),
    );
  }

  Widget _buildAlbumTile(BuildContext context, LidarrAlbum album) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageSource = ImageUtils.extractPosterUrl(
      album.images,
      baseUrl: widget.baseUrl,
      apiKey: widget.apiKey,
      coverTypes: const ['cover', 'disc'],
    );
    final progressColor = album.completionPercent >= 1
        ? colorScheme.primary
        : album.completionPercent > 0
        ? colorScheme.tertiary
        : colorScheme.outline;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) {
            _loadTracksForAlbum(album.id);
          }
        },
        leading: ClipRRect(
          borderRadius: AppRadius.borderRadiusXs,
          child: imageSource.url.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageSource.url,
                  httpHeaders: imageSource.headers,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      _albumPlaceholder(context),
                )
              : _albumPlaceholder(context),
        ),
        title: Text(
          album.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (album.year.isNotEmpty)
              Text(
                album.year,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.borderRadiusXs,
              child: LinearProgressIndicator(
                value: album.completionPercent,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: AppSpacing.xs,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${album.trackFileCount} / ${album.trackCount} tracks',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MediaSearchPopupMenu(
              onAutoSearch: () => widget.onSearchAlbum(album.id),
              onInteractiveSearch: () =>
                  widget.onInteractiveSearchAlbum(album.id),
              isLoading: widget.searchingAlbums.contains(album.id),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              album.monitored ? Icons.bookmark : Icons.bookmark_border,
              color: album.monitored
                  ? colorScheme.tertiary
                  : colorScheme.outline,
            ),
          ],
        ),
        children: _buildTracksList(context, album.id),
      ),
    );
  }

  Widget _albumPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.album, color: colorScheme.outline),
    );
  }

  List<Widget> _buildTracksList(BuildContext context, int albumId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_tracksLoadingError.contains(albumId)) {
      return [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Failed to load tracks',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => _loadTracksForAlbum(albumId),
                icon: const Icon(Icons.refresh, size: AppSpacing.lg),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ];
    }

    if (!_tracksByAlbum.containsKey(albumId)) {
      return const [];
    }

    final tracks = _tracksByAlbum[albumId];
    if (tracks == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (tracks.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No tracks found.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    final sortedTracks = List<LidarrTrack>.from(tracks)
      ..sort((a, b) {
        final mediumCompare = (a.mediumNumber ?? 1).compareTo(
          b.mediumNumber ?? 1,
        );
        if (mediumCompare != 0) {
          return mediumCompare;
        }

        return a.sortableTrackNumber.compareTo(b.sortableTrackNumber);
      });

    return sortedTracks
        .map(
          (track) => ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: AppSpacing.md,
              backgroundColor: track.hasFile
                  ? colorScheme.primary
                  : colorScheme.outline,
              child: Text(
                track.displayTrackNumber,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: track.hasFile
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(track.title, style: theme.textTheme.bodyMedium),
            trailing: Text(
              track.formattedDuration,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }
}
