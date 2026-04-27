import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/theme.dart';

void main() {
  group('AppTheme', () {
    testWidgets('dark theme preserves special-case background colors', (
      tester,
    ) async {
      final theme = AppTheme.darkTheme(null);

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

      expect(
        theme.navigationBarTheme.backgroundColor,
        theme.colorScheme.surface,
      );
      expect(theme.bottomSheetTheme.backgroundColor, theme.colorScheme.surface);
      expect(theme.dialogTheme.backgroundColor, theme.colorScheme.surface);
    });

    testWidgets('dark theme attaches SeekarrThemeColors defaults', (
      tester,
    ) async {
      final theme = AppTheme.darkTheme(null);

      final colors = theme.extension<SeekarrThemeColors>();

      expect(colors, isNotNull);
      expect(
        colors!.statusBadgeBackground,
        theme.colorScheme.surface.withValues(alpha: 0.8),
      );
      expect(colors.statusBadgeForeground, theme.colorScheme.onSurface);
    });

    testWidgets('light theme attaches SeekarrThemeColors defaults', (
      tester,
    ) async {
      final theme = AppTheme.lightTheme(null);

      final colors = theme.extension<SeekarrThemeColors>();

      expect(colors, isNotNull);
      expect(
        colors!.statusBadgeBackground,
        theme.colorScheme.surface.withValues(alpha: 0.8),
      );
      expect(colors.statusBadgeForeground, theme.colorScheme.onSurface);
    });

    test('SeekarrThemeColors.defaults uses surface scrim and onSurface', () {
      final colorScheme = AppTheme.lightTheme(null).colorScheme.copyWith(
        surface: const Color(0xFF123456),
        onSurface: const Color(0xFFABCDEF),
      );

      final colors = SeekarrThemeColors.defaults(
        brightness: Brightness.light,
        colorScheme: colorScheme,
      );

      expect(
        colors.statusBadgeBackground,
        colorScheme.surface.withValues(alpha: 0.8),
      );
      expect(colors.statusBadgeForeground, colorScheme.onSurface);
    });
  });
}
