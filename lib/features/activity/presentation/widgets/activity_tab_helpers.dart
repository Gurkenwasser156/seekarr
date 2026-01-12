import 'package:flutter/material.dart';

/// Mixin providing shared UI helpers for activity tab states.
///
/// Includes common methods for building section headers and async list widgets
/// used across both ActivityTab and WantedTab.
mixin ActivityTabHelpers {
  /// Builds a styled section header as a Sliver.
  Widget buildSectionHeaderSliver(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// Builds a sliver list for async data with loading and error states.
  Widget buildAsyncSliverList(
    Future<List<dynamic>> future,
    Widget Function(dynamic) itemBuilder,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No items found.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index.isOdd) return const Divider();
            return itemBuilder(items[index ~/ 2]);
          }, childCount: (items.length * 2) - 1),
        );
      },
    );
  }

  /// Builds a sliver list with grouping support.
  ///
  /// Since grouping often results in non-linear lists (like expansions),
  /// this implementation wraps the grouped widget in a SliverToBoxAdapter for now.
  /// For true sliver performance with grouping, the grouping logic needs to flatten
  /// the structure into a list of sliver-compatible items, but that requires
  /// significantly more logic change.
  Widget buildAsyncSliverListWithGrouping(
    Future<List<dynamic>> future,
    Widget Function(dynamic) itemBuilder, {
    Widget Function(List<dynamic>)? groupingBuilder,
  }) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No items found.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        if (groupingBuilder != null) {
          // Grouping builds a single Column usually, so wrap in SliverToBoxAdapter
          return SliverToBoxAdapter(child: groupingBuilder(items));
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index.isOdd) return const Divider();
            return itemBuilder(items[index ~/ 2]);
          }, childCount: (items.length * 2) - 1),
        );
      },
    );
  }
}
