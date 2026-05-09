import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/models/media_preview.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/widgets/app_card.dart';
import 'package:seekarr/core/widgets/async_value_widget.dart';
import 'package:seekarr/core/widgets/content_card.dart';
import 'package:seekarr/core/widgets/section_header.dart';
import 'package:seekarr/features/discover/domain/models/seerr_request.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:seekarr/features/services/presentation/services_provider.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

class ServicesTrendingSection extends ConsumerWidget {
  const ServicesTrendingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PosterSection<MediaPreview>(
      title: 'Trending',
      service: ServiceKey.seerr,
      asyncValue: ref.watch(servicesTrendingProvider),
      serviceName: 'Seerr',
      actionLabel: 'Seerr',
      onAction: () => context.go('/services/seerr'),
      itemTitle: (item) => item.title,
      itemSubtitle: (item) => item.year,
      imageUrl: (item, _) => ImageUtils.buildTmdbPosterUrl(item.posterPath),
      heroTag: (item) => 'services_seerr_${item.mediaType}_${item.id}',
      onTap: (item) => _openSeerrPreview(
        context,
        item,
        heroTag: 'services_seerr_${item.mediaType}_${item.id}',
      ),
    );
  }
}

class ServicesRecentlyAddedMoviesSection extends ConsumerWidget {
  const ServicesRecentlyAddedMoviesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PosterSection<RadarrMovie>(
      title: 'Recently Added · Movies',
      service: ServiceKey.radarr,
      asyncValue: ref.watch(servicesMoviesProvider),
      serviceName: 'Radarr',
      actionLabel: 'See all',
      onAction: () => context.go('/services/radarr/media'),
      itemTitle: (item) => item.title,
      itemSubtitle: (item) => item.year.toString(),
      imageUrl: (item, settings) => ImageUtils.extractPosterUrl(
        item.images,
        baseUrl: settings.radarrUrl,
        apiKey: settings.radarrApiKey,
      ).url,
      heroTag: (item) => 'services_radarr_${item.id}',
      onTap: (item) => context.push(
        '/services/radarr/movie/${item.id}?heroTag=services_radarr_${item.id}',
        extra: item,
      ),
      limit: 8,
    );
  }
}

class ServicesRecentlyAddedSeriesSection extends ConsumerWidget {
  const ServicesRecentlyAddedSeriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PosterSection<SonarrSeries>(
      title: 'Recently Added · Series',
      service: ServiceKey.sonarr,
      asyncValue: ref.watch(servicesSeriesProvider),
      serviceName: 'Sonarr',
      actionLabel: 'See all',
      onAction: () => context.go('/services/sonarr/media'),
      itemTitle: (item) => item.title,
      itemSubtitle: (item) => item.year.toString(),
      imageUrl: (item, settings) => ImageUtils.extractPosterUrl(
        item.images,
        baseUrl: settings.sonarrUrl,
        apiKey: settings.sonarrApiKey,
      ).url,
      heroTag: (item) => 'services_sonarr_${item.id}',
      onTap: (item) => context.push(
        '/services/sonarr/series/${item.id}?heroTag=services_sonarr_${item.id}',
        extra: item,
      ),
      limit: 8,
    );
  }
}

class ServicesRecentRequestsSection extends ConsumerWidget {
  const ServicesRecentRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(servicesRequestsProvider);

    return _ListSection<SeerrRequest>(
      title: 'Recent Requests',
      service: ServiceKey.seerr,
      asyncValue: requests,
      serviceName: 'Seerr',
      actionLabel: 'See all',
      onAction: () => context.go('/services/seerr/requests'),
      emptyLabel: 'No recent requests',
      itemsBuilder: (items) => items.take(3).map(_RequestRow.new).toList(),
    );
  }
}

class ServicesDownloadingSection extends ConsumerWidget {
  const ServicesDownloadingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(servicesQueueProvider);

    return _ListSection<ServiceQueueItem>(
      title: 'Downloading',
      service: ServiceKey.radarr,
      asyncValue: queue,
      serviceName: 'download queue',
      actionLabel: 'Queue',
      onAction: () => context.go('/activity'),
      emptyLabel: 'No active downloads',
      itemsBuilder: (items) => items.map(_DownloadRow.new).toList(),
    );
  }
}

class _PosterSection<T> extends StatelessWidget {
  final String title;
  final ServiceKey service;
  final AsyncValue<List<T>> asyncValue;
  final String serviceName;
  final String actionLabel;
  final VoidCallback onAction;
  final String Function(T item) itemTitle;
  final String Function(T item) itemSubtitle;
  final String Function(T item, SettingsModel settings) imageUrl;
  final String Function(T item)? heroTag;
  final void Function(T item) onTap;
  final int limit;

