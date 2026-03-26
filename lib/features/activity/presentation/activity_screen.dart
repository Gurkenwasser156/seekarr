import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/features/activity/presentation/widgets/activity_tab.dart';
import 'package:seekarr/features/activity/presentation/widgets/requests_list.dart';
import 'package:seekarr/features/activity/presentation/widgets/wanted_tab.dart';

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
