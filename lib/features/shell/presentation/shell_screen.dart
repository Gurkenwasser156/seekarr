import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seekarr/core/providers/navigation_refresh_provider.dart';

/// Main shell screen with bottom navigation following Material Design 3.
///
/// Uses outlined icons for unselected state and filled icons for selected state,
/// following M3 navigation bar guidelines.
class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int idx) =>
            _onItemTapped(idx, context, ref, selectedIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Movies',
          ),
          NavigationDestination(
            icon: Icon(Icons.tv_outlined),
            selectedIcon: Icon(Icons.tv),
            label: 'Series',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Music',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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
