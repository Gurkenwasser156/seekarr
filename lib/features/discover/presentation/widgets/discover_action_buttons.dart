import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/sheet_utils.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_extras_provider.dart';
import 'package:seekarr/features/discover/presentation/discover_details_provider.dart';
import 'package:seekarr/features/discover/presentation/discover_navigation_utils.dart';
import 'package:seekarr/features/discover/presentation/widgets/manage_media_sheet.dart';
import 'package:seekarr/features/discover/presentation/widgets/request_bottom_sheet.dart';

class DiscoverActionButtons extends ConsumerWidget {
  final int mediaId;
  final String mediaType;
  final bool hasManageableMedia;
  final bool isInService;
  final bool isAvailable;
  final int? tvdbId;
  final String? servicePath;
  final Map<String, dynamic>? mediaInfo;
  final String title;
  final double? voteAverage;

  const DiscoverActionButtons({
    super.key,
    required this.mediaId,
    required this.mediaType,
    required this.hasManageableMedia,
    required this.isInService,
    required this.isAvailable,
    required this.tvdbId,
    required this.servicePath,
    required this.mediaInfo,
    required this.title,
    required this.voteAverage,
  });

  String get _normalizedMediaType => mediaType == 'movie' ? 'movie' : 'tv';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final showOpen = isInService;
    final showManage = hasManageableMedia;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showRequestSheet(context, ref),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Request'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(kMinInteractiveDimension),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ),
        if (showOpen || showManage) ...[
          const SizedBox(height: AppSpacing.md),
          _buildServiceButtons(
            context,
            ref,
            showOpen: showOpen,
            showManage: showManage,
          ),
        ],
        if (isAvailable && servicePath != null && servicePath!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  servicePath!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildServiceButtons(
    BuildContext context,
    WidgetRef ref, {
    required bool showOpen,
    required bool showManage,
  }) {
    if (showOpen && showManage) {
      return Row(
        children: [
          Expanded(child: _buildOpenButton(context, ref)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _buildManageButton(context, ref)),
        ],
      );
    }

    if (showOpen) {
      return SizedBox(
        width: double.infinity,
        child: _buildOpenButton(context, ref),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: _buildManageButton(context, ref),
    );
  }

  Widget _buildOpenButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
      onPressed: () => _openInService(context, ref),
      icon: const Icon(Icons.open_in_new),
      label: Text(
        _normalizedMediaType == 'movie' ? 'Open in Radarr' : 'Open in Sonarr',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  Widget _buildManageButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
      onPressed: () => _showManageSheet(context, ref),
      icon: const Icon(Icons.settings),
      label: Text(
        _normalizedMediaType == 'movie' ? 'Manage Movie' : 'Manage Series',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  void _showRequestSheet(BuildContext context, WidgetRef ref) {
    SheetUtils.showSeekarrModalSheet(
      context: context,
      builder: (sheetContext) => RequestBottomSheet(
        mediaId: mediaId,
        mediaType: _normalizedMediaType,
        onRequestComplete: () {
          if (!context.mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request submitted successfully!')),
          );
          _invalidateDetailProviders(ref);
        },
      ),
    );
  }

  void _showManageSheet(BuildContext context, WidgetRef ref) {
    final currentMediaInfo = mediaInfo;
    if (currentMediaInfo == null) {
      return;
    }

    SheetUtils.showSeekarrModalSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ManageMediaSheet(
        mediaInfo: currentMediaInfo,
        mediaTitle: title,
        mediaType: _normalizedMediaType,
        tmdbId: mediaId,
        tvdbId: tvdbId,
        onDataChanged: () => _invalidateDetailProviders(ref),
      ),
    );
  }

  Future<void> _openInService(BuildContext context, WidgetRef ref) async {
    await openMediaInService(
      context: context,
      ref: ref,
      mediaType: _normalizedMediaType,
      tmdbId: mediaId,
      tvdbId: tvdbId,
    );
  }

  void _invalidateDetailProviders(WidgetRef ref) {
    ref.invalidate(
      discoverDetailProvider((id: mediaId, type: _normalizedMediaType)),
    );
    ref.invalidate(
      discoverDetailExtrasProvider((
        mediaId: mediaId,
        mediaType: _normalizedMediaType,
        tvdbId: tvdbId,
        voteAverage: voteAverage,
      )),
    );
  }
}
