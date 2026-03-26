import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/features/discover/presentation/discover_navigation_utils.dart';
import 'package:seekarr/features/discover/presentation/manage_media_provider.dart';
import 'package:seekarr/features/discover/presentation/widgets/manage_media_sections.dart';

/// Bottom sheet for managing media requests and files via Jellyseerr.
///
/// Shows:
/// - Requests section: list of requests with delete option
/// - Media section: Open in Radarr/Sonarr, Remove from service
/// - Advanced section: Clear all data
class ManageMediaSheet extends ConsumerWidget {
  final Map<String, dynamic> mediaInfo;
  final String mediaTitle;
  final String mediaType; // 'movie' or 'tv'
  final int tmdbId;
  final int? tvdbId;
  final VoidCallback onDataChanged;

  const ManageMediaSheet({
    super.key,
    required this.mediaInfo,
    required this.mediaTitle,
    required this.mediaType,
    required this.tmdbId,
    this.tvdbId,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (
      mediaInfo: mediaInfo,
      mediaType: mediaType,
      tmdbId: tmdbId,
      tvdbId: tvdbId,
    );
    final state = ref.watch(manageMediaProvider(args));
    final notifier = ref.read(manageMediaProvider(args).notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMovie = mediaType == 'movie';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMovie ? 'Manage Movie' : 'Manage Series',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            mediaTitle,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null
                    ? Center(
                        child: Text(
                          state.error!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        children: [
                          RequestsSection(
                            requests: state.requests,
                            onDeleteRequest: (requestId) {
                              _deleteRequest(context, ref, args, requestId);
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          MediaSection(
                            isMovie: isMovie,
                            hasExternalService: notifier.hasExternalService,
                            isDeleting: state.isDeleting,
                            onOpen: () => _openInService(context, ref),
                            onRemove: () {
                              _removeFromService(context, ref, args);
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AdvancedSection(
                            isMovie: isMovie,
                            isDeleting: state.isDeleting,
                            onClear: () {
                              _clearAllData(context, ref, args);
                            },
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteRequest(
    BuildContext context,
    WidgetRef ref,
    ManageMediaArgs args,
    int requestId,
  ) async {
    final notifier = ref.read(manageMediaProvider(args).notifier);
    final error = await notifier.deleteRequest(requestId);
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Request deleted')));
      onDataChanged();
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _removeFromService(
    BuildContext context,
    WidgetRef ref,
    ManageMediaArgs args,
  ) async {
    final notifier = ref.read(manageMediaProvider(args).notifier);
    if (notifier.jellyseerrMediaId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Remove from ${mediaType == 'movie' ? 'Radarr' : 'Sonarr'}',
        ),
        content: Text(
          'This will irreversibly remove this ${mediaType == 'movie' ? 'movie' : 'series'} from '
          '${mediaType == 'movie' ? 'Radarr' : 'Sonarr'}, including all files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final error = await notifier.removeFromService();
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${mediaType == 'movie' ? 'Movie' : 'Series'} removed from service',
          ),
        ),
      );
      Navigator.pop(context);
      onDataChanged();
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _clearAllData(
    BuildContext context,
    WidgetRef ref,
    ManageMediaArgs args,
  ) async {
    final notifier = ref.read(manageMediaProvider(args).notifier);
    if (notifier.jellyseerrMediaId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Data'),
        content: Text(
          'This will irreversibly remove all data for this ${mediaType == 'movie' ? 'movie' : 'series'}, '
          'including any requests. If this item exists in your Jellyfin library, '
          'the media information will be recreated during the next scan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final error = await notifier.clearAllData();
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Data cleared')));
      Navigator.pop(context);
      onDataChanged();
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _openInService(BuildContext context, WidgetRef ref) async {
    await openMediaInService(
      context: context,
      ref: ref,
      mediaType: mediaType,
      tmdbId: tmdbId,
      tvdbId: tvdbId,
      dismissSheet: () => Navigator.pop(context),
      showConfigurationAlert: false,
      movieNotFoundMessage: 'Movie not found in Radarr',
      seriesNotFoundMessage: 'Series not found in Sonarr',
    );
  }
}
