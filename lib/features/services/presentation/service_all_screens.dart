import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/utils/route_utils.dart';
import 'package:seekarr/core/utils/string_utils.dart';
import 'package:seekarr/core/widgets/app_card.dart';
import 'package:seekarr/core/widgets/async_value_widget.dart';
import 'package:seekarr/core/widgets/content_card.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/features/discover/domain/models/seerr_request.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:seekarr/features/services/presentation/services_provider.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

class ServiceAllRequestsScreen extends ConsumerWidget {
  const ServiceAllRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(servicesRequestsProvider);

    return Scaffold(
      appBar: _ServiceListAppBar(
        title: 'All Requests',
        backRoute: '/services/seerr',
        accent: ServiceKey.seerr.accent,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(servicesRequestsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom:
                AppSpacing.lg +
                FloatingNavBarMetrics.getScrollViewBottomPadding(context),
          ),
          children: [
            _FilterChipRow(
              accent: ServiceKey.seerr.accent,
              filters: const ['All', 'Pending', 'Approved', 'Declined'],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AsyncValueWidget<List<SeerrRequest>>(
                value: requests,
                serviceName: 'Seerr requests',
                data: (items) {
                  if (items.isEmpty) {
                    return const _EmptyListState(label: 'No requests found');
                  }

                  return Column(
                    children: [
                      for (final request in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _RequestListRow(request: request),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceAllMediaScreen extends ConsumerWidget {
  final ServiceKey service;

  const ServiceAllMediaScreen({super.key, required this.service})
    : assert(service != ServiceKey.seerr);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final media = switch (service) {
      ServiceKey.radarr => ref.watch(servicesMoviesProvider),
      ServiceKey.sonarr => ref.watch(servicesSeriesProvider),
      ServiceKey.lidarr => ref.watch(servicesMusicProvider),
      ServiceKey.seerr => throw StateError('Seerr does not have all media'),
    };

    return Scaffold(
      appBar: _ServiceListAppBar(
        title: _allMediaTitle(service),
        backRoute: '/services/${service.routeParam}',
        accent: service.accent,
        trailing: IconButton(
          icon: Icon(Icons.filter_list_rounded, color: service.accent),
          onPressed: () {},
          tooltip: 'Filters',
        ),
      ),
      body: Column(
        children: [
          _FilterChipRow(accent: service.accent, filters: _filtersFor(service)),
          Expanded(
            child: AsyncValueWidget<List<dynamic>>(
              value: media,
              serviceName: service.title,
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyListState(label: 'No media found');
                }

                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom:
                        AppSpacing.lg +
                        FloatingNavBarMetrics.getScrollViewBottomPadding(
                          context,
                        ),
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.56,
                    crossAxisSpacing: AppSpacing.gridGap,
                    mainAxisSpacing: AppSpacing.gridGap,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _AllMediaTile(
                      service: service,
                      item: item,
                      settings: settings,
                      index: index,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceListAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String backRoute;
  final Color accent;
  final Widget? trailing;

  const _ServiceListAppBar({
    required this.title,
    required this.backRoute,
    required this.accent,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded),
        onPressed: () => RouteUtils.popOrGo(context, backRoute),
        tooltip: 'Back',
      ),
      title: Text(title),
      actions: trailing == null
          ? null
          : [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: trailing!,
              ),
            ],
      titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  final Color accent;
  final List<String> filters;

  const _FilterChipRow({required this.accent, required this.filters});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final selected = index == 0;
          return FilterChip(
            label: Text(filters[index]),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) {},
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : accent,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: accent,
            backgroundColor: accent.withValues(alpha: 0.10),
            side: BorderSide(color: selected ? accent : Colors.transparent),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}

class _RequestListRow extends StatelessWidget {
  final SeerrRequest request;

  const _RequestListRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final media = request.media;
    final title = media?.title ?? 'Unknown Media';
    final requester = request.requestedBy?.displayName ?? 'Unknown';
    final mediaType = request.type == 'tv' ? 'Series' : 'Movie';
    final displayStatus = request.displayStatus;
    final statusColor = _requestStatusColor(displayStatus.kind);
    final posterUrl = ImageUtils.buildTmdbPosterUrl(media?.posterPath);
    final heroTag = 'services_all_request_${request.id}';

    return AppCard.outlined(
      onTap: () => _openRequest(context, request, heroTag: heroTag),
      backgroundColor: colorScheme.surfaceContainer,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            height: 54,
            child: posterUrl.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      request.type == 'tv'
                          ? Icons.tv_rounded
                          : Icons.movie_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : Hero(
                    tag: heroTag,
                    child: ContentCard(imageUrl: posterUrl),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _RequesterAvatar(name: requester),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        requester,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      '·',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      mediaType,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRequestDate(request.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SmallPill(label: displayStatus.label, color: statusColor),
              const SizedBox(height: AppSpacing.sm),
              SizedBox.square(
                dimension: 28,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                  color: AppColors.error,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.10),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {},
                  tooltip: 'Delete request',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRequest(
    BuildContext context,
    SeerrRequest request, {
    required String heroTag,
  }) {
    final media = request.media;
    final id = media?.tmdbId ?? media?.id;
    if (id == null || id <= 0) return;
    final mediaType = request.type == 'tv' ? 'tv' : 'movie';
    final posterUrl = ImageUtils.buildTmdbPosterUrl(media?.posterPath);
    final encodedPosterUrl = Uri.encodeComponent(posterUrl);
    context.push(
      '/services/seerr/$mediaType/$id?heroTag=$heroTag&posterUrl=$encodedPosterUrl',
    );
  }
}

class _RequesterAvatar extends StatelessWidget {
  final String name;

  const _RequesterAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: ServiceKey.seerr.accent.withValues(alpha: 0.14),
        border: Border.all(
          color: ServiceKey.seerr.accent.withValues(alpha: 0.27),
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: ServiceKey.seerr.accent,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AllMediaTile extends StatelessWidget {
  final ServiceKey service;
  final dynamic item;
  final SettingsModel settings;
  final int index;

  const _AllMediaTile({
    required this.service,
    required this.item,
    required this.settings,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final title = _mediaTitle(service, item);
    final subtitle = _mediaSubtitle(service, item);
    final imageSource = _mediaImage(service, item, settings);
    final id = _mediaId(service, item);

    return InkWell(
      onTap: () => context.push(
        _mediaRoute(service, id, heroTag: _mediaHeroTag(service, id, index)),
        extra: item,
      ),
      borderRadius: AppRadius.borderRadiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: _mediaHeroTag(service, id, index),
              child: ContentCard(
                imageUrl: imageSource.url,
                httpHeaders: imageSource.headers,
                badge: _SmallPill(
                  label: _mediaStatusLabel(service, item),
                  color: _mediaStatusColor(service, item),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.borderRadiusSm,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _EmptyListState extends StatelessWidget {
  final String label;

  const _EmptyListState({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

String _formatRequestDate(String value) {
  if (value.trim().isEmpty) return 'Unknown date';
  return formatIsoDate(value);
}

Color _requestStatusColor(SeerrRequestDisplayKind kind) {
  switch (kind) {
    case SeerrRequestDisplayKind.pending:
      return AppColors.warning;
    case SeerrRequestDisplayKind.approved:
    case SeerrRequestDisplayKind.processing:
      return AppColors.info;
    case SeerrRequestDisplayKind.available:
    case SeerrRequestDisplayKind.partiallyAvailable:
    case SeerrRequestDisplayKind.completed:
      return AppColors.success;
    case SeerrRequestDisplayKind.declined:
    case SeerrRequestDisplayKind.failed:
    case SeerrRequestDisplayKind.deleted:
      return AppColors.error;
    case SeerrRequestDisplayKind.unknown:
      return AppColors.info;
  }
}

String _allMediaTitle(ServiceKey service) {
  switch (service) {
    case ServiceKey.radarr:
      return 'All Movies';
    case ServiceKey.sonarr:
      return 'All Series';
    case ServiceKey.lidarr:
      return 'All Artists';
    case ServiceKey.seerr:
      return 'All Media';
  }
}

List<String> _filtersFor(ServiceKey service) {
  switch (service) {
    case ServiceKey.radarr:
      return const ['All', 'Available', 'Missing', 'In Queue'];
    case ServiceKey.sonarr:
      return const ['All', 'Continuing', 'Ended', 'Missing'];
    case ServiceKey.lidarr:
      return const ['All', 'Complete', 'Missing', 'Cutoff'];
    case ServiceKey.seerr:
      return const ['All'];
  }
}

String _mediaTitle(ServiceKey service, dynamic item) {
  return switch (service) {
    ServiceKey.radarr => (item as RadarrMovie).title,
    ServiceKey.sonarr => (item as SonarrSeries).title,
    ServiceKey.lidarr => (item as LidarrArtist).artistName,
    ServiceKey.seerr => 'Unknown',
  };
}

String _mediaSubtitle(ServiceKey service, dynamic item) {
  return switch (service) {
    ServiceKey.radarr => (item as RadarrMovie).year.toString(),
    ServiceKey.sonarr => (item as SonarrSeries).year.toString(),
    ServiceKey.lidarr => _artistStats(item as LidarrArtist),
    ServiceKey.seerr => '',
  };
}

String _artistStats(LidarrArtist artist) {
  final albumText = artist.albumCount == 1
      ? '1 album'
      : '${artist.albumCount} albums';
  final trackText = artist.trackCount == 1
      ? '1 track'
      : '${artist.trackCount} tracks';
  if (artist.albumCount == 0 && artist.trackCount == 0) return artist.status;
  return '$albumText · $trackText';
}

ImageSource _mediaImage(
  ServiceKey service,
  dynamic item,
  SettingsModel settings,
) {
  return switch (service) {
    ServiceKey.radarr => ImageUtils.extractPosterUrl(
      (item as RadarrMovie).images,
      baseUrl: settings.radarrUrl,
      apiKey: settings.radarrApiKey,
    ),
    ServiceKey.sonarr => ImageUtils.extractPosterUrl(
      (item as SonarrSeries).images,
      baseUrl: settings.sonarrUrl,
      apiKey: settings.sonarrApiKey,
    ),
    ServiceKey.lidarr => ImageUtils.extractPosterUrl(
      (item as LidarrArtist).images,
      baseUrl: settings.lidarrUrl,
      apiKey: settings.lidarrApiKey,
      coverTypes: const ['poster', 'fanart', 'banner'],
    ),
    ServiceKey.seerr => (url: '', headers: null),
  };
}

int _mediaId(ServiceKey service, dynamic item) {
  return switch (service) {
    ServiceKey.radarr => (item as RadarrMovie).id,
    ServiceKey.sonarr => (item as SonarrSeries).id,
    ServiceKey.lidarr => (item as LidarrArtist).id,
    ServiceKey.seerr => 0,
  };
}

String _mediaRoute(ServiceKey service, int id, {String? heroTag}) {
  final query = heroTag == null ? '' : '?heroTag=$heroTag';
  return switch (service) {
    ServiceKey.radarr => '/services/radarr/movie/$id$query',
    ServiceKey.sonarr => '/services/sonarr/series/$id$query',
    ServiceKey.lidarr => '/services/lidarr/artist/$id$query',
    ServiceKey.seerr => '/services/seerr',
  };
}

String _mediaHeroTag(ServiceKey service, int id, int index) =>
    'services_${service.routeParam}_media_${id}_$index';

String _mediaStatusLabel(ServiceKey service, dynamic item) {
  return switch (service) {
    ServiceKey.radarr => (item as RadarrMovie).hasFile ? 'Avail' : 'Miss',
    ServiceKey.sonarr => _seriesAvailabilityLabel(item as SonarrSeries),
    ServiceKey.lidarr => (item as LidarrArtist).hasFiles ? 'Avail' : 'Miss',
    ServiceKey.seerr => '',
  };
}

Color _mediaStatusColor(ServiceKey service, dynamic item) {
  final label = _mediaStatusLabel(service, item);
  return switch (label) {
    'Avail' => AppColors.success,
    'Part' => AppColors.info,
    _ => AppColors.error,
  };
}

String _seriesAvailabilityLabel(SonarrSeries series) {
  final stats = series.statistics;
  final fileCount = (stats?['episodeFileCount'] as num?)?.toInt() ?? 0;
  final episodeCount = (stats?['episodeCount'] as num?)?.toInt() ?? 0;
  if (episodeCount > 0 && fileCount >= episodeCount) return 'Avail';
  if (fileCount > 0) return 'Part';
  return 'Miss';
}
