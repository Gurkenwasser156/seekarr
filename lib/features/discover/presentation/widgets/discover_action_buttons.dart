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
  final Map<String, dynamic>? mediaInfo;
  final String title;
  final double? voteAverage;
  final Widget? secondaryAction;

  const DiscoverActionButtons({
    super.key,
    required this.mediaId,
    required this.mediaType,
    required this.hasManageableMedia,
    required this.isInService,
    required this.isAvailable,
    required this.tvdbId,
    required this.mediaInfo,
    required this.title,
    required this.voteAverage,
    this.secondaryAction,
  });

  String get _normalizedMediaType => mediaType == 'movie' ? 'movie' : 'tv';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final showOpen = isInService;
    final showManage = hasManageableMedia;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilledButton.icon(
          onPressed: () => _showRequestSheet(context, ref),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Request'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
        if (secondaryAction != null) secondaryAction!,
        if (showOpen) _buildOpenButton(context, ref),
        if (showManage) _buildManageButton(context, ref),
      ],
    );
  }

  Widget _buildOpenButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
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
    return OutlinedButton.icon(
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
