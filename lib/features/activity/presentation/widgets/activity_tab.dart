import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/api/base_arr_service.dart';
import 'package:seekarr/features/activity/presentation/activity_provider.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_item_tiles.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab_helpers.dart';
import 'package:seekarr/features/activity/presentation/widgets/segment_selector.dart';

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
  ActivitySegment _selectedSegment = ActivitySegment.queue;
  Key _refreshKey = UniqueKey();

  void _refresh({ActivitySegment? nextSegment}) {
    setState(() {
      if (nextSegment != null) {
        _selectedSegment = nextSegment;
      }
      _refreshKey = UniqueKey();
    });
  }

  Widget _buildContentSliver(ArrActivityMixin service) {
    switch (_selectedSegment) {
      case ActivitySegment.queue:
        return buildAsyncContentSliver(
          service.getQueue(),
          (item) => QueueItemTile(
            item: item as Map<String, dynamic>,
            serviceType: widget.serviceType,
          ),
        );
      case ActivitySegment.history:
        return buildAsyncContentSliver(
          service.getAllHistory(),
          (item) => HistoryItemTile(
            item: item as Map<String, dynamic>,
            serviceType: widget.serviceType,
          ),
        );
      case ActivitySegment.blocklist:
        return buildAsyncContentSliver(
          service.getBlocklist(),
          (item) => BlocklistItemTile(
            item: item as Map<String, dynamic>,
            serviceType: widget.serviceType,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = resolveArrService(ref, widget.serviceType);

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: CustomScrollView(
        key: _refreshKey,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ActivitySegmentSelector<ActivitySegment>(
            segments: ActivitySegment.values,
            selected: _selectedSegment,
            onChanged: (segment) => _refresh(nextSegment: segment),
            labelBuilder: (segment) => segment.label,
          ),
          _buildContentSliver(service),
        ],
      ),
    );
  }
}
