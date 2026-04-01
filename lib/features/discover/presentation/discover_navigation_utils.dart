import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/utils/snack_bar_helper.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';

Future<bool> openMediaInService({
  required BuildContext context,
  required WidgetRef ref,
  required String mediaType,
  required int tmdbId,
  int? tvdbId,
  VoidCallback? dismissSheet,
  bool showConfigurationAlert = true,
  String movieNotFoundMessage = 'Movie not found in Radarr',
  String seriesNotFoundMessage = 'Series not found in Sonarr',
}) async {
  if (mediaType == 'movie') {
    return _openMovieInService(
      context: context,
      ref: ref,
      tmdbId: tmdbId,
      dismissSheet: dismissSheet,
      showConfigurationAlert: showConfigurationAlert,
      notFoundMessage: movieNotFoundMessage,
    );
  }

  return _openSeriesInService(
    context: context,
    ref: ref,
    tvdbId: tvdbId,
    dismissSheet: dismissSheet,
    showConfigurationAlert: showConfigurationAlert,
    notFoundMessage: seriesNotFoundMessage,
  );
}

Future<bool> _openMovieInService({
  required BuildContext context,
  required WidgetRef ref,
  required int tmdbId,
  VoidCallback? dismissSheet,
  required bool showConfigurationAlert,
  required String notFoundMessage,
}) async {
  if (showConfigurationAlert) {
    final settings = ref.read(currentSettingsProvider);
    if (settings.radarrUrl.isEmpty || settings.radarrApiKey.isEmpty) {
      _showNotConfiguredDialog(context, 'Radarr');
      return false;
    }
  }

  try {
    final radarrService = ref.read(radarrServiceProvider);
    final movie = await radarrService.getMovieByTmdbId(tmdbId);
    if (!context.mounted) {
      return false;
    }

    if (movie == null) {
      SnackBarHelper.info(context, notFoundMessage);
      return false;
    }

    final router = GoRouter.of(context);
    dismissSheet?.call();
    router.push('/movies/${movie.id}?heroTag=radarr_${movie.id}', extra: movie);
    return true;
  } catch (error) {
    if (!context.mounted) {
      return false;
    }

    SnackBarHelper.info(context, 'Error: $error');
    return false;
  }
}

Future<bool> _openSeriesInService({
  required BuildContext context,
  required WidgetRef ref,
  required int? tvdbId,
  VoidCallback? dismissSheet,
  required bool showConfigurationAlert,
  required String notFoundMessage,
}) async {
  if (showConfigurationAlert) {
    final settings = ref.read(currentSettingsProvider);
    if (settings.sonarrUrl.isEmpty || settings.sonarrApiKey.isEmpty) {
      _showNotConfiguredDialog(context, 'Sonarr');
      return false;
    }
  }

  if (tvdbId == null) {
    SnackBarHelper.info(context, 'TVDB ID not available');
    return false;
  }

  try {
    final sonarrService = ref.read(sonarrServiceProvider);
    final series = await sonarrService.getSeriesByTvdbId(tvdbId);
    if (!context.mounted) {
      return false;
    }

    if (series == null) {
      SnackBarHelper.info(context, notFoundMessage);
      return false;
    }

    final router = GoRouter.of(context);
    dismissSheet?.call();
    router.push(
      '/series/${series.id}?heroTag=sonarr_${series.id}',
      extra: series,
    );
    return true;
  } catch (error) {
    if (!context.mounted) {
      return false;
    }

    SnackBarHelper.info(context, 'Error: $error');
    return false;
  }
}

void _showNotConfiguredDialog(BuildContext context, String serviceName) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('$serviceName Not Configured'),
      content: Text(
        'Please configure $serviceName in Settings to use this feature.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
