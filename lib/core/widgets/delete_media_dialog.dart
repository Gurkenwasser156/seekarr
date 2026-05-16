import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';

/// Result from the delete confirmation dialog.
class DeleteMediaResult {
  final bool confirmed;
  final bool deleteFiles;
  final bool addExclusion;

  const DeleteMediaResult({
    required this.confirmed,
    this.deleteFiles = false,
    this.addExclusion = false,
  });

  static const cancelled = DeleteMediaResult(confirmed: false);
}

enum DeleteMediaType {
  movie(label: 'movie', serviceName: 'Radarr'),
  series(label: 'series', serviceName: 'Sonarr'),
  artist(label: 'artist', serviceName: 'Lidarr');

  const DeleteMediaType({required this.label, required this.serviceName});

  final String label;
  final String serviceName;
}

/// Shows a confirmation dialog for deleting media with optional checkboxes.
Future<DeleteMediaResult> showDeleteMediaDialog({
  required BuildContext context,
  required String title,
  required DeleteMediaType mediaType,
}) async {
  bool deleteFiles = false;
  bool addExclusion = false;

  final result = await showDialog<DeleteMediaResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final errorColor = colorScheme.error;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: errorColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text('Delete $title?')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will remove this ${mediaType.label} from ${mediaType.serviceName}.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              CheckboxListTile(
                value: addExclusion,
                onChanged: (value) =>
                    setState(() => addExclusion = value ?? false),
                title: const Text('Add list exclusion'),
                subtitle: Text(
                  'Prevent this ${mediaType.label} from being re-added by lists',
                  style: theme.textTheme.bodySmall,
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: deleteFiles,
                onChanged: (value) =>
                    setState(() => deleteFiles = value ?? false),
                title: Text(
                  'Delete files',
                  style: TextStyle(
                    color: deleteFiles ? errorColor : null,
                    fontWeight: deleteFiles ? FontWeight.bold : null,
                  ),
                ),
                subtitle: Text(
                  'Permanently delete downloaded files from disk',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: deleteFiles ? errorColor : null,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (deleteFiles) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.10),
                    borderRadius: AppRadius.borderRadiusSm,
                    border: Border.all(
                      color: errorColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: errorColor, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'This cannot be undone!',
                          style: TextStyle(
                            color: errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, DeleteMediaResult.cancelled),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                DeleteMediaResult(
                  confirmed: true,
                  deleteFiles: deleteFiles,
                  addExclusion: addExclusion,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ),
  );

  return result ?? DeleteMediaResult.cancelled;
}
