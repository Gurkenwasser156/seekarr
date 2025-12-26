import 'package:flutter/material.dart';
import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';

/// A reusable widget to display file information (path and filename).
///
/// Uses Material Design 3 styling with proper color tokens.
class FileInfoSection extends StatelessWidget {
  final String? path;
  final String? filename;

  const FileInfoSection({super.key, this.path, this.filename});

  @override
  Widget build(BuildContext context) {
    if (path == null && filename == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'File Information',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (path != null) ...[
            _InfoRow(
              label: 'Path',
              value: path!,
              icon: Icons.folder_outlined,
              colorScheme: colorScheme,
            ),
          ],
          if (filename != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              label: 'File',
              value: filename!,
              icon: Icons.description_outlined,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
