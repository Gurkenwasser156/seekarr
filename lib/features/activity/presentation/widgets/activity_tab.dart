import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/features/activity/presentation/activity_provider.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_item_tiles.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_sliver_section.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab_helpers.dart';

class ActivityTab extends ConsumerStatefulWidget {
  final ServiceType serviceType;

  const ActivityTab({super.key, required this.serviceType})
    : assert(
        serviceType != ServiceType.discover,
        'ActivityTab does not support ServiceType.discover.',
      );

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab>
    with ActivityTabHelpers {
  Key _refreshKey = UniqueKey();

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = resolveArrService(ref, widget.serviceType);

    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
      },
      child: CustomScrollView(
        key: _refreshKey,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: AppSpacing.lg)),
          ...buildActivitySliverSection(
            helpers: this,
            context: context,
            title: 'Queue',
            future: service.getQueue(),
            itemBuilder: (item) =>
                QueueItemTile(item: item as Map<String, dynamic>),
          ),
          ...buildActivitySliverSection(
            helpers: this,
            context: context,
            title: 'History',
            future: service.getHistory(),
            itemBuilder: (item) =>
                HistoryItemTile(item: item as Map<String, dynamic>),
          ),
          ...buildActivitySliverSection(
            helpers: this,
            context: context,
            title: 'Blocklist',
            future: service.getBlocklist(),
            itemBuilder: (item) =>
                BlocklistItemTile(item: item as Map<String, dynamic>),
            isLast: true,
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.lg)),
        ],
      ),
    );
  }
}
