import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: implementation_imports
import 'package:flutter_riverpod/legacy.dart';
import 'package:seekarr/features/music/data/lidarr_service.dart';
import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';

/// Provider for the current search query in Music section.
final musicSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for search results in Music section.
///
/// Returns null when query is empty, otherwise returns lookup results.
final musicSearchResultsProvider = FutureProvider<List<LidarrArtist>?>((
  ref,
) async {
  final query = ref.watch(musicSearchQueryProvider);
  if (query.isEmpty) {
    return null;
  }

  try {
    final service = ref.read(lidarrServiceProvider);
    return await service.lookupArtists(query);
  } catch (e) {
    return [];
  }
});
