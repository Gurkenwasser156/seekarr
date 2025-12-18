import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final seriesProvider = FutureProvider<List<SonarrSeries>>((ref) async {
  final service = ref.watch(sonarrServiceProvider);
  return service.getSeries();
});
