import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotConfiguredPlaceholder extends StatelessWidget {
  final String serviceName;
  const NotConfiguredPlaceholder({super.key, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_applications_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '$serviceName not configured',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Please set the URL and API Key in Settings.'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings),
            label: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }
}
