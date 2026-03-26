import 'package:flutter/material.dart';

import 'package:seekarr/features/activity/presentation/activity_screen.dart';

/// Tile for a queue item.
class QueueItemTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const QueueItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? 'Unknown';
    final status = item['status'] as String? ?? 'Unknown';

    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Status: $status'),
      leading: const Icon(Icons.download),
    );
  }
}

/// Tile for a history item.
class HistoryItemTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const HistoryItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['sourceTitle'] as String? ?? 'Unknown';
    final eventType = item['eventType'] as String? ?? 'unknown';

    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(eventType),
      leading: const Icon(Icons.history),
    );
  }
}

/// Tile for a blocklist item.
class BlocklistItemTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const BlocklistItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(
        item['sourceTitle'] as String? ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('Blocked'),
      leading: Icon(Icons.block, color: colorScheme.error),
    );
  }
}

/// Tile for a wanted item.
class WantedItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final ServiceType serviceType;

  const WantedItemTile({
    super.key,
    required this.item,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String title;
    String? subtitle;

    if (serviceType == ServiceType.series) {
      final seriesData = item['series'] as Map<String, dynamic>?;
      final seriesTitle = seriesData?['title'] as String? ?? 'Unknown Series';
      final episodeTitle = item['title'] as String? ?? 'Unknown Episode';
      final seasonNumber = item['seasonNumber'] as int? ?? 0;
      final episodeNumber = item['episodeNumber'] as int? ?? 0;

      title =
          '$seasonNumber×${episodeNumber.toString().padLeft(2, '0')} - $episodeTitle';
      subtitle = seriesTitle;
    } else if (serviceType == ServiceType.music) {
      final artistData = item['artist'] as Map<String, dynamic>?;
      final artistName = artistData?['artistName'] as String?;
      title = item['title'] as String? ?? 'Unknown';
      subtitle = artistName;
    } else {
      title = item['title'] as String? ?? 'Unknown';
      subtitle = null;
    }

    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          : null,
      leading: Icon(Icons.warning_amber_rounded, color: colorScheme.tertiary),
    );
  }
}
