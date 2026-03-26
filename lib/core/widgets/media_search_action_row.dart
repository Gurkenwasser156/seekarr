import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';

/// A shared row for automatic and interactive media search actions.
class MediaSearchActionRow extends StatelessWidget {
  final bool isSearching;
  final bool isLoadingReleases;
  final VoidCallback? onAutomaticSearch;
  final VoidCallback? onInteractiveSearch;

  const MediaSearchActionRow({
    super.key,
    this.isSearching = false,
    this.isLoadingReleases = false,
    this.onAutomaticSearch,
    this.onInteractiveSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isSearching ? null : onAutomaticSearch,
            icon: isSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded),
            label: const Text(
              'Automatic Search',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
            style: ElevatedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoadingReleases ? null : onInteractiveSearch,
            icon: isLoadingReleases
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.list_rounded),
            label: const Text(
              'Interactive Search',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
            style: ElevatedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}
