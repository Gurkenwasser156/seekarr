import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seekarr/core/router.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/data/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final secureSettingsStore = FlutterSecureSettingsStore(
    FlutterSecureStorage(
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  final settingsService = SettingsService(prefs, secureSettingsStore);

  await settingsService.migrateFromPlaintext();
  final initialSettings = await settingsService.loadSettings();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureSettingsStoreProvider.overrideWithValue(secureSettingsStore),
        initialSettingsProvider.overrideWithValue(initialSettings),
      ],
      child: const CheckerrApp(),
    ),
  );
}

class CheckerrApp extends ConsumerWidget {
  const CheckerrApp({super.key});

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
