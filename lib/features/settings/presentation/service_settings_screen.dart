import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/section_header.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';

class ServiceSettingsScreen extends ConsumerStatefulWidget {
  final ServiceKey service;

  const ServiceSettingsScreen({super.key, required this.service});

  @override
  ConsumerState<ServiceSettingsScreen> createState() =>
      _ServiceSettingsScreenState();
}

class _ServiceSettingsScreenState extends ConsumerState<ServiceSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _urlController = TextEditingController(text: _getUrlForService(settings));
    _apiKeyController = TextEditingController(
      text: _getApiKeyForService(settings),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  String? _getUrlForService(SettingsModel settings) {
    switch (widget.service) {
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

  String? _getApiKeyForService(SettingsModel settings) {
    switch (widget.service) {
      case ServiceKey.jellyseerr:
        return settings.jellyseerrApiKey;
      case ServiceKey.radarr:
        return settings.radarrApiKey;
      case ServiceKey.sonarr:
        return settings.sonarrApiKey;
      case ServiceKey.lidarr:
        return settings.lidarrApiKey;
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final current = ref.read(settingsProvider);
    final updated = _updateServiceSettings(current);

    await ref.read(settingsProvider.notifier).updateSettings(updated);

    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.service.title} settings saved'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  SettingsModel _updateServiceSettings(SettingsModel current) {
    final url = _urlController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    switch (widget.service) {
      case ServiceKey.jellyseerr:
        return current.copyWith(jellyseerrUrl: url, jellyseerrApiKey: apiKey);
      case ServiceKey.radarr:
        return current.copyWith(radarrUrl: url, radarrApiKey: apiKey);
      case ServiceKey.sonarr:
        return current.copyWith(sonarrUrl: url, sonarrApiKey: apiKey);
      case ServiceKey.lidarr:
        return current.copyWith(lidarrUrl: url, lidarrApiKey: apiKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.service.title} Settings'),
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Service header
            SectionHeader(
              title: widget.service.title,
              trailing: Icon(
                widget.service.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Server URL
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://',
                border: OutlineInputBorder(),
                filled: true,
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Server URL is required';
                }
                final trimmed = value.trim();
                if (!trimmed.startsWith('http://') &&
                    !trimmed.startsWith('https://')) {
                  return 'URL must start with http:// or https://';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // API Key
            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your API key',
                border: const OutlineInputBorder(),
                filled: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyApiKey(),
                  tooltip: 'Copy API key',
                ),
              ),
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _saveSettings(),
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'API Key is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyApiKey() {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: apiKey));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
