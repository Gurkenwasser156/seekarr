import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/utils/sheet_utils.dart';
import 'package:seekarr/core/widgets/header_action_row.dart';
import 'package:seekarr/core/widgets/media_detail_poster_row.dart';
import 'package:seekarr/features/discover/domain/models/discover_detail_model.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_extras_provider.dart';
import 'package:seekarr/features/discover/presentation/discover_details_provider.dart';
import 'package:seekarr/features/discover/presentation/discover_navigation_utils.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_videos_button.dart';
import 'package:seekarr/features/discover/presentation/widgets/manage_media_sheet.dart';
import 'package:seekarr/features/discover/presentation/widgets/request_bottom_sheet.dart';

/// Action buttons for the discover detail screen header.
///
/// Renders a [Column] of [HeaderActionRow] widgets that adapt to
/// the poster row's [collapseFactor].
///
/// Row 1: Request (expanded, OutlinedButton) + Videos (icon-only).
/// Row 2: Manage (expanded) + Open in Service (icon-only). Only shown when applicable.
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

  /// Collapse progress passed through from [MediaDetailPosterRow].
  final double collapseFactor;

  /// Related videos for the Videos icon-only button.
  final List<RelatedVideo> videos;

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
    required this.collapseFactor,
    required this.videos,
  });

  String get _normalizedMediaType => mediaType == 'movie' ? 'movie' : 'tv';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final gap = MediaDetailPosterRow.actionGap(collapseFactor);
    final showManageRow = hasManageableMedia || isInService;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Request + Videos
        HeaderActionRow(
          expanded: HeaderActionRow.glowWrap(
            glowColor: colorScheme.primary,
            child: FilledButton.icon(
              onPressed: () => _showRequestSheet(context, ref),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'Request',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: HeaderActionRow.expandedButtonStyle(),
            ),
          ),
          trailing: videos.isNotEmpty
              ? HeaderActionRow.glowWrap(
                  glowColor: colorScheme.primary,
                  child: DiscoverVideosButton.iconOnly(videos: videos),
                )
              : null,
        ),

        if (showManageRow) ...[
          SizedBox(height: gap),
          // Row 2: Manage + Open in Service
          HeaderActionRow(
            expanded: HeaderActionRow.glowWrap(
              glowColor: colorScheme.primary,
              child: hasManageableMedia
                  ? FilledButton.icon(
                      onPressed: () => _showManageSheet(context, ref),
                      icon: const Icon(Icons.settings),
                      label: Text(
                        _normalizedMediaType == 'movie'
                            ? 'Manage Movie'
                            : 'Manage Series',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                      style: HeaderActionRow.expandedButtonStyle(),
                    )
                  : FilledButton.icon(
                      onPressed: () => _openInService(context, ref),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(
                        _normalizedMediaType == 'movie'
                            ? 'Open in Radarr'
                            : 'Open in Sonarr',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                      style: HeaderActionRow.expandedButtonStyle(),
                    ),
            ),
            trailing: hasManageableMedia && isInService
                ? HeaderActionRow.glowWrap(
                    glowColor: colorScheme.primary,
                    child: FilledButton(
                      onPressed: () => _openInService(context, ref),
                      style: HeaderActionRow.iconOnlyButtonStyle(),
                      child: const Icon(Icons.open_in_new),
                    ),
                  )
                : null,
          ),
        ],
      ],
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
