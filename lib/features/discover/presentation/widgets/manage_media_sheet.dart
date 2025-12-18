import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seekarr/features/discover/data/jellyseerr_service.dart';
import 'package:seekarr/features/discover/domain/models/jellyseerr_request.dart';
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
                          _buildRequestsSection(theme),

                          const SizedBox(height: 24),

                          // Media section
                          _buildMediaSection(theme, isMovie),

                          const SizedBox(height: 24),

                          // Advanced section
                          _buildAdvancedSection(theme, isMovie),

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

  Widget _buildRequestsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requests',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No requests for this media',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...(_requests.map((request) => _buildRequestCard(theme, request))),
      ],
    );
  }

  Widget _buildRequestCard(ThemeData theme, JellyseerrRequest request) {
    String formattedDate = '';
    try {
      final date = DateTime.parse(request.createdAt);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      formattedDate = '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      formattedDate = request.createdAt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Requester info
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      request.requestedBy?.displayName ?? 'Unknown',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Status badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (request.is4k) _buildBadge('4K', Colors.amber),
                    _buildStatusBadge(request.status),
                  ],
                ),

                // Seasons (for TV)
                if (request.seasons != null && request.seasons!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Seasons',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: request.seasons!.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${s.seasonNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 8),

                // Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            onPressed: () => _deleteRequest(request.id),
            icon: const Icon(Icons.delete_outline),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
    Color color;
    String text;

    switch (status) {
      case RequestStatus.approved:
        color = Colors.green;
        text = 'Completed';
        break;
      case RequestStatus.pendingApproval:
        color = Colors.orange;
        text = 'Pending';
        break;
      case RequestStatus.declined:
        color = Colors.red;
        text = 'Declined';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMediaSection(ThemeData theme, bool isMovie) {
    final serviceName = isMovie ? 'Radarr' : 'Sonarr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Open in service button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _hasExternalService ? _openInService : null,
            icon: const Icon(Icons.open_in_new),
            label: Text('Open in $serviceName'),
          ),
        ),
        const SizedBox(height: 12),

        // Remove from service button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _hasExternalService && !_isDeleting
                ? _removeFromService
                : null,
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: Text('Remove from $serviceName'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text(
          '* This will irreversibly remove this ${isMovie ? 'movie' : 'series'} from $serviceName, including all files.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(ThemeData theme, bool isMovie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Clear data button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _jellyseerrMediaId != null && !_isDeleting
                ? _clearAllData
                : null,
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Clear Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text(
          '* This will irreversibly remove all data for this ${isMovie ? 'movie' : 'series'}, '
          'including any requests. If this item exists in your Jellyfin library, '
          'the media information will be recreated during the next scan.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}
