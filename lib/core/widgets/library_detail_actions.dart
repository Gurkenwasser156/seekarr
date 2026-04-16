import 'package:flutter/material.dart';

import 'package:seekarr/core/widgets/header_action_row.dart';
import 'package:seekarr/core/widgets/media_detail_poster_row.dart';
import 'package:seekarr/core/widgets/media_profile_selector.dart';

const _kSpinner = SizedBox.square(
  dimension: 16,
  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
);

/// Shared action buttons for library detail screens (Movies, Series, Music).
///
/// Row 1: Interactive Search (expanded) + Auto Search (icon-only).
/// Row 2: Quality Profile (expanded) + Delete (icon-only, red).
/// Row 2 only appears when [currentProfileName] is non-null.
///
/// All buttons use [FilledButton] with primary background, rounded shape
/// ([AppRadius.xl]), and an Apple TV-style glow effect.
class LibraryDetailActions extends StatelessWidget {
  /// Collapse progress from [MediaDetailPosterRow].
  final double collapseFactor;

  /// Whether a search operation is in progress.
  final bool isSearching;

  /// Whether a delete operation is in progress.
  final bool isDeleting;

  /// Current quality profile name. If null, Row 2 is hidden.
  final String? currentProfileName;

  /// Current quality profile ID for highlighting in the selector.
  final int? currentProfileId;

  /// Available quality profiles for the selector.
  final List<Map<String, dynamic>> qualityProfiles;

  /// Called when the user taps Interactive Search.
  final VoidCallback onInteractiveSearch;

  /// Called when the user taps the Auto Search icon button.
  final VoidCallback onAutoSearch;

  /// Called when a new quality profile is selected.
  final Future<void> Function(int profileId) onProfileSelected;

  /// Called when the user taps the Delete icon button.
  final VoidCallback onDelete;

  const LibraryDetailActions({
    super.key,
    required this.collapseFactor,
    required this.isSearching,
    required this.isDeleting,
    required this.onInteractiveSearch,
    required this.onAutoSearch,
    required this.onProfileSelected,
    required this.onDelete,
    this.currentProfileName,
    this.currentProfileId,
    this.qualityProfiles = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HeaderActionRow(
          expanded: HeaderActionRow.glowWrap(
            glowColor: colorScheme.primary,
            child: FilledButton.icon(
              onPressed: isSearching ? null : onInteractiveSearch,
              icon: isSearching ? _kSpinner : const Icon(Icons.search),
              label: const Text(
                'Interactive Search',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: HeaderActionRow.expandedButtonStyle(),
            ),
          ),
          trailing: HeaderActionRow.glowWrap(
            glowColor: colorScheme.primary,
            child: FilledButton(
              onPressed: isSearching ? null : onAutoSearch,
              style: HeaderActionRow.iconOnlyButtonStyle(),
              child: const Icon(Icons.saved_search),
            ),
          ),
        ),
        if (currentProfileName != null) ...[
          SizedBox(height: MediaDetailPosterRow.actionGap(collapseFactor)),
          HeaderActionRow(
            expanded: HeaderActionRow.glowWrap(
              glowColor: colorScheme.primary,
              child: MediaProfileSelector.split(
                currentProfileName: currentProfileName!,
                currentProfileId: currentProfileId,
                qualityProfiles: qualityProfiles,
                onProfileSelected: onProfileSelected,
              ),
            ),
            trailing: HeaderActionRow.glowWrap(
              glowColor: colorScheme.error,
              child: FilledButton(
                onPressed: isDeleting ? null : onDelete,
                style: HeaderActionRow.iconOnlyButtonStyle(
                  foregroundColor: colorScheme.onError,
                  backgroundColor: colorScheme.error,
                ),
                child: isDeleting
                    ? _kSpinner
                    : const Icon(Icons.delete_outline),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
