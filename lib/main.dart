import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seekarr/core/router.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/data/settings_service.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final secureSettingsStore = _createSecureSettingsStore();
  final settingsService = SettingsService(prefs, secureSettingsStore);

  await settingsService.migrateFromPlaintext();
  final initialSettings = await _loadInitialSettings(settingsService);

  runApp(
    ProviderScope(
      overrides: _buildProviderOverrides(
        prefs: prefs,
        secureSettingsStore: secureSettingsStore,
        initialSettings: initialSettings,
      ),
      child: const SeekarrApp(),
    ),
  );
}

SecureSettingsStore _createSecureSettingsStore() {
  return FlutterSecureSettingsStore(
    FlutterSecureStorage(
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
}

Future<SettingsModel> _loadInitialSettings(SettingsService settingsService) {
  return settingsService.loadSettings();
}

_buildProviderOverrides({
  required SharedPreferences prefs,
  required SecureSettingsStore secureSettingsStore,
  required SettingsModel initialSettings,
}) {
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    secureSettingsStoreProvider.overrideWithValue(secureSettingsStore),
    initialSettingsProvider.overrideWithValue(initialSettings),
  ];
}

class SeekarrApp extends ConsumerWidget {
  const SeekarrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Seekarr',
          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),
          themeMode: themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
