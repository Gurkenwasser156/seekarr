import 'package:flutter/material.dart';
import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';

/// Represents the status of a media item.
enum MediaStatus { available, missing, downloading, queued, unknown }

/// A badge widget to display media status on poster cards.
///
/// Uses Material Design 3 styling with semantic colors from the Seerr palette.
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
    final colorScheme = Theme.of(context).colorScheme;
    final config = _getConfig(colorScheme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: AppRadius.borderRadiusSm,
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: compact ? 10 : 12,
            color: config.foregroundColor,
          ),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: config.foregroundColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _getConfig(ColorScheme colorScheme) {
    switch (status) {
      case MediaStatus.available:
        return _StatusConfig(
          backgroundColor: AppColors.success.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          borderColor: AppColors.success,
          icon: Icons.check_circle_rounded,
          label: 'Available',
        );
      case MediaStatus.missing:
        return _StatusConfig(
          backgroundColor: colorScheme.error.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          borderColor: colorScheme.error,
          icon: Icons.cancel_rounded,
          label: 'Missing',
        );
      case MediaStatus.downloading:
        return _StatusConfig(
          backgroundColor: AppColors.info.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          borderColor: AppColors.info,
          icon: Icons.downloading_rounded,
          label: 'Downloading',
        );
      case MediaStatus.queued:
        return _StatusConfig(
          backgroundColor: AppColors.warning.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          borderColor: AppColors.warning,
          icon: Icons.schedule_rounded,
          label: 'Queued',
        );
      case MediaStatus.unknown:
        return _StatusConfig(
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurfaceVariant,
          borderColor: colorScheme.outline,
          icon: Icons.help_outline_rounded,
          label: 'Unknown',
        );
    }
  }
}

class _StatusConfig {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final IconData icon;
  final String label;

  const _StatusConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.icon,
    required this.label,
  });
}
