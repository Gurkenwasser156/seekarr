import 'package:flutter/material.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/release_utils.dart';
import 'package:seekarr/core/utils/sheet_utils.dart';
import 'package:seekarr/core/widgets/release_list_widgets.dart';

// Re-export ReleaseSortType for backwards compatibility
export 'package:seekarr/core/utils/release_utils.dart' show ReleaseSortType;

/// A reusable bottom sheet for displaying and selecting releases (Interactive Search).
class InteractiveSearchSheet extends StatefulWidget {
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
    return SheetUtils.showSeekarrModalSheet(
      context: context,
      builder: (context) => InteractiveSearchSheet(
        releases: releases,
        title: title,
        onGrabRelease: onGrabRelease,
      ),
    );
  }

  @override
  State<InteractiveSearchSheet> createState() => _InteractiveSearchSheetState();
}

class _InteractiveSearchSheetState extends State<InteractiveSearchSheet> {
  ReleaseSortType _sortType = ReleaseSortType.score;
  bool _sortAscending = false;
  bool _hideRejected = false;
  String? _selectedIndexer;

  /// Returns filtered and sorted releases using the pure function.
  List<dynamic> get _filteredAndSortedReleases {
    return filterAndSortReleases(
      widget.releases,
      sortType: _sortType,
      sortAscending: _sortAscending,
      hideRejected: _hideRejected,
      selectedIndexer: _selectedIndexer,
    );
  }

  /// Returns unique indexer names from all releases.
  Set<String> get _availableIndexers {
    return extractAvailableIndexers(widget.releases);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredReleases = _filteredAndSortedReleases;

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
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${filteredReleases.length}/${widget.releases.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Sort & Filter controls
            _buildSortFilterBar(context, colorScheme),

            // Releases list
            Expanded(
              child: filteredReleases.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _hideRejected || _selectedIndexer != null
                                ? 'No releases match filters'
                                : 'No releases found',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          if (_hideRejected || _selectedIndexer != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            TextButton(
                              onPressed: () => setState(() {
                                _hideRejected = false;
                                _selectedIndexer = null;
                              }),
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filteredReleases.length,
                      itemBuilder: (context, index) {
                        final release = filteredReleases[index];
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

  Widget _buildSortFilterBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Sort dropdown
            PopupMenuButton<ReleaseSortType>(
              initialValue: _sortType,
              onSelected: (type) => setState(() => _sortType = type),
              child: Chip(
                avatar: Icon(_sortType.icon, size: 18),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_sortType.label),
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => ReleaseSortType.values.map((type) {
                return PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(type.label),
                      if (type == _sortType) ...[
                        const Spacer(),
                        Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Sort direction toggle
            IconButton(
              icon: Icon(
                _sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 20,
              ),
              onPressed: () => setState(() => _sortAscending = !_sortAscending),
              tooltip: _sortAscending ? 'Ascending' : 'Descending',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Hide rejected filter
            FilterChip(
              label: const Text('Hide Rejected'),
              selected: _hideRejected,
              onSelected: (selected) =>
                  setState(() => _hideRejected = selected),
              avatar: _hideRejected
                  ? const Icon(Icons.check_rounded, size: 18)
                  : const Icon(Icons.block_rounded, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Indexer filter
            if (_availableIndexers.length > 1)
              PopupMenuButton<String?>(
                initialValue: _selectedIndexer,
                onSelected: (indexer) =>
                    setState(() => _selectedIndexer = indexer),
                child: Chip(
                  avatar: const Icon(Icons.dns_rounded, size: 18),
                  label: Text(_selectedIndexer ?? 'All Indexers'),
                  deleteIcon: _selectedIndexer != null
                      ? const Icon(Icons.close_rounded, size: 18)
                      : null,
                  onDeleted: _selectedIndexer != null
                      ? () => setState(() => _selectedIndexer = null)
                      : null,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: null,
                    child: Row(
                      children: [
                        const Icon(Icons.all_inclusive_rounded, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('All Indexers'),
                        if (_selectedIndexer == null) ...[
                          const Spacer(),
                          Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  ..._availableIndexers.map((indexer) {
                    return PopupMenuItem(
                      value: indexer,
                      child: Row(
                        children: [
                          const Icon(Icons.dns_outlined, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(indexer),
                          if (indexer == _selectedIndexer) ...[
                            const Spacer(),
                            Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
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
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await widget.onGrabRelease(guid, indexerId);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Download started'),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
