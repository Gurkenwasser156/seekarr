import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/models/media_preview.dart';
import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/async_value_widget.dart';
import 'package:seekarr/core/widgets/content_card.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/core/widgets/search_bar_header.dart';
import 'package:seekarr/core/widgets/section_header.dart';
import 'package:seekarr/features/discover/presentation/discover_provider.dart';
import 'package:seekarr/features/discover/presentation/discover_search_provider.dart';

/// Discover screen for browsing trending movies and TV shows.
///
/// Features horizontal carousels for each section following M3 design.
class DiscoverScreen extends ConsumerWidget {
  final bool showAppBar;
  final double topPadding;

  const DiscoverScreen({
    super.key,
    this.showAppBar = true,
    this.topPadding = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(discoverSearchQueryProvider);
    final searchResults = ref.watch(discoverSearchResultsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Listen for navigation refresh trigger
    ref.listen<int>(navigationRefreshProvider(NavigationSection.services), (
      previous,
      next,
    ) {
      // Clear search query and invalidate providers
      ref.read(discoverSearchQueryProvider.notifier).state = '';
      ref.invalidate(discoverTrendingProvider);
      ref.invalidate(discoverMoviesProvider);
      ref.invalidate(discoverTVProvider);
    });

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              leading: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () {
                        ref.read(discoverSearchQueryProvider.notifier).state =
                            '';
                      },
                      tooltip: 'Exit search',
                    )
                  : null,
              title: const Text('Discover'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () => context.push('/activity/discover'),
                  tooltip: 'Activity',
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          if (topPadding > 0)
            SizedBox(height: topPadding + MediaQuery.paddingOf(context).top),
          SearchBarHeader(
            hintText: 'Search movies & TV shows...',
            onQueryChanged: (query) {
              ref.read(discoverSearchQueryProvider.notifier).state = query;
            },
          ),
          Expanded(
            child: searchQuery.isEmpty
                ? _buildDiscoverContent(context, ref)
                : _buildSearchResults(context, ref, searchResults, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverContent(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(discoverTrendingProvider);
        ref.invalidate(discoverMoviesProvider);
        ref.invalidate(discoverTVProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom:
              AppSpacing.xl +
              FloatingNavBarMetrics.getScrollViewBottomPadding(context),
        ),
        child: Column(
          children: [
            _DiscoverSection(
              title: 'Trending',
              sectionId: 'trending',
              provider: discoverTrendingProvider,
              onSeeAll: () => context.push('/services/seerr/trending/all'),
            ),
            const SizedBox(height: AppSpacing.xl),
            _DiscoverSection(
              title: 'Movies',
              sectionId: 'movies',
              provider: discoverMoviesProvider,
              onSeeAll: () => context.push('/services/seerr/movies/all'),
              forcedMediaType: 'movie',
            ),
            const SizedBox(height: AppSpacing.xl),
            _DiscoverSection(
              title: 'TV Series',
              sectionId: 'tv',
              provider: discoverTVProvider,
              onSeeAll: () => context.push('/services/seerr/tv/all'),
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
    ColorScheme colorScheme,
  ) {
    return searchResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      data: (results) {
        if (results == null || results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No results found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom:
                AppSpacing.lg +
                FloatingNavBarMetrics.getScrollViewBottomPadding(context),
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: AppSpacing.gridGap,
            mainAxisSpacing: AppSpacing.gridGap,
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
                  '/services/seerr/${item.mediaType}/${item.id}?heroTag=$heroTag&posterUrl=$encodedUrl',
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

/// A horizontal carousel section for discover content.
class _DiscoverSection extends ConsumerWidget {
  final String title;
  final String sectionId;
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header using the new SectionHeader widget
        SectionHeader(title: title, onTap: onSeeAll),
        const SizedBox(height: AppSpacing.md),

        // Carousel
        SizedBox(
          height: 160,
          child: AsyncValueWidget<List<MediaPreview>>(
            value: asyncValue,
            serviceName: 'Seerr',
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No items found',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                    width: 100,
                    margin: const EdgeInsets.only(
                      right: AppSpacing.carouselGap,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        final encodedUrl = Uri.encodeComponent(imageUrl);
                        context.push(
                          '/services/seerr/$mediaType/${item.id}?heroTag=$heroTag&posterUrl=$encodedUrl',
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
