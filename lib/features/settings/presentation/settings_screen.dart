import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';
import 'package:seekarr/features/settings/presentation/providers/settings_provider.dart';

/// Settings screen for configuring service URLs and API keys.
///
/// Uses Material Design 3 styling with grouped card sections.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _jellyseerrUrlController;
  late TextEditingController _jellyseerrApiKeyController;
  late TextEditingController _radarrUrlController;
  late TextEditingController _radarrApiKeyController;
  late TextEditingController _sonarrUrlController;
  late TextEditingController _sonarrApiKeyController;
  late TextEditingController _lidarrUrlController;
  late TextEditingController _lidarrApiKeyController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _jellyseerrUrlController = TextEditingController(
      text: settings.jellyseerrUrl,
    );
    _jellyseerrApiKeyController = TextEditingController(
      text: settings.jellyseerrApiKey,
    );
    _radarrUrlController = TextEditingController(text: settings.radarrUrl);
    _radarrApiKeyController = TextEditingController(
      text: settings.radarrApiKey,
    );
    _sonarrUrlController = TextEditingController(text: settings.sonarrUrl);
    _sonarrApiKeyController = TextEditingController(
      text: settings.sonarrApiKey,
    );
    _lidarrUrlController = TextEditingController(text: settings.lidarrUrl);
    _lidarrApiKeyController = TextEditingController(
      text: settings.lidarrApiKey,
    );
  }

  @override
  void dispose() {
    _jellyseerrUrlController.dispose();
    _jellyseerrApiKeyController.dispose();
    _radarrUrlController.dispose();
    _radarrApiKeyController.dispose();
    _sonarrUrlController.dispose();
    _sonarrApiKeyController.dispose();
    _lidarrUrlController.dispose();
    _lidarrApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    HapticFeedback.mediumImpact();

    if (_formKey.currentState!.validate()) {
      final newSettings = SettingsModel(
        jellyseerrUrl: _jellyseerrUrlController.text.trim(),
        jellyseerrApiKey: _jellyseerrApiKeyController.text.trim(),
        radarrUrl: _radarrUrlController.text.trim(),
        radarrApiKey: _radarrApiKeyController.text.trim(),
        sonarrUrl: _sonarrUrlController.text.trim(),
        sonarrApiKey: _sonarrApiKeyController.text.trim(),
        lidarrUrl: _lidarrUrlController.text.trim(),
        lidarrApiKey: _lidarrApiKeyController.text.trim(),
      );
      await ref.read(settingsProvider.notifier).updateSettings(newSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings saved successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderRadiusMd,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildServiceSection(
              context: context,
              title: 'Jellyseerr',
              subtitle: 'Discovery & Requests',
              icon: Icons.explore_rounded,
              iconColor: colorScheme.primary,
              urlController: _jellyseerrUrlController,
              apiKeyController: _jellyseerrApiKeyController,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildServiceSection(
              context: context,
              title: 'Radarr',
              subtitle: 'Movies',
              icon: Icons.movie_rounded,
              iconColor: Colors.orange,
              urlController: _radarrUrlController,
              apiKeyController: _radarrApiKeyController,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildServiceSection(
              context: context,
              title: 'Sonarr',
              subtitle: 'TV Series',
              icon: Icons.tv_rounded,
              iconColor: Colors.blue,
              urlController: _sonarrUrlController,
              apiKeyController: _sonarrApiKeyController,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildServiceSection(
              context: context,
              title: 'Lidarr',
              subtitle: 'Music',
              icon: Icons.library_music_rounded,
              iconColor: Colors.green,
              urlController: _lidarrUrlController,
              apiKeyController: _lidarrApiKeyController,
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required TextEditingController urlController,
    required TextEditingController apiKeyController,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant),

          // Form fields
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                TextFormField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://localhost:8080',
                    prefixIcon: const Icon(Icons.link_rounded),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Enter API key',
                    prefixIcon: const Icon(Icons.key_rounded),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
