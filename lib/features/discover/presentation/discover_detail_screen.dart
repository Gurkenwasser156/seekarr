import 'package:cached_network_image/cached_network_image.dart';
import 'package:seekarr/core/utils/sheet_utils.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/core/widgets/tag_chip.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/features/discover/presentation/discover_details_provider.dart';
import 'package:seekarr/features/discover/presentation/widgets/manage_media_sheet.dart';
import 'package:seekarr/features/discover/presentation/widgets/request_bottom_sheet.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiscoverDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<DiscoverDetailScreen> createState() =>
      _DiscoverDetailScreenState();
}

class _DiscoverDetailScreenState extends ConsumerState<DiscoverDetailScreen> {
  bool? _isActuallyInLibrary;
  bool _libraryCheckDone = false;

  @override
  void initState() {
    super.initState();
    _checkActualLibraryStatus();
  }

  Future<void> _checkActualLibraryStatus({int? tvdbId}) async {
    try {
      if (widget.mediaType == 'movie') {
        final radarrService = ref.read(radarrServiceProvider);
        final movie = await radarrService.getMovieByTmdbId(widget.mediaId);
        if (mounted) {
          setState(() {
            _isActuallyInLibrary = movie != null;
            _libraryCheckDone = true;
          });
        }
      } else if (tvdbId != null) {
        // For TV, check via tvdbId
        final sonarrService = ref.read(sonarrServiceProvider);
        final series = await sonarrService.getSeriesByTvdbId(tvdbId);
        if (mounted) {
          setState(() {
            _isActuallyInLibrary = series != null;
            _libraryCheckDone = true;
          });
        }
      } else {
        // No tvdbId available, fallback to Jellyseerr status
        setState(() => _libraryCheckDone = true);
      }
    } catch (e) {
      if (mounted) setState(() => _libraryCheckDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.mediaType == 'movie' ? 'movie' : 'tv';
    final detailsAsync = ref.watch(
      discoverDetailProvider((id: widget.mediaId, type: type)),
    );

    return detailsAsync.when(
      loading: () => _buildLoadingState(context),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (details) => _buildDataState(context, details),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.heroTag,
                child: Material(
                  type: MaterialType.transparency,
                  child:
                      widget.initialPosterUrl != null &&
                          widget.initialPosterUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.initialPosterUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              Container(color: Colors.grey[900]),
                        )
                      : Container(
                          color: Colors.grey[900],
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
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataState(BuildContext context, Map<String, dynamic> details) {
    final title = details['title'] ?? details['name'] ?? 'Unknown';
    final overview = details['overview'] ?? '';
    final posterPath = details['posterPath'];
    final posterUrl =
        widget.initialPosterUrl ??
        ImageUtils.buildTmdbPosterUrl(posterPath, size: 'w500');

    // Status
    final mediaInfo = details['mediaInfo'];
    final statusCode = mediaInfo?['status'] as int?;
    final jellyseerrStatus = _getJellyseerrStatus(statusCode);
    final isAvailable = statusCode == 4 || statusCode == 5;

    // Media is "in service" - for movies, use live check; for TV, use Jellyseerr status
    bool isInService;
    if (widget.mediaType == 'movie' && _libraryCheckDone) {
      isInService = _isActuallyInLibrary ?? false;
    } else {
      isInService = statusCode != null && statusCode >= 1 && statusCode <= 5;
    }

    // Path to media in service (if available)
    final servicePath = mediaInfo?['path'] as String?;

    // Metadata
    final genres =
        (details['genres'] as List<dynamic>?)
            ?.map((g) => g['name'])
            .join(', ') ??
        '';
    final releaseDate =
        (details['releaseDate'] ?? details['firstAirDate'])?.toString() ?? '';
    final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
    final runtime = details['runtime'] as int?;
    final runtimeStr = runtime != null && runtime > 0 ? '${runtime}min' : null;

    // Cast & Crew
    final credits = details['credits'] as Map<String, dynamic>?;
    final cast = (credits?['cast'] as List<dynamic>?)?.take(20).toList() ?? [];
    final crew = credits?['crew'] as List<dynamic>? ?? [];
    final directors = crew
        .where((c) => c['job'] == 'Director')
        .take(2)
        .toList();
    final writers = crew
        .where((c) => c['job'] == 'Writer' || c['job'] == 'Screenplay')
        .take(2)
        .toList();

    // Keywords
    final keywords =
        (details['keywords'] as List<dynamic>?)?.take(8).toList() ?? [];

    // TV specific
    final numberOfSeasons = details['numberOfSeasons'] as int?;
    final networks =
        (details['networks'] as List<dynamic>?)
            ?.map((n) => n['name'])
            .take(2)
            .join(', ') ??
        '';

    // External IDs for "Open in" feature
    final externalIds = details['externalIds'] as Map<String, dynamic>?;
    final tvdbId = externalIds?['tvdbId'] as int? ?? details['tvdbId'] as int?;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar with poster
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.heroTag,
                child: Material(
                  type: MaterialType.transparency,
                  child: posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              Container(color: Colors.grey[900]),
                        )
                      : Container(color: Colors.grey[900]),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tags row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (year.isNotEmpty) TagChip(text: year),
                      if (runtimeStr != null) TagChip(text: runtimeStr),
                      if (numberOfSeasons != null)
                        TagChip(text: '$numberOfSeasons Seasons'),
                      TagChip(
                        text: jellyseerrStatus,
                        color: isAvailable ? Colors.green : Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Genres & Network
                  if (genres.isNotEmpty || networks.isNotEmpty)
                    Text(
                      [genres, networks].where((s) => s.isNotEmpty).join(' • '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  const SizedBox(height: 20),

                  // Action buttons
                  _buildActionButtons(
                    context,
                    isInService: isInService,
                    isAvailable: isAvailable,
                    tvdbId: tvdbId,
                    servicePath: servicePath,
                    mediaInfo: mediaInfo,
                    title: title,
                  ),
                  const SizedBox(height: 24),

                  // Crew (Director, Writer)
                  if (directors.isNotEmpty || writers.isNotEmpty) ...[
                    _buildCrewSection(directors, writers),
                    const SizedBox(height: 24),
                  ],

                  // Overview
                  if (overview.isNotEmpty) ...[
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overview,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Keywords
                  if (keywords.isNotEmpty) ...[
                    Text('Tags', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: keywords
                          .map(
                            (k) => Chip(
                              label: Text(k['name'] ?? ''),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Cast
                  if (cast.isNotEmpty) ...[
                    Text('Cast', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),

          // Cast horizontal list
          if (cast.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: cast.length,
                  itemBuilder: (context, index) {
                    final member = cast[index];
                    final name = member['name'] ?? '';
                    final character = member['character'] ?? '';
                    final profilePath = member['profilePath'];
                    final imageUrl = profilePath != null
                        ? 'https://image.tmdb.org/t/p/w185$profilePath'
                        : null;

                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl)
                                : null,
                            child: imageUrl == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            character,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(
              height: FloatingNavBarMetrics.getScrollViewBottomPadding(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required bool isInService,
    required bool isAvailable,
    required int? tvdbId,
    required String? servicePath,
    required Map<String, dynamic>? mediaInfo,
    required String title,
  }) {
    final type = widget.mediaType == 'movie' ? 'movie' : 'tv';
    // Show manage button if media has requests or is in service
    final hasMediaInfo = mediaInfo != null && mediaInfo['id'] != null;

    return Column(
      children: [
        // Request button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showRequestSheet(context),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Request'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),

        // Manage button (only when media exists in service/has requests)
        if (hasMediaInfo) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showManageSheet(
                context,
                mediaInfo: mediaInfo,
                title: title,
                tvdbId: tvdbId,
              ),
              icon: const Icon(Icons.settings),
              label: Text(type == 'movie' ? 'Manage Movie' : 'Manage Series'),
            ),
          ),
        ],

        // Open in Radarr/Sonarr button (when media is in the service)
        if (isInService) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openInService(context, type, tvdbId),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                type == 'movie' ? 'Open in Radarr' : 'Open in Sonarr',
              ),
            ),
          ),
        ],

        // Root folder path (when available)
        if (isAvailable && servicePath != null && servicePath.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  servicePath,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCrewSection(List<dynamic> directors, List<dynamic> writers) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (directors.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Director: ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(directors.map((d) => d['name']).join(', ')),
            ],
          ),
        if (writers.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Writer: ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(writers.map((w) => w['name']).join(', ')),
            ],
          ),
      ],
    );
  }

  Future<void> _showRequestSheet(BuildContext context) async {
    final type = widget.mediaType == 'movie' ? 'movie' : 'tv';

    SheetUtils.showSeekarrModalSheet(
      context: context,
      builder: (context) => RequestBottomSheet(
        mediaId: widget.mediaId,
        mediaType: type,
        onRequestComplete: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request submitted successfully!')),
          );
          // Refresh details
          ref.invalidate(
            discoverDetailProvider((id: widget.mediaId, type: type)),
          );
        },
      ),
    );
  }

  void _showManageSheet(
    BuildContext context, {
    required Map<String, dynamic> mediaInfo,
    required String title,
    required int? tvdbId,
  }) {
    final type = widget.mediaType == 'movie' ? 'movie' : 'tv';

    SheetUtils.showSeekarrModalSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ManageMediaSheet(
        mediaInfo: mediaInfo,
        mediaTitle: title,
        mediaType: type,
        tmdbId: widget.mediaId,
        tvdbId: tvdbId,
        onDataChanged: () {
          // Refresh details from Jellyseerr
          ref.invalidate(
            discoverDetailProvider((id: widget.mediaId, type: type)),
          );
          // Also re-check actual library status (Radarr/Sonarr)
          _checkActualLibraryStatus(tvdbId: tvdbId);
        },
      ),
    );
  }

  Future<void> _openInService(
    BuildContext context,
    String type,
    int? tvdbId,
  ) async {
    final settings = ref.read(settingsProvider);

    if (type == 'movie') {
      // Check if Radarr is configured
      if (settings.radarrUrl.isEmpty || settings.radarrApiKey.isEmpty) {
        _showNotConfiguredAlert(context, 'Radarr');
        return;
      }

      // Find movie in Radarr by TMDB ID
      try {
        final radarrService = ref.read(radarrServiceProvider);
        final movie = await radarrService.getMovieByTmdbId(widget.mediaId);
        if (movie != null) {
          if (context.mounted) {
            context.push(
              '/movies/${movie.id}?heroTag=radarr_${movie.id}',
              extra: movie,
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Movie not found in Radarr library'),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } else {
      // Check if Sonarr is configured
      if (settings.sonarrUrl.isEmpty || settings.sonarrApiKey.isEmpty) {
        _showNotConfiguredAlert(context, 'Sonarr');
        return;
      }

      if (tvdbId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('TVDB ID not available')));
        return;
      }

      // Find series in Sonarr by TVDB ID
      try {
        final sonarrService = ref.read(sonarrServiceProvider);
        final series = await sonarrService.getSeriesByTvdbId(tvdbId);
        if (series != null) {
          if (context.mounted) {
            context.push(
              '/series/${series.id}?heroTag=sonarr_${series.id}',
              extra: series,
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Series not found in Sonarr library'),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showNotConfiguredAlert(BuildContext context, String serviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$serviceName Not Configured'),
        content: Text(
          'Please configure $serviceName in Settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getJellyseerrStatus(int? status) {
    if (status == null) return 'Available to Request';
    switch (status) {
      case 1:
        return 'Pending';
      case 2:
        return 'Processing';
      case 3:
        return 'Partial';
      case 4:
      case 5:
        return 'Available';
      default:
        return 'Unknown';
    }
  }
}
