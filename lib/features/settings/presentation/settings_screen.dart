import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';
import 'package:seekarr/features/settings/presentation/providers/settings_provider.dart';

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
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(onPressed: _saveSettings, icon: const Icon(Icons.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader('Jellyseerr (Discover)'),
            _buildTextField(
              _jellyseerrUrlController,
              'URL',
              'http://localhost:8080',
            ),
            _buildTextField(_jellyseerrApiKeyController, 'API Key', 'xxxxxxxx'),
            const SizedBox(height: 24),
            _buildSectionHeader('Radarr (Movies)'),
            _buildTextField(
              _radarrUrlController,
              'URL',
              'http://localhost:8080',
            ),
            _buildTextField(_radarrApiKeyController, 'API Key', 'xxxxxxxx'),
            const SizedBox(height: 24),
            _buildSectionHeader('Sonarr (Series)'),
            _buildTextField(
              _sonarrUrlController,
              'URL',
              'http://localhost:8080',
            ),
            _buildTextField(_sonarrApiKeyController, 'API Key', 'xxxxxxxx'),
            const SizedBox(height: 24),
            _buildSectionHeader('Lidarr (Music)'),
            _buildTextField(
              _lidarrUrlController,
              'URL',
              'http://localhost:8080',
            ),
            _buildTextField(_lidarrApiKeyController, 'API Key', 'xxxxxxxx'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
