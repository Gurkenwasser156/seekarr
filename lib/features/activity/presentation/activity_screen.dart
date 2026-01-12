import 'package:seekarr/features/discover/presentation/discover_provider.dart';
import 'package:seekarr/features/discover/data/jellyseerr_service.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ServiceType { movies, series, music, discover }

class ActivityScreen extends ConsumerWidget {
  final ServiceType serviceType;

  const ActivityScreen({super.key, required this.serviceType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (serviceType == ServiceType.discover) {
      return Scaffold(
        appBar: AppBar(title: const Text('Requests')),
        body: const _RequestsList(),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_getServiceTitle()} Activity'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activity'),
              Tab(text: 'Wanted'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ActivityTab(serviceType: serviceType),
            _WantedTab(serviceType: serviceType),
          ],
        ),
      ),
    );
  }

  String _getServiceTitle() {
    switch (serviceType) {
      case ServiceType.movies:
        return 'Movies';
      case ServiceType.series:
        return 'Series';
      case ServiceType.music:
        return 'Music';
      case ServiceType.discover:
        return 'Requests';
    }
  }
}

class _RequestsList extends ConsumerWidget {
  const _RequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(requestsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(requestsProvider);
      },
      child: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (requests) {
          if (requests.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No requests found'),
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final title = request.media?.title ?? 'Unknown';
              final year = request.media?.year ?? '';
              final status = request.media?.status.label ?? 'Unknown';
              final createdAt =
                  DateTime.tryParse(
                    request.createdAt,
                  )?.toLocal().toString().split(' ')[0] ??
                  request.createdAt;
              final seasons =
                  request.seasons?.map((s) => s.seasonNumber).join(', ') ?? '';
              final profile =
                  request.profileName ??
                  request.profileId?.toString() ??
                  'Default';
              final is4k = request.is4k;
              final type = request.type == 'tv' ? 'TV' : 'Movie';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$title ($year)',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (is4k)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '4K',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Request?'),
                                  content: const Text('This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ref
                                    .read(jellyseerrServiceProvider)
                                    .deleteRequest(request.id);
                                ref.invalidate(requestsProvider);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Type:', type),
                      _buildInfoRow('Status:', status),
                      _buildInfoRow('Date:', createdAt),
                      if (request.type == 'tv' && seasons.isNotEmpty)
                        _buildInfoRow('Seasons:', seasons),
                      _buildInfoRow('Profile:', profile),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _ActivityTab extends ConsumerStatefulWidget {
  final ServiceType serviceType;

  const _ActivityTab({required this.serviceType});

  @override
  ConsumerState<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<_ActivityTab>
    with ActivityTabHelpers {
  Key _refreshKey = UniqueKey();

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = _getQueueProvider();
    final historyAsync = _getHistoryProvider();
    final blocklistAsync = _getBlocklistProvider();

    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
      },
      child: CustomScrollView(
        key: _refreshKey,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: buildSectionHeaderSliver(context, 'Queue'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: buildAsyncSliverList(queueAsync, _buildQueueItem),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: buildSectionHeaderSliver(context, 'History'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: buildAsyncSliverList(historyAsync, _buildHistoryItem),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: buildSectionHeaderSliver(context, 'Blocklist'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: buildAsyncSliverList(blocklistAsync, _buildBlocklistItem),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }

  // Helpers to get futures from providers manually since we are inside a widget
  // and want to combine multiple async calls easily without creating 9 providers.
  // Or we can just read the services directly.
  Future<List<dynamic>> _getQueueProvider() {
    switch (widget.serviceType) {
      case ServiceType.movies:
        return ref.read(radarrServiceProvider).getQueue();
      case ServiceType.series:
        return ref.read(sonarrServiceProvider).getQueue();
      case ServiceType.music:
        return ref.read(lidarrServiceProvider).getQueue();
      case ServiceType.discover:
        return Future.value([]);
    }
  }

  Future<List<dynamic>> _getHistoryProvider() {
    switch (widget.serviceType) {
      case ServiceType.movies:
        return ref.read(radarrServiceProvider).getHistory();
      case ServiceType.series:
        return ref.read(sonarrServiceProvider).getHistory();
      case ServiceType.music:
        return ref.read(lidarrServiceProvider).getHistory();
      case ServiceType.discover:
        return Future.value([]);
    }
  }

  Future<List<dynamic>> _getBlocklistProvider() {
    switch (widget.serviceType) {
      case ServiceType.movies:
        return ref.read(radarrServiceProvider).getBlocklist();
      case ServiceType.series:
        return ref.read(sonarrServiceProvider).getBlocklist();
      case ServiceType.music:
        return ref.read(lidarrServiceProvider).getBlocklist();
      case ServiceType.discover:
        return Future.value([]);
    }
  }

  Widget _buildQueueItem(dynamic item) {
    final title = item['title'] ?? 'Unknown';
    final status = item['status'] ?? 'Unknown';
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Status: $status'),
      leading: const Icon(Icons.download),
    );
  }

  Widget _buildHistoryItem(dynamic item) {
    final title = item['sourceTitle'] ?? 'Unknown';
    final eventType = item['eventType'] ?? 'unknown';
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(eventType),
      leading: const Icon(Icons.history),
    );
  }

  Widget _buildBlocklistItem(dynamic item) {
    final title = item['sourceTitle'] ?? 'Unknown';
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Blocked'),
      leading: const Icon(Icons.block, color: Colors.red),
    );
  }
}

class _WantedTab extends ConsumerStatefulWidget {
  final ServiceType serviceType;

  const _WantedTab({required this.serviceType});

  @override
  ConsumerState<_WantedTab> createState() => _WantedTabState();
}

class _WantedTabState extends ConsumerState<_WantedTab>
    with ActivityTabHelpers {
  Key _refreshKey = UniqueKey();

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final missingAsync = _getMissingProvider();
    final cutoffAsync = _getCutoffProvider();
    final useGrouping = widget.serviceType == ServiceType.series;

    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
      },
      child: CustomScrollView(
        key: _refreshKey,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: buildSectionHeaderSliver(context, 'Missing'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: buildAsyncSliverListWithGrouping(
              missingAsync,
              _buildWantedItem,
              groupingBuilder: useGrouping ? _buildGroupedSeriesList : null,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: buildSectionHeaderSliver(context, 'Cutoff Unmet'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: buildAsyncSliverListWithGrouping(
              cutoffAsync,
              _buildWantedItem,
              groupingBuilder: useGrouping ? _buildGroupedSeriesList : null,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }

  Widget _buildGroupedSeriesList(List<dynamic> items) {
    // Group episodes by series
    final grouped = <String, List<dynamic>>{};
    for (final item in items) {
      // Try multiple paths for series title - API may structure it differently
      String seriesTitle = 'Unknown Series';

      // Try: item['series']['title']
      if (item['series'] != null && item['series']['title'] != null) {
        seriesTitle = item['series']['title'] as String;
      }
      // Try: item['seriesTitle']
      else if (item['seriesTitle'] != null) {
        seriesTitle = item['seriesTitle'] as String;
      }

      grouped.putIfAbsent(seriesTitle, () => []).add(item);
    }

    // Sort groups by series title
    final sortedKeys = grouped.keys.toList()..sort();

    return Column(
      children: sortedKeys.map((seriesTitle) {
        final episodes = grouped[seriesTitle]!;
        // Sort episodes by season and episode number
        episodes.sort((a, b) {
          final seasonA = a['seasonNumber'] as int? ?? 0;
          final seasonB = b['seasonNumber'] as int? ?? 0;
          if (seasonA != seasonB) return seasonA.compareTo(seasonB);
          final epA = a['episodeNumber'] as int? ?? 0;
          final epB = b['episodeNumber'] as int? ?? 0;
          return epA.compareTo(epB);
        });

        return ExpansionTile(
          leading: const Icon(Icons.tv, color: Colors.orange),
          title: Text(
            seriesTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${episodes.length} episode${episodes.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          children: episodes.map((ep) {
            final seasonNum = ep['seasonNumber'] as int? ?? 0;
            final episodeNum = ep['episodeNumber'] as int? ?? 0;
            final epTitle = ep['title'] as String? ?? 'Unknown Episode';
            return ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.orange.shade200,
                child: Text(
                  '$seasonNum',
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ),
              title: Text(
                '${episodeNum.toString().padLeft(2, '0')} - $epTitle',
                style: const TextStyle(fontSize: 14),
              ),
              dense: true,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Future<List<dynamic>> _getMissingProvider() {
    switch (widget.serviceType) {
      case ServiceType.movies:
        return ref.read(radarrServiceProvider).getMissing();
      case ServiceType.series:
        return ref.read(sonarrServiceProvider).getMissing();
      case ServiceType.music:
        return ref.read(lidarrServiceProvider).getMissing();
      case ServiceType.discover:
        return Future.value([]);
    }
  }

  Future<List<dynamic>> _getCutoffProvider() {
    switch (widget.serviceType) {
      case ServiceType.movies:
        return ref.read(radarrServiceProvider).getCutoff();
      case ServiceType.series:
        return ref.read(sonarrServiceProvider).getCutoff();
      case ServiceType.music:
        return ref.read(lidarrServiceProvider).getCutoff();
      case ServiceType.discover:
        return Future.value([]);
    }
  }

  Widget _buildWantedItem(dynamic item) {
    // For series, item contains 'series' object with title
    // For movies, item has direct 'title'
    // For music, item may have 'artist' object

    String title;
    String? subtitle;

    if (widget.serviceType == ServiceType.series) {
      // Episode format: shows episodeTitle, series.title as subtitle
      final seriesData = item['series'] as Map<String, dynamic>?;
      final seriesTitle = seriesData?['title'] as String? ?? 'Unknown Series';
      final episodeTitle = item['title'] as String? ?? 'Unknown Episode';
      final seasonNumber = item['seasonNumber'] as int? ?? 0;
      final episodeNumber = item['episodeNumber'] as int? ?? 0;

      title =
          '$seasonNumber×${episodeNumber.toString().padLeft(2, '0')} - $episodeTitle';
      subtitle = seriesTitle;
    } else if (widget.serviceType == ServiceType.music) {
      // Album/track format
      final artistData = item['artist'] as Map<String, dynamic>?;
      final artistName = artistData?['artistName'] as String?;
      title = item['title'] ?? 'Unknown';
      subtitle = artistName;
    } else {
      title = item['title'] ?? 'Unknown';
      subtitle = null;
    }

    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.grey))
          : null,
      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
    );
  }
}
