import 'package:flutter/material.dart';

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

/// Shows a confirmation dialog for deleting media with optional checkboxes.
Future<DeleteMediaResult> showDeleteMediaDialog({
  required BuildContext context,
  required String title,
  required String mediaType, // 'movie', 'series', or 'artist'
}) async {
  bool deleteFiles = false;
  bool addExclusion = false;

  final result = await showDialog<DeleteMediaResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final serviceName = _getServiceName(mediaType);

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red.shade400),
              const SizedBox(width: 12),
              Expanded(child: Text('Delete $title?')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will remove this $mediaType from $serviceName.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: addExclusion,
                onChanged: (value) =>
                    setState(() => addExclusion = value ?? false),
                title: const Text('Add list exclusion'),
                subtitle: Text(
                  'Prevent this $mediaType from being re-added by lists',
                  style: Theme.of(context).textTheme.bodySmall,
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
                    color: deleteFiles ? Colors.red : null,
                    fontWeight: deleteFiles ? FontWeight.bold : null,
                  ),
                ),
                subtitle: Text(
                  'Permanently delete downloaded files from disk',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: deleteFiles ? Colors.red.shade300 : null,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (deleteFiles) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This cannot be undone!',
                          style: TextStyle(
                            color: Colors.red.shade700,
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
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

String _getServiceName(String mediaType) {
  switch (mediaType) {
    case 'movie':
      return 'Radarr';
    case 'series':
      return 'Sonarr';
    case 'artist':
      return 'Lidarr';
    default:
      return 'the service';
  }
}
