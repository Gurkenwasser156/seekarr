import 'package:flutter/material.dart';
import 'package:seekarr/features/discover/domain/models/jellyseerr_request.dart';

class RequestsSection extends StatelessWidget {
  final List<JellyseerrRequest> requests;
  final Function(int) onDeleteRequest;

  const RequestsSection({
    super.key,
    required this.requests,
    required this.onDeleteRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        if (requests.isEmpty)
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
          ...requests.map(
            (request) => _RequestCard(
              request: request,
              onDelete: () => onDeleteRequest(request.id),
            ),
          ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final JellyseerrRequest request;
  final VoidCallback onDelete;

  const _RequestCard({required this.request, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    if (request.is4k) _Badge(text: '4K', color: Colors.amber),
                    _StatusBadge(status: request.status),
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
            onPressed: onDelete,
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
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
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
}

class _StatusBadge extends StatelessWidget {
  final RequestStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
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
}

class MediaSection extends StatelessWidget {
  final bool isMovie;
  final bool hasExternalService;
  final bool isDeleting;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;

  const MediaSection({
    super.key,
    required this.isMovie,
    required this.hasExternalService,
    required this.isDeleting,
    this.onOpen,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            onPressed: hasExternalService ? onOpen : null,
            icon: const Icon(Icons.open_in_new),
            label: Text('Open in $serviceName'),
          ),
        ),
        const SizedBox(height: 12),

        // Remove from service button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: hasExternalService && !isDeleting ? onRemove : null,
            icon: isDeleting
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
}

class AdvancedSection extends StatelessWidget {
  final bool isMovie;
  final bool isDeleting;
  final VoidCallback? onClear;

  const AdvancedSection({
    super.key,
    required this.isMovie,
    required this.isDeleting,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            onPressed: !isDeleting ? onClear : null,
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
