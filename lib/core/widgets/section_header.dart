import 'package:flutter/material.dart';
import 'package:seekarr/core/app_spacing.dart';

/// A reusable section header with title and optional "See All" action.
///
/// Follows Material Design 3 styling with consistent typography
/// and tap feedback for the entire header area.
class SectionHeader extends StatelessWidget {
  /// The title text for the section
  final String title;

  /// Optional callback when the header is tapped (e.g., "See All" action)
  final VoidCallback? onTap;

  /// Whether to show the chevron icon indicating more content
  final bool showChevron;

  /// Optional trailing widget (alternative to chevron)
  final Widget? trailing;

  /// Optional subtitle text
  final String? subtitle;

  const SectionHeader({
    super.key,
    required this.title,
    this.onTap,
    this.showChevron = true,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title and optional subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing widget or chevron
              if (trailing != null)
                trailing!
              else if (showChevron && onTap != null)
                Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
