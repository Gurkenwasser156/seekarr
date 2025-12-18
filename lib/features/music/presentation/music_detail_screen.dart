import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/widgets/media_detail_view.dart';
import 'package:seekarr/core/widgets/tag_chip.dart';
import 'package:seekarr/core/widgets/status_badge.dart';
import 'package:seekarr/core/widgets/interactive_search_sheet.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MusicDetailScreen extends ConsumerStatefulWidget {
  final LidarrArtist artist;
  final String heroTag;

  const MusicDetailScreen({
    super.key,
    required this.artist,
    required this.heroTag,
  });

  @override
  ConsumerState<MusicDetailScreen> createState() => _MusicDetailScreenState();
}

class _MusicDetailScreenState extends ConsumerState<MusicDetailScreen> {
  bool _isSearching = false;
  bool _isLoadingReleases = false;
  List<dynamic> _albums = [];
  final Map<int, List<dynamic>> _tracksByAlbum = {};
  bool _albumsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      final lidarrService = ref.read(lidarrServiceProvider);
      final albums = await lidarrService.getAlbums(widget.artist.id);
      if (mounted) {
        setState(() {
          _albums = albums;
          _albumsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _albumsLoaded = true);
    }
  }

  Future<void> _loadTracksForAlbum(int albumId) async {
    if (_tracksByAlbum.containsKey(albumId)) return;
    try {
      final lidarrService = ref.read(lidarrServiceProvider);
      final tracks = await lidarrService.getTracks(albumId);
      if (mounted) {
        setState(() {
          _tracksByAlbum[albumId] = tracks;
        });
      }
    } catch (e) {
      // Track loading failed
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final artist = widget.artist;
    final title = artist.artistName;
    final overview = artist.overview ?? 'No description available.';
    final status = artist.status;
    final genres = artist.genres.join(', ');

    // Lidarr uses different cover types
    final imageUrl = ImageUtils.extractPosterUrl(
      artist.images,
      baseUrl: settings.lidarrUrl,
      apiKey: settings.lidarrApiKey,
      coverTypes: ['poster', 'fanart', 'banner', 'logo'],
    );

    // Statistics
    final stats = artist.statistics;
    // Determine status based on track files
    final hasFiles = (stats?['trackFileCount'] as int? ?? 0) > 0;

    final tags = <Widget>[];
    // Status badge first
    tags.add(StatusBadge.fromMedia(hasFile: hasFiles, status: status));
    if (genres.isNotEmpty) {
      tags.add(
        Text(
          genres,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    // Statistics
    if (stats != null) {
      final albumCount = stats['albumCount'] as int? ?? 0;
      final trackCount = stats['trackCount'] as int? ?? 0;
      if (albumCount > 0) tags.add(TagChip(text: '$albumCount Albums'));
      if (trackCount > 0) tags.add(TagChip(text: '$trackCount Tracks'));
    }

    return MediaDetailView(
      title: title,
      heroTag: widget.heroTag,
      posterUrl: imageUrl,
      overview: overview,
      tags: tags,
      actions: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton.icon(
            onPressed: _isSearching
                ? null
                : () => _triggerSearch(context, artist.id),
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
                : () => _showInteractiveSearch(context, artist.id),
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
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Albums', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildAlbumsAccordion(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumsAccordion(BuildContext context) {
    if (!_albumsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_albums.isEmpty) {
      return const Text('No albums found');
    }

    return Column(
      children: _albums.map((album) {
        final albumId = album['id'] as int;
        final albumTitle = album['title'] as String? ?? 'Unknown Album';
        final releaseDate = album['releaseDate'] as String?;
        final year = releaseDate != null && releaseDate.length >= 4
            ? releaseDate.substring(0, 4)
            : '';
        final monitored = album['monitored'] as bool? ?? false;
        final stats = album['statistics'] as Map<String, dynamic>?;
        final trackCount = stats?['totalTrackCount'] as int? ?? 0;
        final trackFileCount = stats?['trackFileCount'] as int? ?? 0;
        final percent = trackCount > 0 ? (trackFileCount / trackCount) : 0.0;

        // Get cover image
        final images = album['images'] as List<dynamic>? ?? [];
        final settings = ref.watch(settingsProvider);
        final albumCover = ImageUtils.extractPosterUrl(
          images,
          baseUrl: settings.lidarrUrl,
          apiKey: settings.lidarrApiKey,
          coverTypes: ['cover', 'disc'],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              if (expanded) _loadTracksForAlbum(albumId);
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: albumCover.isNotEmpty
                  ? Image.network(
                      albumCover,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _albumPlaceholder(),
                    )
                  : _albumPlaceholder(),
            ),
            title: Text(
              albumTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (year.isNotEmpty)
                  Text(year, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percent.toDouble(),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent == 1.0 ? Colors.green : Colors.orange,
                    ),
                    minHeight: 4,
                  ),
                ),
                Text(
                  '$trackFileCount / $trackCount tracks',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchMenu(
                  context: context,
                  onAutoSearch: () => _searchAlbum(context, albumId),
                  onInteractiveSearch: () =>
                      _interactiveSearchAlbum(context, albumId),
                ),
                const SizedBox(width: 8),
                Icon(
                  monitored ? Icons.bookmark : Icons.bookmark_border,
                  color: monitored
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey,
                ),
              ],
            ),
            children: _buildTracksList(albumId),
          ),
        );
      }).toList(),
    );
  }

  Widget _albumPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey[800],
      child: const Icon(Icons.album, color: Colors.grey),
    );
  }

