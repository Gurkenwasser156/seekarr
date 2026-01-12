import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';

/// Main shell screen with floating bottom navigation.
///
/// Uses a custom [FloatingBottomNavBar] with rounded corners and floating design.
/// Outlined icons for unselected state and filled icons for selected state.
class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  static const _destinations = [
    FloatingNavDestination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Discover',
    ),
    FloatingNavDestination(
      icon: Icons.movie_outlined,
      selectedIcon: Icons.movie,
      label: 'Movies',
    ),
    FloatingNavDestination(
      icon: Icons.tv_outlined,
      selectedIcon: Icons.tv,
      label: 'Series',
    ),
    FloatingNavDestination(
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music,
      label: 'Music',
    ),
    FloatingNavDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      // Extend body behind the nav bar for true floating effect
      extendBody: true,
      body: child,
      bottomNavigationBar: FloatingBottomNavBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int idx) =>
            _onItemTapped(idx, context, ref, selectedIndex),
        destinations: _destinations,
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/discover')) return 0;
    if (location.startsWith('/movies')) return 1;
    if (location.startsWith('/series')) return 2;
    if (location.startsWith('/music')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(
    int index,
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    // Add light haptic feedback on tab change
    HapticFeedback.selectionClick();

    // Map index to navigation section for refresh trigger
    final sectionMap = {
      0: NavigationSection.discover,
      1: NavigationSection.movies,
      2: NavigationSection.series,
      3: NavigationSection.music,
    };

    // If tapping on the current tab, trigger a refresh
    if (index == currentIndex && sectionMap.containsKey(index)) {
      ref.triggerNavigationRefresh(sectionMap[index]!);
    }

    // Always navigate (even if same tab, to reset navigation stack)
    switch (index) {
      case 0:
        context.go('/discover');
      case 1:
        context.go('/movies');
      case 2:
        context.go('/series');
      case 3:
        context.go('/music');
      case 4:
        context.go('/settings');
    }
  }
}
