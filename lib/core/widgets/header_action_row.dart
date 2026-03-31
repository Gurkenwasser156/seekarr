import 'package:flutter/material.dart';

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
  static const buttonHeight = 40.0;

  /// Creates a [ButtonStyle] for icon-only [OutlinedButton] trailing widgets.
  ///
  /// Produces a [buttonHeight]×[buttonHeight] square button. Pass
  /// [foregroundColor] and [borderColor] for variants like error/delete.
  static ButtonStyle iconOnlyButtonStyle({
    Color? foregroundColor,
    Color? borderColor,
  }) => OutlinedButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: const Size(buttonHeight, buttonHeight),
    fixedSize: const Size(buttonHeight, buttonHeight),
    foregroundColor: foregroundColor,
    side: borderColor != null ? BorderSide(color: borderColor) : null,
  );

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
