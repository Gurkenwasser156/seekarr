import 'package:seekarr/features/discover/data/seerr_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final discoverDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({int id, String type})>((ref, arg) async {
      final service = ref.watch(seerrServiceProvider);
      if (arg.type == 'movie') {
        return service.getMovie(arg.id);
      } else {
        return service.getTv(arg.id);
      }
    });
