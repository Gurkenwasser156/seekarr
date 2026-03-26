import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: implementation_imports
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/async_value_widget.dart';
import 'package:seekarr/core/widgets/media_grid.dart';
import 'package:seekarr/core/widgets/search_bar_header.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

typedef SettingsSelector = (String, String) Function(SettingsModel settings);
typedef MediaBrowseItemTap<T> =
    void Function(BuildContext context, T item, String heroTag);

/// Shared scaffold for media library browse screens.
///
/// Provides the shared AppBar, search bar, navigation refresh listener,
/// library refresh flow, and search results layout used by the Movies, Series,
/// and Music screens.
///
/// This is a [ConsumerWidget] because it needs [WidgetRef] for provider
/// watching/listening.
class MediaBrowseScaffold<T> extends ConsumerWidget {
  final String title;
  final String searchHint;
  final String activityRoute;
  final NavigationSection navigationSection;
  final String serviceName;
  final String heroTagPrefix;
  final String searchHeroTagPrefix;
  final FutureProvider<List<T>> libraryProvider;
  final StateProvider<String> searchQueryProvider;
  final FutureProvider<List<T>?> searchResultsProvider;
  final List<dynamic>? Function(T item) imagesExtractor;
  final int Function(T item) idExtractor;
  final StatusExtractor<T>? statusExtractor;
  final SettingsSelector settingsSelector;
  final MediaBrowseItemTap<T> onItemTap;
  final List<String>? coverTypes;

  const MediaBrowseScaffold({
    super.key,
    required this.title,
    required this.searchHint,
    required this.activityRoute,
    required this.navigationSection,
    required this.serviceName,
    required this.heroTagPrefix,
    required this.searchHeroTagPrefix,
    required this.libraryProvider,
    required this.searchQueryProvider,
    required this.searchResultsProvider,
    required this.imagesExtractor,
    required this.idExtractor,
    this.statusExtractor,
    required this.settingsSelector,
    required this.onItemTap,
    this.coverTypes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching = ref.watch(
      searchQueryProvider.select((value) => value.isNotEmpty),
    );

    ref.listen<int>(navigationRefreshProvider(navigationSection), (
      previous,
      next,
    ) {
      ref.read(searchQueryProvider.notifier).state = '';
      ref.invalidate(libraryProvider);
    });

    return Scaffold(
      appBar: AppBar(
        leading: isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                },
                tooltip: 'Exit search',
              )
            : null,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(activityRoute),
            tooltip: 'Activity',
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBarHeader(
            hintText: searchHint,
            onQueryChanged: (query) {
              ref.read(searchQueryProvider.notifier).state = query;
            },
          ),
          Expanded(
            child: isSearching
                ? _buildSearchResults(context, ref)
                : _buildLibraryContent(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryContent(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);
    final (url, apiKey) = ref.watch(
      currentSettingsProvider.select(settingsSelector),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(libraryProvider);
      },
      child: AsyncValueWidget<List<T>>(
        value: libraryAsync,
        serviceName: serviceName,
        data: (items) => _buildGrid(
          context: context,
          items: items,
          baseUrl: url,
          apiKey: apiKey,
          heroTagPrefix: heroTagPrefix,
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, WidgetRef ref) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final (url, apiKey) = ref.watch(
      currentSettingsProvider.select(settingsSelector),
    );

    return searchResultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (results) {
        if (results == null || results.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return _buildGrid(
          context: context,
          items: results,
          baseUrl: url,
          apiKey: apiKey,
          heroTagPrefix: searchHeroTagPrefix,
        );
      },
    );
  }

  Widget _buildGrid({
    required BuildContext context,
    required List<T> items,
    required String baseUrl,
    required String apiKey,
    required String heroTagPrefix,
  }) {
    return MediaGrid<T>(
      items: items,
      imagesExtractor: imagesExtractor,
      idExtractor: idExtractor,
      statusExtractor: statusExtractor,
      baseUrl: baseUrl,
      apiKey: apiKey,
      heroTagPrefix: heroTagPrefix,
      onItemTap: (item, heroTag) {
        onItemTap(context, item, heroTag);
      },
      coverTypes: coverTypes ?? const ['poster', 'cover'],
    );
  }
}