  const _PosterSection({
    required this.title,
    required this.service,
    required this.asyncValue,
    required this.serviceName,
    required this.actionLabel,
    required this.onAction,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.imageUrl,
    required this.onTap,
    this.heroTag,
    this.limit = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          showChevron: false,
          trailing: _SectionAction(label: actionLabel, color: service.accent),
          onTap: onAction,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 176,
          child: AsyncValueWidget<List<T>>(
            value: asyncValue,
            serviceName: serviceName,
            data: (items) {
              final visibleItems = items.take(limit).toList(growable: false);
              if (visibleItems.isEmpty) {
                return _SectionEmptyState(label: 'No items found');
              }

              return Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(currentSettingsProvider);
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: visibleItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.carouselGap),
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      return _ServicePosterTile(
                        title: itemTitle(item),
                        subtitle: itemSubtitle(item),
                        imageUrl: imageUrl(item, settings),
                        accent: service.accent,
                        heroTag: heroTag?.call(item),
                        onTap: () => onTap(item),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _ListSection<T> extends StatelessWidget {
  final String title;
  final ServiceKey service;
  final AsyncValue<List<T>> asyncValue;
  final String serviceName;
  final String actionLabel;
  final VoidCallback onAction;
  final String emptyLabel;
  final List<Widget> Function(List<T> items) itemsBuilder;

  const _ListSection({
    required this.title,
    required this.service,
    required this.asyncValue,
    required this.serviceName,
    required this.actionLabel,
    required this.onAction,
    required this.emptyLabel,
    required this.itemsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          showChevron: false,
          trailing: _SectionAction(label: actionLabel, color: service.accent),
          onTap: onAction,
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AsyncValueWidget<List<T>>(
            value: asyncValue,
            serviceName: serviceName,
            data: (items) {
              final rows = itemsBuilder(items);
              if (rows.isEmpty) {
                return _SectionEmptyState(label: emptyLabel);
              }

              return Column(children: rows);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _ServicePosterTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color accent;
  final String? heroTag;
  final VoidCallback onTap;

  const _ServicePosterTile({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.accent,
    required this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 96,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              height: 138,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _HeroContentCard(
                      heroTag: heroTag,
                      imageUrl: imageUrl,
                    ),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroContentCard extends StatelessWidget {
  final String? heroTag;
  final String imageUrl;

  const _HeroContentCard({required this.heroTag, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final card = ContentCard(imageUrl: imageUrl);
    if (heroTag == null || heroTag!.isEmpty) {
      return card;
    }

    return Hero(tag: heroTag!, child: card);
  }
}

class _RequestRow extends StatelessWidget {
  final SeerrRequest request;

  const _RequestRow(this.request);

  @override
  Widget build(BuildContext context) {
    final media = request.media;
    final title = media?.title ?? 'Unknown Media';
    final requester = request.requestedBy?.displayName ?? 'Unknown';
    final subtitle =
        '$requester · ${request.type == 'tv' ? 'Series' : 'Movie'}';
    final statusColor = _requestStatusColor(request.status);
    final posterUrl = ImageUtils.buildTmdbPosterUrl(media?.posterPath);
    final heroTag = _requestHeroTag(request);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _CompactListRow(
        icon: request.type == 'tv' ? Icons.tv_rounded : Icons.movie_rounded,
        title: title,
        subtitle: subtitle,
        imageUrl: posterUrl,
        heroTag: heroTag,
        trailing: _SmallStatusPill(
          label: request.status.label,
          color: statusColor,
        ),
        onTap: () => _openRequest(context, request, heroTag: heroTag),
      ),
    );
  }

  void _openRequest(
    BuildContext context,
    SeerrRequest request, {
    String? heroTag,
  }) {
    final media = request.media;
    final id = media?.tmdbId ?? media?.id;
    if (id == null || id <= 0) {
      context.go('/services/seerr');
      return;
    }

    final mediaType = request.type == 'tv' ? 'tv' : 'movie';
    final posterUrl = ImageUtils.buildTmdbPosterUrl(media?.posterPath);
    final encodedPosterUrl = Uri.encodeComponent(posterUrl);
    final tag = heroTag ?? 'services_request_${request.id}';
    context.push(
      '/services/seerr/$mediaType/$id?heroTag=$tag&posterUrl=$encodedPosterUrl',
    );
  }
}

class _DownloadRow extends StatelessWidget {
  final ServiceQueueItem item;

  const _DownloadRow(this.item);

  @override
  Widget build(BuildContext context) {
    final percent = item.progress == null
        ? null
        : (item.progress! * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _CompactListRow(
        icon: item.service.icon,
        title: item.title,
        subtitle: item.subtitle,
        trailing: Text(
          percent == null ? 'DL' : '$percent%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: item.service.accent,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        progressValue: item.progress,
        progressColor: item.progress == null ? null : item.service.accent,
        onTap: () => context.go('/activity'),
      ),
    );
  }
}

class _CompactListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? heroTag;
  final Widget trailing;
  final double? progressValue;
  final Color? progressColor;
  final VoidCallback onTap;

  const _CompactListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.imageUrl,
    this.heroTag,
    this.progressValue,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard.surfaceOutlined(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 54,
            child: imageUrl == null || imageUrl!.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : _HeroContentCard(heroTag: heroTag, imageUrl: imageUrl!),
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
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (progressColor != null) ...[
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 3,
                      color: progressColor,
                      backgroundColor: colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    );
  }
}

class _SmallStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallStatusPill({required this.label, required this.color});

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
        ),
      ),
    );
  }
}

class _SectionAction extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionAction({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label →',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  final String label;

  const _SectionEmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

Color _requestStatusColor(RequestStatus status) {
  switch (status) {
    case RequestStatus.approved:
      return AppColors.success;
    case RequestStatus.pendingApproval:
      return AppColors.warning;
    case RequestStatus.declined:
      return AppColors.error;
    case RequestStatus.unknown:
      return AppColors.info;
  }
}

void _openSeerrPreview(
  BuildContext context,
  MediaPreview item, {
  required String heroTag,
}) {
  final posterUrl = ImageUtils.buildTmdbPosterUrl(item.posterPath);
  final encodedPosterUrl = Uri.encodeComponent(posterUrl);
  context.push(
    '/services/seerr/${item.mediaType}/${item.id}?heroTag=$heroTag&posterUrl=$encodedPosterUrl',
  );
}

String _requestHeroTag(SeerrRequest request) =>
    'services_request_${request.id}';

extension on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pendingApproval:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.declined:
        return 'Declined';
      case RequestStatus.unknown:
        return 'Unknown';
    }
  }
}
