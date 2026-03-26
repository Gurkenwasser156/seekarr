import 'package:flutter/material.dart';

/// Groups series episodes into expansion tiles.
class GroupedSeriesList extends StatelessWidget {
  final List<dynamic> items;

  const GroupedSeriesList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final grouped = <String, List<dynamic>>{};

    for (final item in items) {
      String seriesTitle = 'Unknown Series';

      if (item['series'] != null && item['series']['title'] != null) {
        seriesTitle = item['series']['title'] as String;
      } else if (item['seriesTitle'] != null) {
        seriesTitle = item['seriesTitle'] as String;
      }

      grouped.putIfAbsent(seriesTitle, () => []).add(item);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return Column(
      children: sortedKeys.map((seriesTitle) {
        final episodes = grouped[seriesTitle]!;
        episodes.sort((a, b) {
          final seasonA = a['seasonNumber'] as int? ?? 0;
          final seasonB = b['seasonNumber'] as int? ?? 0;
          if (seasonA != seasonB) {
            return seasonA.compareTo(seasonB);
          }

          final episodeA = a['episodeNumber'] as int? ?? 0;
          final episodeB = b['episodeNumber'] as int? ?? 0;
          return episodeA.compareTo(episodeB);
        });

        return ExpansionTile(
          leading: Icon(Icons.tv, color: colorScheme.tertiary),
          title: Text(
            seriesTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${episodes.length} episode${episodes.length == 1 ? '' : 's'}',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          children: episodes.map((episode) {
            final seasonNum = episode['seasonNumber'] as int? ?? 0;
            final episodeNum = episode['episodeNumber'] as int? ?? 0;
            final episodeTitle =
                episode['title'] as String? ?? 'Unknown Episode';

            return ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.tertiaryContainer,
                child: Text(
                  '$seasonNum',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
              title: Text(
                '${episodeNum.toString().padLeft(2, '0')} - $episodeTitle',
                style: const TextStyle(fontSize: 14),
              ),
              dense: true,
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
