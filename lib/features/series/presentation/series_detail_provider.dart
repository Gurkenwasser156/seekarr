import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/series/domain/models/sonarr_episode.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';

final seriesDetailProvider = FutureProvider.autoDispose
    .family<SonarrSeries?, int>((ref, seriesId) async {
      final service = ref.watch(sonarrServiceProvider);
      return service.getSeriesById(seriesId);
    });

final seriesEpisodesProvider = FutureProvider.autoDispose
    .family<List<SonarrEpisode>, int>((ref, seriesId) async {
      final service = ref.watch(sonarrServiceProvider);
      return service.getEpisodes(seriesId);
    });
