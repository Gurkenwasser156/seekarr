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

  static final Map<NavTab, FloatingNavDestination> _allDestinations = {
    for (final tab in NavTab.values)
      tab: FloatingNavDestination(
        icon: tab.icon,
        selectedIcon: tab.selectedIcon,
        label: tab.label,
      ),
  };

  static const Map<NavTab, NavigationSection> _refreshSectionsByTab = {
    NavTab.discover: NavigationSection.discover,
    NavTab.movies: NavigationSection.movies,
    NavTab.series: NavigationSection.series,
    NavTab.music: NavigationSection.music,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleTabs = ref.watch(visibleNavTabsProvider);
    final destinations = [
      for (final tab in visibleTabs) _allDestinations[tab]!,
    ];
    final selectedIndex = _calculateSelectedIndex(context, visibleTabs);

    return Scaffold(
      // Extend body behind the nav bar for true floating effect
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
    final String location = GoRouterState.of(context).uri.path;
    final selectedIndex = visibleTabs.indexWhere(
      (tab) => location.startsWith(tab.routePath),
    );

    return selectedIndex >= 0 ? selectedIndex : 0;
  }

  void _onItemTapped(
    int index,
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
    List<NavTab> visibleTabs,
  ) {
    // Add light haptic feedback on tab change
    HapticFeedback.selectionClick();

    final tab = visibleTabs[index];

    // If tapping on the current tab, trigger a refresh
    if (index == currentIndex) {
      final refreshSection = _refreshSectionsByTab[tab];
      if (refreshSection != null) {
        ref.triggerNavigationRefresh(refreshSection);
      }
    }

    // Always navigate (even if same tab, to reset navigation stack)
    context.go(tab.routePath);
  }
}
