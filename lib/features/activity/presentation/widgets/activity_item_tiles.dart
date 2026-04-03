import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/widgets/media_search_popup_menu.dart';
import 'package:seekarr/core/widgets/status_badge.dart';
import 'package:seekarr/core/widgets/tag_chip.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_formatters.dart';
import 'package:seekarr/features/activity/presentation/widgets/detail_sheets.dart';

class QueueItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final ServiceType serviceType;

  const QueueItemTile({
    super.key,
    required this.item,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedStatus = resolveQueueDisplayStatus(item);
    final title = stringOrNull(item['title']) ?? 'Unknown release';
    final subtitle = _buildMediaContext(serviceType, item);
    final progress = _queueProgress(item);
    final chips = _buildQueueChips(item, colorScheme);
    final hasWarnings = extractStatusMessages(
      item['statusMessages'],
    ).isNotEmpty;
    final showInlineProgress =
        progress != null && resolvedStatus.badge == MediaStatus.downloading;
    final inlineStatus = showInlineProgress
        ? '${resolvedStatus.label} (${(progress * 100).round()}%)'
        : resolvedStatus.label;

    return _TileShell(
      onTap: () => DetailSheets.showQueueDetail(context, item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (subtitle != null) ...[
                          Text(
                            '$subtitle ·',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        Text(
                          inlineStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (hasWarnings) ...[
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: colorScheme.error,
                          ),
                        ],
                        if (showInlineProgress)
                          SizedBox(
                            width: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          _ChipRow(chips: chips),
        ],
      ),
    );
  }
}

class HistoryItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final ServiceType serviceType;

  const HistoryItemTile({
    super.key,
    required this.item,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventType = stringOrNull(item['eventType']) ?? 'unknown';
    final title = _historyTitle(item, serviceType);
    final subtitle = _buildMediaContext(
      serviceType,
      item,
      includePrimaryTitle: false,
    );
    final metadata = joinActivityParts([
      formatDateOnly(stringOrNull(item['date'])),
      _historySizeLabel(item),
    ]);
    final episodeCode = serviceType == ServiceType.series
        ? _historyEpisodeCode(item)
        : null;
    final chips = _buildHistoryChips(item, colorScheme);

    return _TileShell(
      onTap: () => DetailSheets.showHistoryDetail(context, item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (episodeCode != null)
                      TagChip(
                        text: episodeCode,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TagChip(
                text: humanizeEventType(eventType),
                color: _eventTypeColor(eventType),
              ),
            ],
          ),
          if (subtitle != null) _SubtitleText(text: subtitle),
          if (metadata.isNotEmpty)
            _SubtitleText(text: metadata, topSpacing: AppSpacing.sm),
          _ChipRow(chips: chips),
        ],
      ),
    );
  }
}

class BlocklistItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final ServiceType serviceType;

  const BlocklistItemTile({
    super.key,
    required this.item,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = _buildMediaContext(serviceType, item);
    final chips = _buildBlocklistChips(item, colorScheme);
    final reason = _blocklistReason(item);

    return _TileShell(
      onTap: () => DetailSheets.showBlocklistDetail(context, item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleRow(
            title: stringOrNull(item['sourceTitle']) ?? 'Unknown release',
            titleStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            trailing: Icon(
              Icons.block_rounded,
              color: colorScheme.error,
              size: 20,
            ),
          ),
          if (subtitle != null) _SubtitleText(text: subtitle),
          _ChipRow(chips: chips),
          if (reason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatRelativeActivityDate(stringOrNull(item['date'])),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class WantedItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final ServiceType serviceType;
  final VoidCallback? onAutoSearch;
  final VoidCallback? onInteractiveSearch;
  final bool isCutoff;
  final String? qualityProfileName;

  const WantedItemTile({
    super.key,
    required this.item,
    required this.serviceType,
    this.onAutoSearch,
    this.onInteractiveSearch,
    this.isCutoff = false,
    this.qualityProfileName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _wantedTitle(item, serviceType);
    final subtitle = isCutoff && serviceType == ServiceType.movies
        ? null
        : _wantedSubtitle(item, serviceType);
    final statusText = isCutoff
        ? _cutoffHighlightText(item, serviceType)
        : wantedStatusText(item, serviceType);
    final chips = _buildWantedChips(
      item,
      serviceType,
      colorScheme,
      isCutoff: isCutoff,
      qualityProfileName: qualityProfileName,
    );
    final canSearch = onAutoSearch != null && onInteractiveSearch != null;

    return _TileShell(
      onTap: () => DetailSheets.showWantedDetail(context, item, serviceType),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleRow(
            title: title,
            titleStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: isCutoff ? 1 : null,
            trailing: canSearch
                ? MediaSearchPopupMenu(
                    onAutoSearch: onAutoSearch!,
                    onInteractiveSearch: onInteractiveSearch!,
                    iconSize: 18,
                  )
                : null,
          ),
          if (subtitle != null) _SubtitleText(text: subtitle),
          if (statusText != null)
            _SubtitleText(text: statusText, color: colorScheme.error),
          _ChipRow(chips: chips),
        ],
      ),
    );
  }
}

class _TileShell extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TileShell({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SubtitleText extends StatelessWidget {
  final String text;
  final Color? color;
  final double topSpacing;

  const _SubtitleText({
    required this.text,
    this.color,
    this.topSpacing = AppSpacing.xs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topSpacing),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color ?? colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<Widget> chips;

  const _ChipRow({required this.chips});

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: chips,
        ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final Widget? trailing;
  final int? maxLines;

  const _TitleRow({
    required this.title,
    this.titleStyle,
    this.trailing,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: titleStyle,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

List<Widget> _buildQueueChips(
  Map<String, dynamic> item,
  ColorScheme colorScheme,
) {
  final quality = extractQualityName(item);
  final protocol = stringOrNull(item['protocol']);
  final downloadClient = stringOrNull(item['downloadClient']);

  return [
    if (quality != null) TagChip(text: quality),
    if (protocol != null) TagChip(text: protocol, color: AppColors.info),
    if (downloadClient != null)
      TagChip(text: downloadClient, color: colorScheme.tertiary),
  ];
}

List<Widget> _buildHistoryChips(
  Map<String, dynamic> item,
  ColorScheme colorScheme,
) {
  final quality = extractQualityName(item);
  final indexer = stringOrNull(asActivityMap(item['data'])?['indexer']);

  return [
    if (quality != null) TagChip(text: quality),
    if (indexer != null) TagChip(text: indexer, color: colorScheme.tertiary),
  ];
}

List<Widget> _buildBlocklistChips(
  Map<String, dynamic> item,
  ColorScheme colorScheme,
) {
  final protocol = stringOrNull(item['protocol']);
  final indexer = stringOrNull(item['indexer']);

  return [
    if (protocol != null) TagChip(text: protocol, color: AppColors.info),
    if (indexer != null) TagChip(text: indexer, color: colorScheme.tertiary),
  ];
}

List<Widget> _buildWantedChips(
  Map<String, dynamic> item,
  ServiceType serviceType,
  ColorScheme colorScheme, {
  bool isCutoff = false,
  String? qualityProfileName,
}) {
  final monitored = item['monitored'] == false
      ? TagChip(text: 'Unmonitored', color: colorScheme.error)
      : null;
  final quality = switch (serviceType) {
    ServiceType.movies =>
      qualityProfileName ??
          extractQualityName(item, fileKey: 'movieFile') ??
          extractQualityName(item),
    ServiceType.music =>
      extractQualityName(item, fileKey: 'albumFile') ??
          extractQualityName(item),
    _ => extractQualityName(item),
  };
  final date = switch (serviceType) {
    ServiceType.movies => stringOrNull(
      item['airDateUtc'] ?? item['digitalRelease'] ?? item['inCinemas'],
    ),
    ServiceType.music => stringOrNull(item['releaseDate']),
    _ => stringOrNull(item['airDateUtc']),
  };
  final showDateChip = !(isCutoff && serviceType == ServiceType.movies);

  return [
    if (monitored != null) monitored,
    if (quality != null) TagChip(text: quality),
    if (showDateChip && date != null)
      TagChip(text: formatIsoDate(date), color: AppColors.info),
  ];
}

double? _queueProgress(Map<String, dynamic> item) {
  final size = (item['size'] as num?)?.toDouble();
  final sizeLeft = (item['sizeleft'] as num?)?.toDouble();
  if (size == null || size <= 0 || sizeLeft == null) return null;
  return (((size - sizeLeft) / size).clamp(0.0, 1.0) as num).toDouble();
}

String _historyTitle(Map<String, dynamic> item, ServiceType serviceType) {
  final sourceTitle = stringOrNull(item['sourceTitle']) ?? 'Unknown release';
  if (serviceType != ServiceType.movies) return sourceTitle;

  final year = intOrNull(asActivityMap(item['movie'])?['year'] ?? item['year']);
  return year == null ? sourceTitle : '$sourceTitle ($year)';
}

String? _historyEpisodeCode(Map<String, dynamic> item) {
  final episode = asActivityMap(item['episode']);
  return formatEpisodeCode(
    intOrNull(episode?['seasonNumber'] ?? item['seasonNumber']),
    intOrNull(episode?['episodeNumber'] ?? item['episodeNumber']),
  );
}

Color _eventTypeColor(String eventType) {
  switch (eventType) {
    case 'grabbed':
      return AppColors.info;
    case 'downloadFolderImported':
    case 'downloadImported':
      return AppColors.success;
    case 'downloadFailed':
      return AppColors.error;
    case 'episodeFileDeleted':
    case 'movieFileDeleted':
      return AppColors.warning;
    default:
      return AppColors.primaryLight;
  }
}

String? _blocklistReason(Map<String, dynamic> item) {
  final directMessage = stringOrNull(item['message']);
  if (directMessage != null) return directMessage;

  final messages = extractStatusMessages(item['statusMessages']);
  return messages.isEmpty ? null : messages.first;
}

String? _historySizeLabel(Map<String, dynamic> item) {
  final size = formatSizeInGb(
    asActivityMap(item['data'])?['size'] ?? item['size'],
  );
  return size == '—' ? null : size;
}

String? _cutoffHighlightText(
  Map<String, dynamic> item,
  ServiceType serviceType,
) {
  final size = switch (serviceType) {
    ServiceType.movies =>
      item['sizeOnDisk'] ??
          asActivityMap(item['statistics'])?['sizeOnDisk'] ??
          asActivityMap(item['movieFile'])?['size'] ??
          item['size'],
    ServiceType.series =>
      item['sizeOnDisk'] ??
          asActivityMap(item['statistics'])?['sizeOnDisk'] ??
          asActivityMap(item['episodeFile'])?['size'] ??
          item['size'],
    ServiceType.music =>
      item['sizeOnDisk'] ??
          asActivityMap(item['albumFile'])?['size'] ??
          asActivityMap(item['trackFile'])?['size'] ??
          asActivityMap(item['statistics'])?['sizeOnDisk'] ??
          item['size'],
    ServiceType.discover => null,
  };

  final formattedSize = formatSizeInGb(size);
  return formattedSize == '—' ? null : formattedSize;
}

String? _buildMediaContext(
  ServiceType serviceType,
  Map<String, dynamic> item, {
  bool includePrimaryTitle = true,
}) {
  switch (serviceType) {
    case ServiceType.series:
      final series = asActivityMap(item['series']);
      final episode = asActivityMap(item['episode']);
      final episodeCode = formatEpisodeCode(
        intOrNull(episode?['seasonNumber'] ?? item['seasonNumber']),
        intOrNull(episode?['episodeNumber'] ?? item['episodeNumber']),
      );
      final episodeTitle = stringOrNull(episode?['title']);
      final primaryTitle = includePrimaryTitle
          ? stringOrNull(item['title'])
          : null;

      final line = joinActivityParts([
        stringOrNull(series?['title'] ?? item['seriesTitle']),
        episodeCode,
        if (episodeTitle != null && episodeTitle != primaryTitle) episodeTitle,
      ]);
      return line.isEmpty ? null : line;
    case ServiceType.movies:
      final movie = asActivityMap(item['movie']);
      final title = stringOrNull(movie?['title'] ?? item['title']);
      final year = intOrNull(movie?['year'] ?? item['year']);
      if (title == null) return null;
      return year == null ? title : '$title ($year)';
    case ServiceType.music:
      final artist = asActivityMap(item['artist']);
      final album = asActivityMap(item['album']);
      final line = joinActivityParts([
        stringOrNull(artist?['artistName']),
        stringOrNull(album?['title']),
      ]);
      return line.isEmpty ? null : line;
    case ServiceType.discover:
      return null;
  }
}

String _wantedTitle(Map<String, dynamic> item, ServiceType serviceType) {
  switch (serviceType) {
    case ServiceType.movies:
      final title = stringOrNull(item['title']) ?? 'Unknown movie';
      final year = intOrNull(item['year']);
      return year == null ? title : '$title ($year)';
    case ServiceType.music:
      return stringOrNull(item['title']) ?? 'Unknown release';
    case ServiceType.series:
      final episodeCode = formatEpisodeCode(
        intOrNull(item['seasonNumber']),
        intOrNull(item['episodeNumber']),
      );
      final title = joinActivityParts([
        episodeCode,
        stringOrNull(item['title']),
      ]);
      return title.isEmpty ? 'Unknown Episode' : title;
    case ServiceType.discover:
      return stringOrNull(item['title']) ?? 'Unknown';
  }
}

String? _wantedSubtitle(Map<String, dynamic> item, ServiceType serviceType) {
  switch (serviceType) {
    case ServiceType.movies:
      final date = stringOrNull(
        item['airDateUtc'] ?? item['digitalRelease'] ?? item['inCinemas'],
      );
      return date == null ? null : 'Release ${formatIsoDate(date)}';
    case ServiceType.music:
      return stringOrNull(asActivityMap(item['artist'])?['artistName']);
    case ServiceType.series:
      return stringOrNull(asActivityMap(item['series'])?['title']) ??
          'Unknown Series';
    case ServiceType.discover:
      return null;
  }
}
