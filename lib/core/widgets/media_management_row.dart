import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/media_profile_selector.dart';

/// Shared profile management and delete row for detail screens.
class MediaManagementRow extends StatelessWidget {
  final String currentProfileName;
  final int? currentProfileId;
  final List<Map<String, dynamic>> qualityProfiles;
  final Future<void> Function(int profileId) onProfileSelected;
  final bool isDeleting;
  final VoidCallback? onDelete;
  final String deleteTooltip;

  const MediaManagementRow({
    super.key,
    required this.currentProfileName,
    required this.currentProfileId,
    required this.qualityProfiles,
    required this.onProfileSelected,
    this.isDeleting = false,
    this.onDelete,
    this.deleteTooltip = 'Delete',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: MediaProfileSelector.split(
            currentProfileName: currentProfileName,
            currentProfileId: currentProfileId,
            qualityProfiles: qualityProfiles,
            onProfileSelected: onProfileSelected,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        IconButton(
          onPressed: isDeleting ? null : onDelete,
          icon: isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline_rounded),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderRadiusSm,
            ),
          ),
          tooltip: deleteTooltip,
        ),
      ],
    );
  }
}
