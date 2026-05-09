import 'package:flutter/material.dart' show Color, IconData, Icons;

import 'package:seekarr/core/theme.dart';

enum NavTab {
  services(
    label: 'Services',
    icon: Icons.view_list_outlined,
    selectedIcon: Icons.view_list_rounded,
    routePath: '/services',
    accentColor: AppColors.seerr,
  ),
  activity(
    label: 'Activity',
    icon: Icons.monitor_heart_outlined,
    selectedIcon: Icons.monitor_heart_rounded,
    routePath: '/activity',
    accentColor: AppColors.radarr,
  ),
  search(
    label: 'Search',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search_rounded,
    routePath: '/search',
    accentColor: AppColors.seerr,
  ),
  settings(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    routePath: '/settings',
    accentColor: AppColors.onSurfaceVariantDark,
  );

  const NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.routePath,
    required this.accentColor,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String routePath;
  final Color accentColor;

  static final Map<String, NavTab> _tabsByName = {
    for (final tab in values) tab.name: tab,
  };

  static NavTab? fromName(String name) => _tabsByName[name];
}
