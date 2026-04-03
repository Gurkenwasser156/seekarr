import 'package:flutter/material.dart';

import 'package:seekarr/core/api/base_arr_service.dart';
import 'package:seekarr/core/utils/snack_bar_helper.dart';
import 'package:seekarr/core/widgets/interactive_search_sheet.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_formatters.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';

int? extractWantedItemId(ServiceType serviceType, Map<String, dynamic> item) {
  switch (serviceType) {
    case ServiceType.movies:
      return intOrNull(item['id'] ?? item['movieId']);
    case ServiceType.series:
      return intOrNull(item['id']);
    case ServiceType.music:
      return intOrNull(item['id'] ?? item['albumId']);
    case ServiceType.discover:
      return null;
  }
}

bool canSearchWantedItem(ServiceType serviceType, Map<String, dynamic> item) {
  return extractWantedItemId(serviceType, item) != null;
}

Future<void> runWantedAutoSearch(
  BuildContext context,
  ArrActivityMixin service,
  ServiceType serviceType,
  Map<String, dynamic> item,
) async {
  final itemId = extractWantedItemId(serviceType, item);
  if (itemId == null) return;

  try {
    switch (serviceType) {
      case ServiceType.movies:
        await (service as RadarrService).searchMovie(itemId);
        break;
      case ServiceType.series:
        await (service as SonarrService).searchEpisodes([itemId]);
        break;
      case ServiceType.music:
        await (service as LidarrService).searchAlbums([itemId]);
        break;
      case ServiceType.discover:
        return;
    }

    if (!context.mounted) return;
    SnackBarHelper.success(context, 'Search started');
  } catch (error) {
    if (!context.mounted) return;
    SnackBarHelper.error(context, 'Search failed: $error');
  }
}

Future<void> showWantedInteractiveSearch(
  BuildContext context,
  ArrActivityMixin service,
  ServiceType serviceType,
  Map<String, dynamic> item, {
  String? title,
}) async {
  final itemId = extractWantedItemId(serviceType, item);
  if (itemId == null) return;

  final sheetTitle =
      title ??
      'Releases for ${stringOrNull(item['title']) ?? _fallbackLabel(serviceType)}';

  switch (serviceType) {
    case ServiceType.movies:
      final radarrService = service as RadarrService;
      await InteractiveSearchSheet.showAsync(
        context: context,
        title: sheetTitle,
        fetchReleases: (token) =>
            radarrService.getReleases(itemId, cancelToken: token),
        onGrabRelease: (guid, indexerId) async {
          await radarrService.grabRelease(guid: guid, indexerId: indexerId);
        },
      );
      break;
    case ServiceType.series:
      final sonarrService = service as SonarrService;
      await InteractiveSearchSheet.showAsync(
        context: context,
        title: sheetTitle,
        fetchReleases: (token) =>
            sonarrService.getReleases(episodeId: itemId, cancelToken: token),
        onGrabRelease: (guid, indexerId) async {
          await sonarrService.grabRelease(guid: guid, indexerId: indexerId);
        },
      );
      break;
    case ServiceType.music:
      final lidarrService = service as LidarrService;
      await InteractiveSearchSheet.showAsync(
        context: context,
        title: sheetTitle,
        fetchReleases: (token) =>
            lidarrService.getReleases(albumId: itemId, cancelToken: token),
        onGrabRelease: (guid, indexerId) async {
          await lidarrService.grabRelease(guid: guid, indexerId: indexerId);
        },
      );
      break;
    case ServiceType.discover:
      return;
  }
}

String _fallbackLabel(ServiceType serviceType) {
  switch (serviceType) {
    case ServiceType.movies:
      return 'Movie';
    case ServiceType.series:
      return 'Episode';
    case ServiceType.music:
      return 'Album';
    case ServiceType.discover:
      return 'Item';
  }
}

/// Mixin providing shared async sliver builders for activity tabs.
mixin ActivityTabHelpers {
  Widget buildAsyncContentSliver(
    Future<List<dynamic>> future,
    Widget Function(dynamic item) itemBuilder,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final stateSliver = _buildAsyncStateSliver(context, snapshot);
        if (stateSliver != null) return stateSliver;

        final items = snapshot.data ?? [];

        return SliverList.separated(
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(items[index]),
          separatorBuilder: (context, index) => const Divider(height: 1),
        );
      },
    );
  }

  Widget buildAsyncGroupedContentSliver(
    Future<List<dynamic>> future,
    Widget Function(List<dynamic> items) groupBuilder,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final stateSliver = _buildAsyncStateSliver(context, snapshot);
        if (stateSliver != null) return stateSliver;

        final items = snapshot.data ?? [];

        return SliverToBoxAdapter(child: groupBuilder(items));
      },
    );
  }

  Widget? _buildAsyncStateSliver(
    BuildContext context,
    AsyncSnapshot<List<dynamic>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasError) {
      return _buildMessageSliver(
        context,
        'Error: ${snapshot.error}',
        color: Theme.of(context).colorScheme.error,
        textAlign: TextAlign.center,
      );
    }

    final items = snapshot.data ?? const [];
    if (items.isEmpty) {
      return _buildMessageSliver(
        context,
        'Nothing here',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }

    return null;
  }

  Widget _buildMessageSliver(
    BuildContext context,
    String message, {
    required Color color,
    TextAlign? textAlign,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            style: TextStyle(color: color),
            textAlign: textAlign,
          ),
        ),
      ),
    );
  }
}
