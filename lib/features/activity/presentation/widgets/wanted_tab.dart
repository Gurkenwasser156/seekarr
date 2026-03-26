import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/features/activity/presentation/activity_provider.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_item_tiles.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_sliver_section.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab_helpers.dart';
import 'package:seekarr/features/activity/presentation/widgets/grouped_series_list.dart';

class WantedTab extends ConsumerStatefulWidget {
  final ServiceType serviceType;

  const WantedTab({super.key, required this.serviceType})
    : assert(
        serviceType != ServiceType.discover,
        'WantedTab does not support ServiceType.discover.',
      );

  @override
  ConsumerState<WantedTab> createState() => _WantedTabState();
}

class _WantedTabState extends ConsumerState<WantedTab> with ActivityTabHelpers {
  Key _refreshKey = UniqueKey();

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = resolveArrService(ref, widget.serviceType);
    final useGrouping = widget.serviceType == ServiceType.series;

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
            title: 'Missing',
            future: service.getMissing(),
            itemBuilder: (item) => WantedItemTile(
              item: item as Map<String, dynamic>,
              serviceType: widget.serviceType,
            ),
            groupingBuilder: useGrouping
                ? (items) => GroupedSeriesList(items: items)
                : null,
          ),
          ...buildActivitySliverSection(
            helpers: this,
            context: context,
            title: 'Cutoff Unmet',
            future: service.getCutoff(),
            itemBuilder: (item) => WantedItemTile(
              item: item as Map<String, dynamic>,
              serviceType: widget.serviceType,
            ),
            groupingBuilder: useGrouping
                ? (items) => GroupedSeriesList(items: items)
                : null,
            isLast: true,
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.lg)),
        ],
      ),
    );
  }
}
