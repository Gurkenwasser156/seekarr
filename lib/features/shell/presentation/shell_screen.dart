import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/nav_tab.dart';

/// Main shell screen with floating bottom navigation.
///
/// Uses a custom [FloatingBottomNavBar] with rounded corners and floating design.
/// Outlined icons for unselected state and filled icons for selected state.
class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleTabs = ref.watch(visibleNavTabsProvider);
    final destinations = visibleTabs
        .map(_destinationFor)
        .toList(growable: false);
    final selectedIndex = _calculateSelectedIndex(context, visibleTabs);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: FloatingBottomNavBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int idx) =>
            _onItemTapped(idx, context, ref, selectedIndex, visibleTabs),
        destinations: destinations,
      ),
    );
  }

  static int _calculateSelectedIndex(
    BuildContext context,
    List<NavTab> visibleTabs,
  ) {
    final location = GoRouterState.of(context).uri.path;

    for (var index = 0; index < visibleTabs.length; index++) {
      if (location.startsWith(visibleTabs[index].routePath)) {
        return index;
      }
    }

    return 0;
  }

  void _onItemTapped(
    int index,
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
    List<NavTab> visibleTabs,
  ) {
    HapticFeedback.selectionClick();

    final tab = visibleTabs[index];
    _refreshIfReselected(index, currentIndex, tab, ref);
    context.go(tab.routePath);
  }

  FloatingNavDestination _destinationFor(NavTab tab) {
    return FloatingNavDestination(
      icon: tab.icon,
      selectedIcon: tab.selectedIcon,
      label: tab.label,
    );
  }

  void _refreshIfReselected(
    int index,
    int currentIndex,
    NavTab tab,
    WidgetRef ref,
  ) {
    if (index != currentIndex) {
      return;
    }

    final refreshSection = _refreshSectionFor(tab);
    if (refreshSection != null) {
      ref.triggerNavigationRefresh(refreshSection);
    }
  }

  NavigationSection? _refreshSectionFor(NavTab tab) {
    switch (tab) {
      case NavTab.discover:
        return NavigationSection.discover;
      case NavTab.movies:
        return NavigationSection.movies;
      case NavTab.series:
        return NavigationSection.series;
      case NavTab.music:
        return NavigationSection.music;
      case NavTab.settings:
        return null;
    }
  }
}
