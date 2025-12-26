import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/widgets/not_configured_placeholder.dart';

/// A widget that handles AsyncValue states with proper M3 styling.
///
/// Shows loading, error, or data states based on the AsyncValue.
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String serviceName;

  /// Optional custom loading widget. Defaults to centered CircularProgressIndicator.
  final Widget? loadingWidget;

  /// Whether to show a shimmer loading effect instead of spinner
  final bool useShimmer;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    required this.serviceName,
    this.loadingWidget,
    this.useShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return value.when(
      data: data,
      loading: () =>
          loadingWidget ?? const Center(child: CircularProgressIndicator()),
      error: (e, stack) {
        if (e.toString().contains('not configured')) {
          return NotConfiguredPlaceholder(serviceName: serviceName);
        }
        return _ErrorStateWidget(error: e, colorScheme: colorScheme);
      },
    );
  }
}

/// A styled error state widget following M3 design guidelines.
class _ErrorStateWidget extends StatelessWidget {
  final Object error;
  final ColorScheme colorScheme;

  const _ErrorStateWidget({required this.error, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
