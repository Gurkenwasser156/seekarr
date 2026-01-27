import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';

/// A reusable quality profile selector widget.
///
/// Displays the current profile name and opens a dialog to select a new one.
/// Used in Movie, Series, and Music detail screens to unify profile selection UI.
class MediaProfileSelector extends StatelessWidget {
  /// The currently selected profile name to display.
  final String currentProfileName;

  /// The currently selected profile ID for highlighting in dialog.
  final int? currentProfileId;

  /// List of available quality profiles.
  /// Each map should have 'id' (int) and 'name' (String) keys.
  final List<Map<String, dynamic>> qualityProfiles;

  /// Callback when a new profile is selected.
  /// Called with newly selected profile ID.
  final Future<void> Function(int profileId) onProfileSelected;

  /// Whether to use haptic feedback when opening selector.
  final bool enableHaptics;

  /// Whether to use split button variant.
  final bool isSplit;

  const MediaProfileSelector({
    super.key,
    required this.currentProfileName,
    required this.currentProfileId,
    required this.qualityProfiles,
    required this.onProfileSelected,
    this.enableHaptics = true,
    this.isSplit = false,
  });

  /// Named constructor for split button variant.
  const MediaProfileSelector.split({
    super.key,
    required this.currentProfileName,
    required this.currentProfileId,
    required this.qualityProfiles,
    required this.onProfileSelected,
    this.enableHaptics = true,
  }) : isSplit = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSplit) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: AppRadius.borderRadiusSm,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showProfileSelector(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.sm),
                  bottomLeft: Radius.circular(AppRadius.sm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.high_quality_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          currentProfileName,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            InkWell(
              onTap: () => _showProfileSelector(context),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppRadius.sm),
                bottomRight: Radius.circular(AppRadius.sm),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(Icons.expand_more, size: 20),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _showProfileSelector(context),
      borderRadius: AppRadius.borderRadiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: AppRadius.borderRadiusSm,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.high_quality_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              currentProfileName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.edit_rounded, size: 14, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _showProfileSelector(BuildContext context) async {
    if (qualityProfiles.isEmpty) return;

    if (enableHaptics) {
      HapticFeedback.selectionClick();
    }

    final colorScheme = Theme.of(context).colorScheme;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Quality Profile'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: qualityProfiles.length,
            itemBuilder: (context, index) {
              final profile = qualityProfiles[index];
              final id = profile['id'] as int;
              final name = profile['name'] as String;
              final isSelected = id == currentProfileId;

              return ListTile(
                title: Text(name),
                leading: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.primary,
                      )
                    : Icon(
                        Icons.circle_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                onTap: () => Navigator.pop(context, id),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusSm,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedId != null && selectedId != currentProfileId) {
      await onProfileSelected(selectedId);
    }
  }
}
