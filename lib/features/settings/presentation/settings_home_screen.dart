import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/section_header.dart';
import 'package:seekarr/core/widgets/app_card.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';

class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final bottomPadding = FloatingNavBarMetrics.getScrollViewBottomPadding(
      context,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              bottomPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Services Section
                const SectionHeader(title: 'Services'),
                const SizedBox(height: AppSpacing.sm),
                ...ServiceKey.values.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SettingsCard(
                      leading: Icon(service.icon),
                      title: service.title,
                      subtitle: _getServiceSubtitle(settings, service),
                      onTap: () => context.push(
                        '/settings/service/${service.routeParam}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // About Section
                const SectionHeader(title: 'About'),
                const SizedBox(height: AppSpacing.sm),
                SettingsCard(
                  leading: const Icon(Icons.share_rounded),
                  title: 'Share App',
                  onTap: () {
                    // TODO: Implement share functionality
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: SettingsCard(
                    leading: const Icon(Icons.code_rounded),
                    title: 'GitHub',
                    onTap: () {
                      // TODO: Implement GitHub link
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: SettingsCard(
                    leading: const Icon(Icons.feedback_rounded),
                    title: 'Send Feedback',
                    onTap: () {
                      // TODO: Implement feedback action
                    },
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceSubtitle(SettingsModel settings, ServiceKey service) {
    final url = _getUrlForService(settings, service);
    if (url == null || url.isEmpty) return 'Not configured';

    final host = service.extractHost(url);
    return host != null ? host : url;
  }

  String? _getUrlForService(SettingsModel settings, ServiceKey service) {
    switch (service) {
      case ServiceKey.jellyseerr:
        return settings.jellyseerrUrl;
      case ServiceKey.radarr:
        return settings.radarrUrl;
      case ServiceKey.sonarr:
        return settings.sonarrUrl;
      case ServiceKey.lidarr:
        return settings.lidarrUrl;
    }
  }
}
