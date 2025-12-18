import 'package:flutter/material.dart';
import 'package:seekarr/core/widgets/release_list_widgets.dart';

/// A reusable bottom sheet for displaying and selecting releases (Interactive Search).
class InteractiveSearchSheet extends StatelessWidget {
  final List<dynamic> releases;
  final String title;
  final Future<void> Function(String guid, int indexerId) onGrabRelease;

  const InteractiveSearchSheet({
    super.key,
    required this.releases,
    required this.title,
    required this.onGrabRelease,
  });

  /// Shows the interactive search sheet as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required List<dynamic> releases,
    required String title,
    required Future<void> Function(String guid, int indexerId) onGrabRelease,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => InteractiveSearchSheet(
        releases: releases,
        title: title,
        onGrabRelease: onGrabRelease,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${releases.length} releases',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Releases list
            Expanded(
              child: releases.isEmpty
                  ? const Center(child: Text('No releases found'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: releases.length,
                      itemBuilder: (context, index) {
                        final release = releases[index];
                        return ReleaseListItem(
                          release: release,
                          onGrab: () => _handleGrab(context, release),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGrab(BuildContext context, dynamic release) async {
    final guid = release['guid'] as String?;
    final indexerId = release['indexerId'] as int?;
    final releaseTitle = release['title'] as String? ?? 'Release';

    if (guid == null || indexerId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid release data')));
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grab Release'),
        content: Text('Download "$releaseTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await onGrabRelease(guid, indexerId);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Parse error for better user feedback
        final errorStr = e.toString().toLowerCase();
        String message;

        // Extract status code if present
        final codeMatch = RegExp(r'(\d{3})').firstMatch(e.toString());
        final statusCode = codeMatch?.group(1);

        if (errorStr.contains('504') || errorStr.contains('gateway timeout')) {
          message =
              'Indexer timeout - the indexer took too long to respond. (Error 504)';
        } else if (errorStr.contains('500') ||
            errorStr.contains('server error')) {
          // Often means the release is already in queue or file exists
          message =
              'This release may already be downloading or available. Check your download queue.${statusCode != null ? ' (Error $statusCode)' : ''}';
        } else if (errorStr.contains('already')) {
          message = 'This item is already in your library or download queue.';
        } else if (errorStr.contains('disk space') ||
            errorStr.contains('space')) {
          message = 'Not enough disk space for this download.';
        } else if (errorStr.contains('timeout')) {
          message =
              'Request timed out. Please try again.${statusCode != null ? ' (Error $statusCode)' : ''}';
        } else {
          message =
              'Failed to grab release${statusCode != null ? ' (Error $statusCode)' : ''}: ${e.toString().split(':').last.trim()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
