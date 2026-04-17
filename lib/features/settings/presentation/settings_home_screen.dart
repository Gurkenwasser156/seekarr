import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/snack_bar_helper.dart';
import 'package:seekarr/core/widgets/app_card.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/core/widgets/section_header.dart';
import 'package:seekarr/features/settings/data/service_connection_provider.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/nav_tab.dart';
import 'package:seekarr/features/settings/domain/regions.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  static final Uri _githubUri = Uri.parse(
    'https://github.com/matthw-labs/seekarr',
  );
  static final Uri _feedbackUri = Uri(
    scheme: 'mailto',
    path: 'matthw.labs@gmail.com',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final bottomPadding = FloatingNavBarMetrics.getScrollViewBottomPadding(
      context,
    );
    final content = [
      ..._buildGeneralSection(context, settings),
      const SizedBox(height: AppSpacing.lg),
      ..._buildServicesSection(context, ref, settings),
      const SizedBox(height: AppSpacing.lg),
      ..._buildAboutSection(context),
    ];

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
            sliver: SliverList(delegate: SliverChildListDelegate(content)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGeneralSection(
    BuildContext context,
    SettingsModel settings,
  ) {
    return [
      const SectionHeader(title: 'General'),
      const SizedBox(height: AppSpacing.sm),
      SettingsCard(
        leading: const Icon(Icons.language_rounded),
        title: 'Region',
        subtitle: _formatRegionLabel(settings.region),
        onTap: () => context.push('/settings/region'),
      ),
      _sectionCard(
        SettingsCard(
          leading: const Icon(Icons.palette_rounded),
          title: 'Appearance',
          subtitle: settings.themeMode.label,
          onTap: () => context.push('/settings/appearance'),
        ),
      ),
      _sectionCard(
        SettingsCard(
          leading: const Icon(Icons.apps_rounded),
          title: 'Services',
          subtitle: _formatServicesVisibilityLabel(settings),
          onTap: () => context.push('/settings/services'),
        ),
      ),
    ];
  }

  List<Widget> _buildServicesSection(
    BuildContext context,
    WidgetRef ref,
    SettingsModel settings,
  ) {
    return [
      const SectionHeader(title: 'Services'),
      const SizedBox(height: AppSpacing.sm),
      for (final service in ServiceKey.values)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: SettingsCard(
            leading: Icon(service.icon),
            title: service.title,
            subtitle: _getServiceSubtitle(settings, service),
            subtitleLeading: _buildConnectionIndicator(
              context,
              ref,
              settings,
              service,
            ),
            onTap: () =>
                context.push('/settings/service/${service.routeParam}'),
          ),
        ),
    ];
  }

  Widget? _buildConnectionIndicator(
    BuildContext context,
    WidgetRef ref,
    SettingsModel settings,
    ServiceKey service,
  ) {
    // No indicator when the service isn't configured yet.
    if (settings.urlFor(service).isEmpty) {
      return null;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final asyncStatus = ref.watch(serviceConnectionProvider(service));
    const checkingIndicator = SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    final disconnectedIndicator = Icon(
      Icons.cloud_off_rounded,
      size: 16,
      color: colorScheme.error,
    );

    return asyncStatus.when(
      loading: () => checkingIndicator,
      error: (_, __) => disconnectedIndicator,
      data: (status) {
        switch (status) {
          case ServiceConnectionStatus.connected:
            return Icon(
              Icons.cloud_done_rounded,
              size: 16,
              color: colorScheme.primary,
            );
          case ServiceConnectionStatus.disconnected:
            return disconnectedIndicator;
          case ServiceConnectionStatus.checking:
            return checkingIndicator;
          case ServiceConnectionStatus.notConfigured:
            return null;
        }
      },
    );
  }

  List<Widget> _buildAboutSection(BuildContext context) {
    return [
      const SectionHeader(title: 'About'),
      const SizedBox(height: AppSpacing.sm),
      SettingsCard(
        leading: const Icon(Icons.share_rounded),
        title: 'Share App',
        onTap: () => SnackBarHelper.info(context, 'Coming soon!'),
      ),
      _sectionCard(
        SettingsCard(
          leading: const Icon(Icons.code_rounded),
          title: 'GitHub',
          onTap: () => _openGitHub(context),
        ),
      ),
      _sectionCard(
        SettingsCard(
          leading: const Icon(Icons.feedback_rounded),
          title: 'Send Feedback',
          onTap: () => _sendFeedback(context),
        ),
      ),
    ];
  }

  Widget _sectionCard(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: child,
    );
  }

  String _getServiceSubtitle(SettingsModel settings, ServiceKey service) {
    final url = settings.urlFor(service);
    return url.isEmpty ? 'Not configured' : service.extractHost(url) ?? url;
  }

  String _formatRegionLabel(String region) {
    final normalizedRegion = SettingsModel.normalizeRegion(region);
    final regionName = commonRegions[normalizedRegion] ?? normalizedRegion;
    return '$regionName ($normalizedRegion)';
  }

  String _formatServicesVisibilityLabel(SettingsModel settings) {
    final hiddenTabs = NavTab.hideableValues
        .where((tab) => !settings.isTabVisible(tab))
        .map((tab) => tab.label)
        .toList(growable: false);

    if (hiddenTabs.isEmpty) {
      return 'All visible';
    }

    return '${hiddenTabs.join(', ')} hidden';
  }

  Future<void> _openGitHub(BuildContext context) {
    return _launchExternalUri(
      context: context,
      uri: _githubUri,
      failureMessage: 'Unable to open the GitHub repository.',
    );
  }

  Future<void> _sendFeedback(BuildContext context) {
    return _launchExternalUri(
      context: context,
      uri: _feedbackUri,
      failureMessage: 'Unable to open the email composer.',
    );
  }

  Future<void> _launchExternalUri({
    required BuildContext context,
    required Uri uri,
    required String failureMessage,
  }) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      SnackBarHelper.info(context, failureMessage);
    }
  }
}
