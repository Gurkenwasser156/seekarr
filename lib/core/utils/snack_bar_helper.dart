import 'package:flutter/material.dart';

/// Convenience helpers for showing semantically typed snackbars.
///
/// The app theme already configures shared snackbar styling in `core/theme.dart`.
/// These helpers keep call sites small and centralize semantic variants.
///
/// Usage:
/// ```dart
/// SnackBarHelper.success(context, 'Settings saved');
/// SnackBarHelper.info(context, 'Coming soon!');
/// SnackBarHelper.error(context, 'Failed to delete movie');
/// ```
class SnackBarHelper {
  SnackBarHelper._();

  /// Shows an informational snackbar with the default themed appearance.
  static void info(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows a success snackbar using the default themed appearance.
  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows an error snackbar with the theme error background color.
  static void error(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: colorScheme.error),
    );
  }
}
