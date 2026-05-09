import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/app_card.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

const _servicesScreenDescription =
    'Configure connections for Seerr, Radarr, Sonarr, and Lidarr. The main '
    'navigation now always uses Services, Activity, Search, and Settings.';

class SettingsServicesScreen extends ConsumerWidget {
  const SettingsServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard.outlined(
            backgroundColor: theme.colorScheme.surfaceContainer,
            borderColor: theme.colorScheme.outlineVariant,
            child: Text(
              _servicesScreenDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsGroupCard(
            children: [
              for (final service in ServiceKey.values)
                SettingsCard.grouped(
                  leading: Icon(service.icon),
                  title: service.title,
                  subtitle: _serviceSubtitle(settings, service),
                  accentColor: service.accent,
                  onTap: () =>
                      context.push('/settings/service/${service.routeParam}'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _serviceSubtitle(SettingsModel settings, ServiceKey service) {
    final url = settings.urlFor(service);
    return url.isEmpty ? 'Not configured' : service.extractHost(url) ?? url;
  }
}
