import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/api/base_arr_service.dart';
import 'package:seekarr/features/activity/presentation/activity_provider.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_formatters.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_item_tiles.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab_helpers.dart';
import 'package:seekarr/features/activity/presentation/widgets/segment_selector.dart';
import 'package:seekarr/features/activity/presentation/widgets/sonarr_wanted_hierarchy.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';

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
  WantedSegment _selectedSegment = WantedSegment.missing;
  Key _refreshKey = UniqueKey();
  Future<Map<int, String>>? _movieQualityProfilesFuture;

  void _refresh({WantedSegment? nextSegment}) {
    setState(() {
      if (nextSegment != null) {
        _selectedSegment = nextSegment;
      }
      _movieQualityProfilesFuture = null;
      _refreshKey = UniqueKey();
    });
  }

  Future<List<dynamic>> _futureForSegment(ArrActivityMixin service) {
    switch (_selectedSegment) {
      case WantedSegment.missing:
        return service.getAllMissing();
      case WantedSegment.cutoffUnmet:
        return service.getAllCutoff();
    }
  }

  Widget _buildContentSliver(ArrActivityMixin service) {
    final future = _futureForSegment(service);

    if (widget.serviceType == ServiceType.series) {
      return buildAsyncGroupedContentSliver(
        future,
        (items) => SonarrWantedHierarchy(
          items: items,
          service: service as SonarrService,
          isCutoff: _selectedSegment == WantedSegment.cutoffUnmet,
        ),
      );
    }

    if (widget.serviceType == ServiceType.movies &&
        _selectedSegment == WantedSegment.cutoffUnmet) {
      final radarrService = service as RadarrService;
      _movieQualityProfilesFuture ??= _loadMovieQualityProfiles(radarrService);

      return FutureBuilder<Map<int, String>>(
        future: _movieQualityProfilesFuture,
        builder: (context, snapshot) {
          final qualityProfiles = snapshot.data ?? const <int, String>{};

          return _buildWantedListSliver(
            future,
            service,
            qualityProfiles: qualityProfiles,
          );
        },
      );
    }

    return _buildWantedListSliver(future, service);
  }

  Widget _buildWantedListSliver(
    Future<List<dynamic>> future,
    ArrActivityMixin service, {
    Map<int, String> qualityProfiles = const {},
  }) {
    return buildAsyncContentSliver(future, (item) {
      final wantedItem = item as Map<String, dynamic>;
      final canSearch = canSearchWantedItem(widget.serviceType, wantedItem);
      final profileId = intOrNull(wantedItem['qualityProfileId']);

      return WantedItemTile(
        item: wantedItem,
        serviceType: widget.serviceType,
        isCutoff: _selectedSegment == WantedSegment.cutoffUnmet,
        qualityProfileName: profileId == null
            ? null
            : qualityProfiles[profileId],
        onAutoSearch: canSearch
            ? () {
                runWantedAutoSearch(
                  context,
                  service,
                  widget.serviceType,
                  wantedItem,
                );
              }
            : null,
        onInteractiveSearch: canSearch
            ? () {
                showWantedInteractiveSearch(
                  context,
                  service,
                  widget.serviceType,
                  wantedItem,
                );
              }
            : null,
      );
    });
  }

  Future<Map<int, String>> _loadMovieQualityProfiles(
    RadarrService service,
  ) async {
    final profiles = await service.getQualityProfiles();
    final mapped = <int, String>{};

    for (final profile in profiles) {
      final id = intOrNull(profile['id']);
      final name = stringOrNull(profile['name']);
      if (id != null && name != null) {
        mapped[id] = name;
      }
    }

    return mapped;
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
          ActivitySegmentSelector<WantedSegment>(
            segments: WantedSegment.values,
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
