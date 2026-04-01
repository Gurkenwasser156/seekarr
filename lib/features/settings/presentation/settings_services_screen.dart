import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/nav_tab.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

const _servicesScreenDescription =
    'Choose which services appear in the navigation bar. Discover and '
    'Settings are always visible.';

class SettingsServicesScreen extends ConsumerWidget {
  const SettingsServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              _servicesScreenDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          ...NavTab.hideableValues.map((tab) {
            return SwitchListTile(
              secondary: Icon(tab.icon),
              title: Text(tab.label),
              value: settings.isTabVisible(tab),
              onChanged: (isVisible) =>
                  _updateTabVisibility(ref, settings, tab, isVisible),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _updateTabVisibility(
    WidgetRef ref,
    SettingsModel settings,
    NavTab tab,
    bool isVisible,
  ) async {
    final updatedHiddenTabs = <NavTab>{...settings.hiddenTabs};

    if (isVisible) {
      updatedHiddenTabs.remove(tab);
    } else {
      updatedHiddenTabs.add(tab);
    }

    await ref
        .read(settingsProvider.notifier)
        .updateSettings(settings.copyWith(hiddenTabs: updatedHiddenTabs));
  }
}
