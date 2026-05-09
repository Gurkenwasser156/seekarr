import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/features/services/presentation/services_dashboard_sections.dart';
import 'package:seekarr/features/services/presentation/services_provider.dart';
import 'package:seekarr/features/services/presentation/services_status_overview.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = FloatingNavBarMetrics.getScrollViewBottomPadding(
      context,
    );

    ref.listen<int>(navigationRefreshProvider(NavigationSection.services), (
      previous,
      next,
    ) {
      _invalidateServicesDashboard(ref);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: ServicesOnlineSummary(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _invalidateServicesDashboard(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomPadding + AppSpacing.sm),
          children: const [
            ServiceStatusGrid(),
            ServicesTrendingSection(),
            ServicesRecentRequestsSection(),
            ServicesRecentlyAddedMoviesSection(),
            ServicesRecentlyAddedSeriesSection(),
            ServicesDownloadingSection(),
          ],
        ),
      ),
    );
  }
}

void _invalidateServicesDashboard(WidgetRef ref) {
  for (final service in ServiceKey.values) {
    ref.invalidate(serviceSummaryProvider(service));
  }
  ref.invalidate(servicesTrendingProvider);
  ref.invalidate(servicesRequestsProvider);
  ref.invalidate(servicesMoviesProvider);
  ref.invalidate(servicesSeriesProvider);
  ref.invalidate(servicesMusicProvider);
  ref.invalidate(servicesQueueProvider);
}