  List<Widget> _buildTracksList(int albumId) {
    final tracks = _tracksByAlbum[albumId];
    if (tracks == null) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final sortedTracks = List<dynamic>.from(tracks)
      ..sort((a, b) {
        final aDisc = a['mediumNumber'] as int? ?? 1;
        final bDisc = b['mediumNumber'] as int? ?? 1;
        if (aDisc != bDisc) return aDisc.compareTo(bDisc);
        final aTrack = a['trackNumber'] as int? ?? 0;
        final bTrack = b['trackNumber'] as int? ?? 0;
        return aTrack.compareTo(bTrack);
      });

    return sortedTracks.map<Widget>((track) {
      final trackNumber = track['trackNumber'] as int? ?? 0;
      final trackTitle = track['title'] as String? ?? 'Track $trackNumber';
      final hasFile = track['hasFile'] as bool? ?? false;
      final duration = track['duration'] as int? ?? 0;
      final durationStr = _formatDuration(duration);

      return ListTile(
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: hasFile ? Colors.green : Colors.grey,
          child: Text(
            trackNumber.toString(),
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
        title: Text(trackTitle, style: const TextStyle(fontSize: 14)),
        trailing: Text(
          durationStr,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        dense: true,
      );
    }).toList();
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildSearchMenu({
    required BuildContext context,
    required VoidCallback onAutoSearch,
    required VoidCallback onInteractiveSearch,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.search, size: 20),
      tooltip: 'Search options',
      onSelected: (value) {
        if (value == 'auto') onAutoSearch();
        if (value == 'interactive') onInteractiveSearch();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'auto', child: Text('Automatic Search')),
        const PopupMenuItem(
          value: 'interactive',
          child: Text('Interactive Search'),
        ),
      ],
    );
  }

  Future<void> _triggerSearch(BuildContext context, int artistId) async {
    setState(() => _isSearching = true);
    try {
      final lidarrService = ref.read(lidarrServiceProvider);
      await lidarrService.searchArtist(artistId);
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
    BuildContext context,
    int artistId,
  ) async {
    setState(() => _isLoadingReleases = true);
    try {
      final lidarrService = ref.read(lidarrServiceProvider);
      final releases = await lidarrService.getReleases(artistId: artistId);
      if (!context.mounted) return;

      await InteractiveSearchSheet.show(
        context: context,
        releases: releases,
        title: 'Releases for ${widget.artist.artistName}',
        onGrabRelease: (guid, indexerId) async {
          await lidarrService.grabRelease(guid: guid, indexerId: indexerId);
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

  Future<void> _searchAlbum(BuildContext context, int albumId) async {
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
    }
  }

  Future<void> _interactiveSearchAlbum(
    BuildContext context,
    int albumId,
  ) async {
    try {
      final lidarrService = ref.read(lidarrServiceProvider);
      final releases = await lidarrService.getReleases(albumId: albumId);
      if (!context.mounted) return;

      await InteractiveSearchSheet.show(
        context: context,
        releases: releases,
        title: 'Album Releases',
        onGrabRelease: (guid, indexerId) async {
          await lidarrService.grabRelease(guid: guid, indexerId: indexerId);
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
    }
  }
}
