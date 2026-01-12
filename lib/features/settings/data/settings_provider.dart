import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seekarr/features/settings/data/settings_service.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main.dart');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsModel>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<SettingsModel> {
  late final SettingsService _service;

  @override
  SettingsModel build() {
    _service = ref.watch(settingsServiceProvider);
    return _service.loadSettings();
  }

  Future<void> updateSettings(SettingsModel newSettings) async {
    await _service.saveSettings(newSettings);
    state = newSettings;
  }
}
