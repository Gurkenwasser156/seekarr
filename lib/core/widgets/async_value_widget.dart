import 'package:seekarr/core/widgets/not_configured_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String serviceName;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) {
        if (e.toString().contains('not configured')) {
          return NotConfiguredPlaceholder(serviceName: serviceName);
        }
        return Center(
          child: SelectableText(
            'Error: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
