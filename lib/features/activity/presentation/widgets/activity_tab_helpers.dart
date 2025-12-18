import 'package:flutter/material.dart';

/// Mixin providing shared UI helpers for activity tab states.
///
/// Includes common methods for building section headers and async list widgets
/// used across both ActivityTab and WantedTab.
mixin ActivityTabHelpers {
  /// Builds a styled section header for activity lists.
  Widget buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Builds a widget for async list data with loading and error states.
  Widget buildAsyncList(
    Future<List<dynamic>> future,
    Widget Function(dynamic) itemBuilder,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Text(
            'No items found.',
            style: TextStyle(color: Colors.grey),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
    );
  }

  /// Builds an async list with custom handling for grouped items (e.g., series).
  Widget buildAsyncListWithGrouping(
    Future<List<dynamic>> future,
    Widget Function(dynamic) itemBuilder, {
    Widget Function(List<dynamic>)? groupingBuilder,
  }) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Text(
            'No items found.',
            style: TextStyle(color: Colors.grey),
          );
        }

        if (groupingBuilder != null) {
          return groupingBuilder(items);
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
    );
  }
}
