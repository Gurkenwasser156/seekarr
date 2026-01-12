import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seekarr/features/discover/data/jellyseerr_service.dart';
import 'package:seekarr/features/discover/domain/models/jellyseerr_request.dart';
import 'package:seekarr/features/discover/presentation/widgets/manage_media_sections.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';

/// Bottom sheet for managing media requests and files via Jellyseerr.
///
/// Shows:
/// - Requests section: list of requests with delete option
/// - Media section: Open in Radarr/Sonarr, Remove from service
/// - Advanced section: Clear all data
class ManageMediaSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> mediaInfo;
  final String mediaTitle;
  final String mediaType; // 'movie' or 'tv'
  final int tmdbId;
  final int? tvdbId;
  final VoidCallback onDataChanged;

  const ManageMediaSheet({
    super.key,
    required this.mediaInfo,
    required this.mediaTitle,
    required this.mediaType,
    required this.tmdbId,
    this.tvdbId,
    required this.onDataChanged,
  });

  @override
  ConsumerState<ManageMediaSheet> createState() => _ManageMediaSheetState();
}

class _ManageMediaSheetState extends ConsumerState<ManageMediaSheet> {
  List<JellyseerrRequest> _requests = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _error;

  int? get _jellyseerrMediaId => widget.mediaInfo['id'] as int?;
  int? get _externalServiceId => widget.mediaInfo['externalServiceId'] as int?;
  bool get _hasExternalService => _externalServiceId != null;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      // Parse requests from mediaInfo
      final requestsData = widget.mediaInfo['requests'] as List<dynamic>? ?? [];
      final requests = requestsData
          .map((r) {
            try {
              return JellyseerrRequest.fromJson(r as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<JellyseerrRequest>()
          .toList();

      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load requests: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRequest(int requestId) async {
    try {
      final service = ref.read(jellyseerrServiceProvider);
      await service.deleteRequest(requestId);
      setState(() {
        _requests.removeWhere((r) => r.id == requestId);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request deleted')));
      }
      widget.onDataChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromService() async {
    final mediaId = _jellyseerrMediaId;
    if (mediaId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove from ${widget.mediaType == 'movie' ? 'Radarr' : 'Sonarr'}',
        ),
        content: Text(
          'This will irreversibly remove this ${widget.mediaType == 'movie' ? 'movie' : 'series'} from '
          '${widget.mediaType == 'movie' ? 'Radarr' : 'Sonarr'}, including all files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final service = ref.read(jellyseerrServiceProvider);
      await service.deleteMediaFile(mediaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.mediaType == 'movie' ? 'Movie' : 'Series'} removed from service',
            ),
          ),
        );
        Navigator.pop(context);
        widget.onDataChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _clearAllData() async {
    final mediaId = _jellyseerrMediaId;
    if (mediaId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Data'),
        content: Text(
          'This will irreversibly remove all data for this ${widget.mediaType == 'movie' ? 'movie' : 'series'}, '
          'including any requests. If this item exists in your Jellyfin library, '
          'the media information will be recreated during the next scan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final service = ref.read(jellyseerrServiceProvider);
      await service.deleteMedia(mediaId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data cleared')));
        Navigator.pop(context);
        widget.onDataChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _openInService() async {
    if (widget.mediaType == 'movie') {
      try {
        final radarrService = ref.read(radarrServiceProvider);
        final movie = await radarrService.getMovieByTmdbId(widget.tmdbId);
        if (movie != null && mounted) {
          Navigator.pop(context);
          context.push(
            '/movies/${movie.id}?heroTag=radarr_${movie.id}',
            extra: movie,
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movie not found in Radarr')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } else {
      if (widget.tvdbId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('TVDB ID not available')));
        return;
      }
      try {
        final sonarrService = ref.read(sonarrServiceProvider);
        final series = await sonarrService.getSeriesByTvdbId(widget.tvdbId!);
        if (series != null && mounted) {
          Navigator.pop(context);
          context.push(
            '/series/${series.id}?heroTag=sonarr_${series.id}',
            extra: series,
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Series not found in Sonarr')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMovie = widget.mediaType == 'movie';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMovie ? 'Manage Movie' : 'Manage Series',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.mediaTitle,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Requests section
                          RequestsSection(
                            requests: _requests,
                            onDeleteRequest: _deleteRequest,
                          ),

                          const SizedBox(height: 24),

                          // Media section
                          MediaSection(
                            isMovie: isMovie,
                            hasExternalService: _hasExternalService,
                            isDeleting: _isDeleting,
                            onOpen: _openInService,
                            onRemove: _removeFromService,
                          ),

                          const SizedBox(height: 24),

                          // Advanced section
                          AdvancedSection(
                            isMovie: isMovie,
                            isDeleting: _isDeleting,
                            onClear: _clearAllData,
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
