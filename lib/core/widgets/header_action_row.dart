import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';

/// A shared row layout for media detail header actions.
///
/// Displays an [expanded] widget that fills remaining space, with an
/// optional [trailing] widget (typically an icon-only button) on the right.
class HeaderActionRow extends StatelessWidget {
  /// The primary widget that fills available horizontal space.
  final Widget expanded;

  /// Optional trailing widget, shown to the right of [expanded].
  final Widget? trailing;

  const HeaderActionRow({super.key, required this.expanded, this.trailing});

  /// Standard height for header action buttons (matches M3 default).
  static const buttonHeight = 35.0;

  /// Shared rounded shape for all detail header action buttons.
  static final _buttonShape = RoundedRectangleBorder(
    borderRadius: AppRadius.borderRadiusXl,
  );

  /// Creates a [ButtonStyle] for icon-only [FilledButton] trailing widgets.
  ///
  /// Produces a [buttonHeight]×[buttonHeight] square button. Pass
  /// [backgroundColor] and [foregroundColor] for variants like error/delete.
  static ButtonStyle iconOnlyButtonStyle({
    Color? foregroundColor,
    Color? backgroundColor,
  }) => FilledButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: const Size(buttonHeight, buttonHeight),
    fixedSize: const Size(buttonHeight, buttonHeight),
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    shape: _buttonShape,
  );

  /// Creates a [ButtonStyle] for expanded [FilledButton.icon] widgets.
  ///
  /// Ensures consistent shape and height across all detail action buttons.
  static ButtonStyle expandedButtonStyle({
    Color? foregroundColor,
    Color? backgroundColor,
  }) => FilledButton.styleFrom(
    fixedSize: const Size(double.infinity, buttonHeight),
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    shape: _buttonShape,
  );

  /// Wraps [child] in a glow effect container using [glowColor].
  ///
  /// Produces an Apple TV-style soft colored shadow behind the button.
  /// The glow [BorderRadius] matches [_buttonShape] (28dp).
  static Widget glowWrap({required Widget child, required Color glowColor}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.55),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: expanded),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
