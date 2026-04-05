import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/widgets.dart';
import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';
import 'package:seekarr/features/music/presentation/music_provider.dart';
import 'package:seekarr/features/music/presentation/music_search_provider.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaBrowseScaffold<LidarrArtist>(
      title: 'Music',
      searchHint: 'Search artists...',
      activityRoute: '/activity/music',
      navigationSection: NavigationSection.music,
      serviceName: 'Lidarr',
      heroTagPrefix: 'artist',
      searchHeroTagPrefix: 'artist_search',
      libraryProvider: musicProvider,
      searchQueryProvider: musicSearchQueryProvider,
      searchResultsProvider: musicSearchResultsProvider,
      imagesExtractor: (artist) => artist.images,
      idExtractor: (artist) => artist.id,
      statusExtractor: (artist) =>
          (hasFile: artist.hasFiles, status: artist.status),
      settingsSelector: (settings) =>
          (settings.lidarrUrl, settings.lidarrApiKey),
      onItemTap: (context, artist, heroTag) {
        context.push('/music/${artist.id}?heroTag=$heroTag', extra: artist);
      },
      coverTypes: const ['poster', 'fanart', 'banner'],
    );
  }
}
