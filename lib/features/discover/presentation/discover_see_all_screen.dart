import 'package:seekarr/core/models/media_preview.dart';
import 'package:seekarr/core/widgets/content_card.dart';
import 'package:seekarr/features/discover/presentation/discover_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class DiscoverSeeAllScreen extends ConsumerStatefulWidget {
  final String type; // 'movies', 'tv', 'trending'
  final String title;

  const DiscoverSeeAllScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  ConsumerState<DiscoverSeeAllScreen> createState() =>
      _DiscoverSeeAllScreenState();
}

class _DiscoverSeeAllScreenState extends ConsumerState<DiscoverSeeAllScreen> {
  final PagingController<int, MediaPreview> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      // Determine which provider family to use based on type
      late Future<List<MediaPreview>> future;

      switch (widget.type) {
        case 'movies':
          future = ref.read(discoverMoviesPageProvider(pageKey).future);
          break;
        case 'tv':
          future = ref.read(discoverTVPageProvider(pageKey).future);
          break;
        case 'trending':
          // Trending implies all, but usually mixed or dependent on implementation.
          // Jellyseerr trending endpoint returns mixed results.
          future = ref.read(discoverTrendingPageProvider(pageKey).future);
          break;
        default:
          throw Exception('Unknown type: ${widget.type}');
      }

      final newItems = await future;

      // Assuming 20 is the page size from Jellyseerr usually, or check if less than expected
      final isLastPage = newItems.length < 20;

      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: PagedGridView<int, MediaPreview>(
        pagingController: _pagingController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        builderDelegate: PagedChildBuilderDelegate<MediaPreview>(
          itemBuilder: (context, item, index) {
            final posterPath = item.posterPath;
            final imageUrl = posterPath != null
                ? 'https://image.tmdb.org/t/p/w500$posterPath'
                : '';

            final mediaType = item.mediaType; // Might be mixed for trending
            final heroTag = 'discover_seeall_${mediaType}_${item.id}_$index';

            return GestureDetector(
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
            );
          },
        ),
      ),
    );
  }
}
