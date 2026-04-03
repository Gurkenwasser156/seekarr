import 'package:flutter/material.dart' show IconData, Icons;

enum NavTab {
  discover(
    label: 'Discover',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
    routePath: '/discover',
    canBeHidden: false,
  ),
  movies(
    label: 'Movies',
    icon: Icons.movie_outlined,
    selectedIcon: Icons.movie,
    routePath: '/movies',
  ),
  series(
    label: 'Series',
    icon: Icons.tv_outlined,
    selectedIcon: Icons.tv,
    routePath: '/series',
  ),
  music(
    label: 'Music',
    icon: Icons.library_music_outlined,
    selectedIcon: Icons.library_music,
    routePath: '/music',
  ),
  settings(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    routePath: '/settings',
    canBeHidden: false,
  );

  const NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.routePath,
    this.canBeHidden = true,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String routePath;
  final bool canBeHidden;

  static final Map<String, NavTab> _tabsByName = {
    for (final tab in values) tab.name: tab,
  };

  static List<NavTab> get hideableValues =>
      values.where((tab) => tab.canBeHidden).toList(growable: false);

  static NavTab? fromName(String name) => _tabsByName[name];
}
