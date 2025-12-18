import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';
import 'package:seekarr/core/widgets/async_value_widget.dart';
import 'package:seekarr/core/widgets/media_grid.dart';
import 'package:seekarr/core/widgets/search_bar_header.dart';
import 'package:seekarr/features/music/presentation/music_provider.dart';
import 'package:seekarr/features/music/presentation/music_search_provider.dart';
import 'package:seekarr/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MusicScreen extends ConsumerWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicAsync = ref.watch(musicProvider);
    final settings = ref.watch(settingsProvider);
    final searchQuery = ref.watch(musicSearchQueryProvider);
    final searchResults = ref.watch(musicSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(musicSearchQueryProvider.notifier).state = '';
                },
                tooltip: 'Exit search',
              )
            : null,
        title: const Text('Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/activity/music'),
            tooltip: 'Activity',
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBarHeader(
            hintText: 'Search artists...',
            onQueryChanged: (query) {
              ref.read(musicSearchQueryProvider.notifier).state = query;
            },
          ),
          Expanded(
            child: searchQuery.isEmpty
                ? _buildLibraryContent(context, ref, musicAsync, settings)
                : _buildSearchResults(context, ref, searchResults, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<LidarrArtist>> musicAsync,
    dynamic settings,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(musicProvider);
      },
      child: AsyncValueWidget<List<LidarrArtist>>(
        value: musicAsync,
        serviceName: 'Lidarr',
        data: (artists) => MediaGrid<LidarrArtist>(
          items: artists,
          imagesExtractor: (artist) => artist.images,
          idExtractor: (artist) => artist.id,
          statusExtractor: (artist) {
            // Check if artist has any track files
            final stats = artist.statistics;
            final trackFileCount = stats?['trackFileCount'] as int? ?? 0;
            return (hasFile: trackFileCount > 0, status: artist.status);
          },
          baseUrl: settings.lidarrUrl,
          apiKey: settings.lidarrApiKey,
          heroTagPrefix: 'artist',
          coverTypes: const ['poster', 'fanart', 'banner'],
          onItemTap: (artist, heroTag) {
            context.push('/music/${artist.id}?heroTag=$heroTag', extra: artist);
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<LidarrArtist>?> searchResults,
    dynamic settings,
  ) {
    return searchResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (results) {
        if (results == null || results.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return MediaGrid<LidarrArtist>(
          items: results,
          imagesExtractor: (artist) => artist.images,
          idExtractor: (artist) => artist.id,
          statusExtractor: (artist) {
            final stats = artist.statistics;
            final trackFileCount = stats?['trackFileCount'] as int? ?? 0;
            return (hasFile: trackFileCount > 0, status: artist.status);
          },
          baseUrl: settings.lidarrUrl,
          apiKey: settings.lidarrApiKey,
          heroTagPrefix: 'artist_search',
          coverTypes: const ['poster', 'fanart', 'banner'],
          onItemTap: (artist, heroTag) {
            context.push('/music/${artist.id}?heroTag=$heroTag', extra: artist);
          },
        );
      },
    );
  }
}
