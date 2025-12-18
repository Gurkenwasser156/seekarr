import 'package:seekarr/features/discover/data/jellyseerr_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final discoverDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({int id, String type})>((ref, arg) async {
      final service = ref.watch(jellyseerrServiceProvider);
      if (arg.type == 'movie') {
        return service.getMovie(arg.id);
      } else {
        return service.getTv(arg.id);
      }
    });
