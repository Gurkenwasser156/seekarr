import 'package:flutter/material.dart';

/// Represents the status of a media item.
enum MediaStatus { available, missing, downloading, queued, unknown }

/// A badge widget to display media status on poster cards.
class StatusBadge extends StatelessWidget {
  final MediaStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  /// Creates a StatusBadge from a hasFile boolean and status string.
  factory StatusBadge.fromMedia({
    required bool hasFile,
    required String status,
    bool compact = false,
  }) {
    MediaStatus mediaStatus;
    if (hasFile) {
      mediaStatus = MediaStatus.available;
    } else if (status.toLowerCase() == 'downloading') {
      mediaStatus = MediaStatus.downloading;
    } else if (status.toLowerCase() == 'queued') {
      mediaStatus = MediaStatus.queued;
    } else {
      mediaStatus = MediaStatus.missing;
    }
    return StatusBadge(status: mediaStatus, compact: compact);
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    // Both compact and full mode now show text badge for better visibility
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: compact ? 10 : 12, color: Colors.white),
          if (!compact) ...[
            const SizedBox(width: 3),
            Text(
              config.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _getConfig() {
    switch (status) {
      case MediaStatus.available:
        return _StatusConfig(
          color: Colors.green.shade700,
          icon: Icons.check_circle,
          label: 'Available',
        );
      case MediaStatus.missing:
        return _StatusConfig(
          color: Colors.red.shade700,
          icon: Icons.cancel,
          label: 'Missing',
        );
      case MediaStatus.downloading:
        return _StatusConfig(
          color: Colors.blue.shade700,
          icon: Icons.download,
          label: 'Downloading',
        );
      case MediaStatus.queued:
        return _StatusConfig(
          color: Colors.orange.shade700,
          icon: Icons.schedule,
          label: 'Queued',
        );
      case MediaStatus.unknown:
        return _StatusConfig(
          color: Colors.grey.shade700,
          icon: Icons.help_outline,
          label: 'Unknown',
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}
