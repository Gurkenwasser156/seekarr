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
      return const _EmptyAlbumsState();
    }

    return Column(
      children: widget.albums
          .map(
            (album) => _AlbumTile(
              album: album,
              baseUrl: widget.baseUrl,
              apiKey: widget.apiKey,
              isSearching: widget.searchingAlbums.contains(album.id),
              onExpanded: () => _loadTracksForAlbum(album.id),
              onSearchAlbum: () => widget.onSearchAlbum(album.id),
              onInteractiveSearchAlbum: () =>
                  widget.onInteractiveSearchAlbum(album.id),
              children: _buildTracksList(context, album.id),
            ),
          )
          .toList(growable: false),
    );
  }

  List<Widget> _buildTracksList(BuildContext context, int albumId) {
    if (_tracksLoadingError.contains(albumId)) {
      return [_TracksLoadError(onRetry: () => _loadTracksForAlbum(albumId))];
    }

    if (!_tracksByAlbum.containsKey(albumId)) {
      return const [];
    }

    final tracks = _tracksByAlbum[albumId];
    if (tracks == null) {
      return const [_TracksLoadingState()];
    }

    if (tracks.isEmpty) {
      return const [_EmptyTracksState()];
    }

    return _sortTracks(
      tracks,
    ).map((track) => _TrackTile(track: track)).toList(growable: false);
  }

  List<LidarrTrack> _sortTracks(List<LidarrTrack> tracks) {
    final sortedTracks = List<LidarrTrack>.from(tracks);
    sortedTracks.sort((a, b) {
      final mediumCompare = (a.mediumNumber ?? 1).compareTo(
        b.mediumNumber ?? 1,
      );
      if (mediumCompare != 0) {
        return mediumCompare;
      }

      return a.sortableTrackNumber.compareTo(b.sortableTrackNumber);
    });
    return sortedTracks;
  }
}

class _EmptyAlbumsState extends StatelessWidget {
  const _EmptyAlbumsState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'No albums found.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  final LidarrAlbum album;
  final String baseUrl;
  final String apiKey;
  final bool isSearching;
  final VoidCallback onExpanded;
  final VoidCallback onSearchAlbum;
  final VoidCallback onInteractiveSearchAlbum;
  final List<Widget> children;

  const _AlbumTile({
    required this.album,
    required this.baseUrl,
    required this.apiKey,
    required this.isSearching,
    required this.onExpanded,
    required this.onSearchAlbum,
    required this.onInteractiveSearchAlbum,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) {
            onExpanded();
          }
        },
        leading: _AlbumArtwork(
          images: album.images,
          baseUrl: baseUrl,
          apiKey: apiKey,
        ),
        title: Text(
          album.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: _AlbumSubtitle(album: album),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MediaSearchPopupMenu(
              onAutoSearch: onSearchAlbum,
              onInteractiveSearch: onInteractiveSearchAlbum,
              isLoading: isSearching,
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
        children: children,
      ),
    );
  }
}

class _AlbumArtwork extends StatelessWidget {
  final List<dynamic> images;
  final String baseUrl;
  final String apiKey;

  const _AlbumArtwork({
    required this.images,
    required this.baseUrl,
    required this.apiKey,
  });

  @override
  Widget build(BuildContext context) {
    final imageSource = ImageUtils.extractPosterUrl(
      images,
      baseUrl: baseUrl,
      apiKey: apiKey,
      coverTypes: const ['cover', 'disc'],
    );

    return ClipRRect(
      borderRadius: AppRadius.borderRadiusXs,
      child: imageSource.url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageSource.url,
              httpHeaders: imageSource.headers,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const _AlbumPlaceholder(),
            )
          : const _AlbumPlaceholder(),
    );
  }
}

class _AlbumSubtitle extends StatelessWidget {
  final LidarrAlbum album;

  const _AlbumSubtitle({required this.album});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
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
            valueColor: AlwaysStoppedAnimation<Color>(
              _albumProgressColor(colorScheme, album),
            ),
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
    );
  }
}

class _AlbumPlaceholder extends StatelessWidget {
  const _AlbumPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.album, color: colorScheme.outline),
    );
  }
}

class _TracksLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _TracksLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
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
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: AppSpacing.lg),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _TracksLoadingState extends StatelessWidget {
  const _TracksLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyTracksState extends StatelessWidget {
  const _EmptyTracksState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        'No tracks found.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final LidarrTrack track;

  const _TrackTile({required this.track});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
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
    );
  }
}

Color _albumProgressColor(ColorScheme colorScheme, LidarrAlbum album) {
  if (album.completionPercent >= 1) {
    return colorScheme.primary;
  }
  if (album.completionPercent > 0) {
    return colorScheme.tertiary;
  }
  return colorScheme.outline;
}
