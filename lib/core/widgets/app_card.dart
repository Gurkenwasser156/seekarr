import 'package:flutter/material.dart';
import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';

/// Variants for AppCard appearance following Material Design 3.
enum AppCardVariant {
  /// Filled card with surface container background
  filled,

  /// Outlined card with border and transparent background
  outlined,

  /// Elevated card with shadow
  elevated,
}

/// A versatile card component following Material Design 3 guidelines.
///
/// Provides three variants: filled, outlined, and elevated.
/// Uses design system tokens for consistent styling.
class AppCard extends StatelessWidget {
  /// The card's child widget
  final Widget child;

  /// The card variant (filled, outlined, elevated)
  final AppCardVariant variant;

  /// Optional callback when the card is tapped
  final VoidCallback? onTap;

  /// Optional padding override (defaults to AppSpacing.lg)
  final EdgeInsetsGeometry? padding;

  /// Optional border radius override
  final BorderRadius? borderRadius;

  /// Optional custom background color
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.filled,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  });

  /// Creates a filled card (default)
  const AppCard.filled({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  }) : variant = AppCardVariant.filled;

  /// Creates an outlined card
  const AppCard.outlined({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  }) : variant = AppCardVariant.outlined;

  /// Creates an elevated card with shadow
  const AppCard.elevated({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  }) : variant = AppCardVariant.elevated;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBorderRadius = borderRadius ?? AppRadius.borderRadiusMd;
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.lg);

    // Determine styling based on variant
    Color bgColor;
    BoxBorder? border;
    List<BoxShadow>? shadows;

    switch (variant) {
      case AppCardVariant.filled:
        bgColor = backgroundColor ?? colorScheme.surfaceContainer;
        border = null;
        shadows = null;
        break;
      case AppCardVariant.outlined:
        bgColor = backgroundColor ?? Colors.transparent;
        border = Border.all(color: colorScheme.outline);
        shadows = null;
        break;
      case AppCardVariant.elevated:
        bgColor = backgroundColor ?? colorScheme.surfaceContainer;
        border = null;
        shadows = [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
        break;
    }

    if (onTap != null) {
      // Place background on Material so InkWell ripple paints on top.
      final shape = RoundedRectangleBorder(
        borderRadius: effectiveBorderRadius,
        side: variant == AppCardVariant.outlined
            ? BorderSide(color: colorScheme.outline)
            : BorderSide.none,
      );

      return Material(
        color: bgColor,
        shape: shape,
        elevation: shadows != null ? 1 : 0,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(padding: effectivePadding, child: child),
        ),
      );
    }

    // Non-tappable: plain Container.
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: effectiveBorderRadius,
        border: border,
        boxShadow: shadows,
      ),
      padding: effectivePadding,
      child: child,
    );
  }
}

/// A card specifically designed for settings/list items
class SettingsCard extends StatelessWidget {
  /// Leading widget (usually an icon)
  final Widget? leading;

  /// Title text
  final String title;

  /// Subtitle text
  final String? subtitle;

  /// Optional widget rendered before the subtitle text (e.g. a status icon).
  /// Only shown when [subtitle] is also provided.
  final Widget? subtitleLeading;

  /// Trailing widget
  final Widget? trailing;

  /// Callback when tapped
  final VoidCallback? onTap;

  const SettingsCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.subtitleLeading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard.filled(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(color: colorScheme.primary, size: 24),
              child: leading!,
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (subtitleLeading != null) ...[
                        subtitleLeading!,
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ] else if (onTap != null) ...[
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}
