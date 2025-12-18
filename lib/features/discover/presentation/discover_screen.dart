import 'package:seekarr/core/models/media_preview.dart';
import 'package:seekarr/core/widgets/async_value_widget.dart';
import 'package:seekarr/core/widgets/content_card.dart';
import 'package:seekarr/core/widgets/search_bar_header.dart';
import 'package:seekarr/features/discover/presentation/discover_provider.dart';
import 'package:seekarr/features/discover/presentation/discover_search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(discoverSearchQueryProvider);
    final searchResults = ref.watch(discoverSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(discoverSearchQueryProvider.notifier).state = '';
                },
                tooltip: 'Exit search',
              )
            : null,
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/activity/discover'),
            tooltip: 'Activity',
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBarHeader(
            hintText: 'Search movies & TV shows...',
            onQueryChanged: (query) {
              ref.read(discoverSearchQueryProvider.notifier).state = query;
            },
          ),
          Expanded(
            child: searchQuery.isEmpty
                ? _buildDiscoverContent(context, ref)
                : _buildSearchResults(context, ref, searchResults),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverContent(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate all discover providers to refresh data
        ref.invalidate(discoverTrendingProvider);
        ref.invalidate(discoverMoviesProvider);
        ref.invalidate(discoverTVProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            _DiscoverSection(
              title: 'Trending',
              sectionId: 'trending',
              provider: discoverTrendingProvider,
              onSeeAll: () => context.push('/discover/trending/all'),
            ),
            const SizedBox(height: 24),
            _DiscoverSection(
              title: 'Movies',
              sectionId: 'movies',
              provider: discoverMoviesProvider,
              onSeeAll: () => context.push('/discover/movies/all'),
              forcedMediaType: 'movie',
            ),
            const SizedBox(height: 24),
            _DiscoverSection(
              title: 'TV Series',
              sectionId: 'tv',
              provider: discoverTVProvider,
              onSeeAll: () => context.push('/discover/tv/all'),
              forcedMediaType: 'tv',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<MediaPreview>?> searchResults,
  ) {
    return searchResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (results) {
        if (results == null || results.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            final posterPath = item.posterPath;
            final imageUrl = posterPath != null
                ? 'https://image.tmdb.org/t/p/w500$posterPath'
                : '';
            final heroTag = 'discover_search_${item.id}';

            return GestureDetector(
              onTap: () {
                final encodedUrl = Uri.encodeComponent(imageUrl);
                context.push(
                  '/discover/${item.mediaType}/${item.id}?heroTag=$heroTag&posterUrl=$encodedUrl',
                );
              },
              child: Hero(
                tag: heroTag,
                child: ContentCard(imageUrl: imageUrl),
              ),
            );
          },
        );
      },
    );
  }
}

class _DiscoverSection extends ConsumerWidget {
  final String title;
  final String sectionId; // Unique ID for hero tag disambiguation
  final FutureProvider<List<MediaPreview>> provider;
  final VoidCallback onSeeAll;
  final String? forcedMediaType;

  const _DiscoverSection({
    required this.title,
    required this.sectionId,
    required this.provider,
    required this.onSeeAll,
    this.forcedMediaType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(provider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height:
              160, // approximate height for card (width 100 * 1.5 aspect + padding?)
          // Card width is not fixed in the new ContentCard?
          // The previous ContentCard had width: 160.
          // We removed the width constraint in ContentCard to let GridView control it,
          // BUT for a horizontal ListView we need a constrained width.
          // We should wrap ContentCard in a SizedBox or Constraints here.
          child: AsyncValueWidget<List<MediaPreview>>(
            value: asyncValue,
            serviceName: 'Jellyseerr',
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No items found'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final posterPath = item.posterPath;
                  final imageUrl = posterPath != null
                      ? 'https://image.tmdb.org/t/p/w500$posterPath'
                      : '';

                  final mediaType = forcedMediaType ?? item.mediaType;
                  final heroTag = 'discover_${sectionId}_${item.id}';

                  return Container(
                    width: 100, // Reduced width for carousel
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        final encodedUrl = Uri.encodeComponent(imageUrl);
                        context.push(
                          '/discover/$mediaType/${item.id}?heroTag=$heroTag&posterUrl=$encodedUrl',
                        );
                      },
                      child: Hero(
                        tag: heroTag,
                        child: ContentCard(imageUrl: imageUrl),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
