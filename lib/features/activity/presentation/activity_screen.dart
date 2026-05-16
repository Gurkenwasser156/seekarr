import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/features/activity/presentation/activity_provider.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_item_tiles.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab.dart';
import 'package:seekarr/features/activity/presentation/widgets/requests_list.dart';
import 'package:seekarr/features/activity/presentation/widgets/wanted_tab.dart';
import 'package:seekarr/features/discover/presentation/discover_provider.dart';
import 'package:seekarr/features/import/presentation/import_service_picker_sheet.dart';

enum ServiceType { movies, series, music, discover }

/// Human-readable display titles for [ServiceType].
extension ServiceTypeDisplay on ServiceType {
  String get displayTitle {
    switch (this) {
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

  bool get supportsArrActivity => this != ServiceType.discover;
}

class ActivityScreen extends ConsumerWidget {
  final ServiceType serviceType;

  const ActivityScreen({super.key, required this.serviceType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!serviceType.supportsArrActivity) {
      return Scaffold(
        appBar: AppBar(title: const Text('Requests')),
        body: const RequestsList(),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${serviceType.displayTitle} Activity'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activity'),
              Tab(text: 'Wanted'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ActivityTab(serviceType: serviceType),
            WantedTab(serviceType: serviceType),
          ],
        ),
      ),
    );
  }
}

class GlobalActivityScreen extends ConsumerStatefulWidget {
  const GlobalActivityScreen({super.key});

  @override
  ConsumerState<GlobalActivityScreen> createState() =>
      _GlobalActivityScreenState();
}

enum _GlobalActivityTab {
  feed('Activity', Icons.bolt_rounded, 'No recent activity'),
  queue('Queue', Icons.downloading_rounded, 'Queue is empty'),
  history('History', Icons.history_rounded, 'No history yet'),
  wanted('Wanted', Icons.manage_search_rounded, 'No wanted items'),
  blocklist('Blocklist', Icons.block_rounded, 'No blocklisted releases'),
  missing('Missing', Icons.warning_amber_rounded, 'No missing items'),
  cutoff('Cutoff', Icons.trending_up_rounded, 'No cutoff unmet items');

  final String label;
  final IconData icon;
  final String emptyMessage;

  const _GlobalActivityTab(this.label, this.icon, this.emptyMessage);
}

class _GlobalActivityScreenState extends ConsumerState<GlobalActivityScreen> {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = FloatingNavBarMetrics.getScrollViewBottomPadding(
      context,
    );

    ref.listen<int>(navigationRefreshProvider(NavigationSection.activity), (
      previous,
      next,
    ) {
      ref.invalidate(requestsProvider);
      ref.read(activityRefreshVersionProvider.notifier).state++;
    });

    return DefaultTabController(
      length: _GlobalActivityTab.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          actions: [
            IconButton(
              tooltip: 'Manual Import',
              icon: const Icon(Icons.download_for_offline_outlined),
              onPressed: () => showImportServicePickerSheet(context),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.radarr,
            indicatorColor: AppColors.radarr,
            tabs: [
              for (final tab in _GlobalActivityTab.values) Tab(text: tab.label),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in _GlobalActivityTab.values)
              _GlobalActivityPane(tab: tab, bottomPadding: bottomPadding),
          ],
        ),
      ),
    );
  }
}

class _GlobalActivityPane extends ConsumerWidget {
  final _GlobalActivityTab tab;
  final double bottomPadding;

  const _GlobalActivityPane({required this.tab, required this.bottomPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = switch (tab) {
      _GlobalActivityTab.feed => ref.watch(globalActivityFeedProvider),
      _GlobalActivityTab.queue => ref.watch(globalQueueItemsProvider),
      _GlobalActivityTab.history => ref.watch(globalHistoryItemsProvider),
      _GlobalActivityTab.wanted => ref.watch(globalWantedItemsProvider),
      _GlobalActivityTab.blocklist => ref.watch(globalBlocklistItemsProvider),
      _GlobalActivityTab.missing => ref.watch(globalMissingItemsProvider),
      _GlobalActivityTab.cutoff => ref.watch(globalCutoffItemsProvider),
    };

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(requestsProvider);
        ref.read(activityRefreshVersionProvider.notifier).state++;
      },
      child: itemsAsync.when(
        loading: () => _ActivityStateList(
          bottomPadding: bottomPadding,
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => _ActivityStateList(
          bottomPadding: bottomPadding,
          child: _ActivityMessage(
            icon: Icons.cloud_off_rounded,
            message: 'Activity unavailable',
            detail: error.toString(),
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _ActivityStateList(
              bottomPadding: bottomPadding,
              child: _ActivityMessage(
                icon: tab.icon,
                message: tab.emptyMessage,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: AppSpacing.md, bottom: bottomPadding),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                GlobalActivityItemTile(item: items[index]),
          );
        },
      ),
    );
  }
}

class _ActivityStateList extends StatelessWidget {
  final double bottomPadding;
  final Widget child;

  const _ActivityStateList({required this.bottomPadding, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [SizedBox(height: 320, child: child)],
    );
  }
}

class _ActivityMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? detail;
  final Color color;

  const _ActivityMessage({
    required this.icon,
    required this.message,
    this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
