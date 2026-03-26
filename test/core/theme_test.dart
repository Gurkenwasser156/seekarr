import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;

import 'package:seekarr/core/theme.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppTheme', () {
    late ByteData fontData;

    setUpAll(() async {
      fontData = ByteData.sublistView(await _loadFallbackFontBytes());
    });

    setUp(() {
      google_fonts_base.clearCache();
      google_fonts_base.assetManifest = _FakeAssetManifest(_outfitAssets);
      binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
        message,
      ) async {
        final key = const StringCodec().decodeMessage(message);
        if (key != null && _outfitAssets.contains(key)) {
          return fontData;
        }
        return null;
      });
    });

    tearDown(() async {
      await GoogleFonts.pendingFonts();
      google_fonts_base.assetManifest = null;
      binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        null,
      );
    });

    testWidgets('dark theme preserves special-case background colors', (
      tester,
    ) async {
      final theme = AppTheme.darkTheme(null);
      await GoogleFonts.pendingFonts();

      expect(
        theme.navigationBarTheme.backgroundColor,
        AppColors.surfaceContainerDark,
      );
      expect(
        theme.bottomSheetTheme.backgroundColor,
        theme.colorScheme.surfaceContainer,
      );
      expect(
        theme.dialogTheme.backgroundColor,
        theme.colorScheme.surfaceContainer,
      );
    });

    testWidgets('light theme preserves special-case background colors', (
      tester,
    ) async {
      final theme = AppTheme.lightTheme(null);
      await GoogleFonts.pendingFonts();

      expect(
        theme.navigationBarTheme.backgroundColor,
        theme.colorScheme.surface,
      );
      expect(theme.bottomSheetTheme.backgroundColor, theme.colorScheme.surface);
      expect(theme.dialogTheme.backgroundColor, theme.colorScheme.surface);
    });
  });
}

const _outfitAssets = <String>{
  'google_fonts/Outfit-Regular.ttf',
  'google_fonts/Outfit-Medium.ttf',
  'google_fonts/Outfit-SemiBold.ttf',
  'google_fonts/Outfit-Bold.ttf',
  'google_fonts/Outfit-Light.ttf',
};

Future<Uint8List> _loadFallbackFontBytes() async {
  final executableDir = File(Platform.resolvedExecutable).absolute.parent;
  final candidateRoots = <String>{
    if (Platform.environment['FLUTTER_ROOT'] case final flutterRoot?)
      flutterRoot,
    executableDir.path,
    executableDir.parent.path,
    executableDir.parent.parent.path,
    executableDir.parent.parent.parent.path,
    executableDir.parent.parent.parent.parent.path,
    executableDir.parent.parent.parent.parent.parent.path,
    executableDir.parent.parent.parent.parent.parent.parent.path,
  };

  for (final root in candidateRoots) {
    final fontFile = File('$root/packages/flutter_tools/static/Ahem.ttf');
    if (await fontFile.exists()) {
      return fontFile.readAsBytes();
    }
  }

  throw FileSystemException(
    'Could not locate fallback font file',
    '${Platform.resolvedExecutable} -> packages/flutter_tools/static/Ahem.ttf',
  );
}

class _FakeAssetManifest implements AssetManifest {
  const _FakeAssetManifest(this.assets);

  final Set<String> assets;

  @override
  List<String> listAssets() => assets.toList(growable: false);

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}
