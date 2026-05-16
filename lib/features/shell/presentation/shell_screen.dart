import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
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
    final hideBottomNav = _isImportRoute(context);
    final destinations = NavTab.values
        .map(_destinationFor)
        .toList(growable: false);
    final selectedIndex = hideBottomNav ? -1 : _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: !hideBottomNav,
      body: child,
      bottomNavigationBar: hideBottomNav
          ? null
          : FloatingBottomNavBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (int idx) =>
                  _onItemTapped(idx, context, ref, selectedIndex),
              destinations: destinations,
            ),
    );
  }

  static bool _isImportRoute(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return location.startsWith('/import');
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    for (var index = 0; index < NavTab.values.length; index++) {
      final tab = NavTab.values[index];
      if (location.startsWith(tab.routePath)) {
        return index;
      }
    }

    return -1;
  }

  void _onItemTapped(
    int index,
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    HapticFeedback.selectionClick();

    final tab = NavTab.values[index];
    final currentPath = GoRouterState.of(context).uri.path;

    if (index == currentIndex && currentPath == tab.routePath) {
      final section = _refreshSectionFor(tab);
      if (section != null) {
        ref.triggerNavigationRefresh(section);
      }
      return;
    }

    context.go(tab.routePath);
  }

  FloatingNavDestination _destinationFor(NavTab tab) {
    return FloatingNavDestination(
      icon: tab.icon,
      selectedIcon: tab.selectedIcon,
      label: tab.label,
      accentColor: tab.accentColor,
    );
  }

  NavigationSection? _refreshSectionFor(NavTab tab) {
    switch (tab) {
      case NavTab.services:
        return NavigationSection.services;
      case NavTab.activity:
        return NavigationSection.activity;
      case NavTab.search:
        return NavigationSection.search;
      case NavTab.settings:
        return null;
    }
  }
}
