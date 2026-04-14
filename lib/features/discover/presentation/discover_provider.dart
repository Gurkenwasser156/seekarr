import 'package:seekarr/features/discover/domain/models/seerr_request.dart';
import 'package:seekarr/core/models/media_preview.dart';
import 'package:seekarr/features/discover/data/seerr_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final requestsProvider = FutureProvider<List<SeerrRequest>>((ref) async {
  final service = ref.watch(seerrServiceProvider);
  return service.getRequests();
});

// Basic providers for the main Discover screen (Carousels) - fetching page 1
final discoverMoviesProvider = FutureProvider<List<MediaPreview>>((ref) async {
  final service = ref.watch(seerrServiceProvider);
  return service.getDiscoverMovies(page: 1);
});

final discoverTVProvider = FutureProvider<List<MediaPreview>>((ref) async {
  final service = ref.watch(seerrServiceProvider);
  return service.getDiscoverTV(page: 1);
});

final discoverTrendingProvider = FutureProvider<List<MediaPreview>>((
  ref,
) async {
  final service = ref.watch(seerrServiceProvider);
  return service.getDiscoverTrending(page: 1);
});

// Family providers for pagination in "See All" screens
final discoverMoviesPageProvider =
    FutureProvider.family<List<MediaPreview>, int>((ref, page) async {
      final service = ref.watch(seerrServiceProvider);
      return service.getDiscoverMovies(page: page);
    });

final discoverTVPageProvider = FutureProvider.family<List<MediaPreview>, int>((
  ref,
  page,
) async {
  final service = ref.watch(seerrServiceProvider);
  return service.getDiscoverTV(page: page);
});

final discoverTrendingPageProvider =
    FutureProvider.family<List<MediaPreview>, int>((ref, page) async {
      final service = ref.watch(seerrServiceProvider);
      return service.getDiscoverTrending(page: page);
    });
