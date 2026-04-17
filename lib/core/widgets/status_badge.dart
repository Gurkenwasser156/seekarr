import 'package:flutter/material.dart';
import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';

/// Represents the status of a media item.
enum MediaStatus { available, missing, downloading, queued, unknown }

/// A badge widget to display media availability in grids and detail headers.
///
/// Full-size detail badges use a theme-driven translucent scrim treatment
/// while compact poster badges preserve their stronger semantic fill.
class StatusBadge extends StatelessWidget {
  final MediaStatus status;
  final bool compact;
  final _StatusConfig? configOverride;

  const StatusBadge({super.key, required this.status, this.compact = false})
    : configOverride = null;

  const StatusBadge._custom({
    required this.status,
    required this.compact,
    required this.configOverride,
  });

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

  factory StatusBadge.fromSeerr({
    required int? statusCode,
    bool compact = false,
  }) {
    final status = switch (statusCode) {
      5 => MediaStatus.available,
      2 || 4 => MediaStatus.queued,
      3 => MediaStatus.downloading,
      6 => MediaStatus.missing,
      _ => MediaStatus.unknown,
    };

    final config = switch (statusCode) {
      null => const _StatusConfig(
        icon: Icons.add_circle_rounded,
        label: 'Available to Request',
        tone: _StatusTone.primary,
      ),
      2 => const _StatusConfig(
        icon: Icons.schedule_rounded,
        label: 'Pending',
        tone: _StatusTone.warning,
      ),
      3 => const _StatusConfig(
        icon: Icons.sync_rounded,
        label: 'Processing',
        tone: _StatusTone.info,
      ),
      4 => const _StatusConfig(
        icon: Icons.change_circle_rounded,
        label: 'Partially Available',
        tone: _StatusTone.warning,
      ),
      5 => const _StatusConfig(
        icon: Icons.check_circle_rounded,
        label: 'Available',
        tone: _StatusTone.success,
      ),
      6 => const _StatusConfig(
        icon: Icons.delete_rounded,
        label: 'Deleted',
        tone: _StatusTone.error,
      ),
      _ => const _StatusConfig(
        icon: Icons.help_outline_rounded,
        label: 'Unknown',
        tone: _StatusTone.neutral,
      ),
    };

    return StatusBadge._custom(
      status: status,
      compact: compact,
      configOverride: config,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final seekarrColors =
        theme.extension<SeekarrThemeColors>() ??
        SeekarrThemeColors.defaults(
          brightness: theme.brightness,
          colorScheme: colorScheme,
        );
    final config = configOverride ?? _getConfig();
    final accentColor = _resolveToneColor(colorScheme, config.tone);
    final backgroundColor = compact
        ? accentColor.withValues(alpha: 0.9)
        : seekarrColors.statusBadgeBackground;
    final borderColor = compact
        ? accentColor
        : seekarrColors.statusBadgeForeground.withValues(alpha: 0.12);
    final textColor = compact
        ? Colors.white
        : seekarrColors.statusBadgeForeground;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.borderRadiusSm,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: compact ? 10 : 12,
            color: compact ? Colors.white : accentColor,
          ),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              config.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
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
        return const _StatusConfig(
          icon: Icons.check_circle_rounded,
          label: 'Available',
          tone: _StatusTone.success,
        );
      case MediaStatus.missing:
        return const _StatusConfig(
          icon: Icons.cancel_rounded,
          label: 'Missing',
          tone: _StatusTone.error,
        );
      case MediaStatus.downloading:
        return const _StatusConfig(
          icon: Icons.downloading_rounded,
          label: 'Downloading',
          tone: _StatusTone.info,
        );
      case MediaStatus.queued:
        return const _StatusConfig(
          icon: Icons.schedule_rounded,
          label: 'Queued',
          tone: _StatusTone.warning,
        );
      case MediaStatus.unknown:
        return const _StatusConfig(
          icon: Icons.help_outline_rounded,
          label: 'Unknown',
          tone: _StatusTone.neutral,
        );
    }
  }

  Color _resolveToneColor(ColorScheme colorScheme, _StatusTone tone) {
    return switch (tone) {
      _StatusTone.primary => colorScheme.primary,
      _StatusTone.success => AppColors.success,
      _StatusTone.warning => AppColors.warning,
      _StatusTone.info => AppColors.info,
      _StatusTone.error => colorScheme.error,
      _StatusTone.neutral => colorScheme.onSurfaceVariant,
    };
  }
}

class _StatusConfig {
  final IconData icon;
  final String label;
  final _StatusTone tone;

  const _StatusConfig({
    required this.icon,
    required this.label,
    required this.tone,
  });
}

enum _StatusTone { primary, success, warning, info, error, neutral }
