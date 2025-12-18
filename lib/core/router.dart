import 'package:flutter/material.dart';
import 'package:seekarr/core/utils/route_utils.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seekarr/features/shell/presentation/shell_screen.dart';
import 'package:seekarr/features/discover/presentation/discover_screen.dart';
import 'package:seekarr/features/activity/presentation/activity_screen.dart';
import 'package:seekarr/features/movies/presentation/movies_screen.dart';
import 'package:seekarr/features/movies/presentation/movie_detail_screen.dart';
import 'package:seekarr/features/series/presentation/series_screen.dart';
import 'package:seekarr/features/series/presentation/series_detail_screen.dart';
import 'package:seekarr/features/music/presentation/music_screen.dart';
import 'package:seekarr/features/music/presentation/music_detail_screen.dart';
import 'package:seekarr/features/music/domain/models/lidarr_artist.dart';
import 'package:seekarr/features/discover/presentation/discover_detail_screen.dart';
import 'package:seekarr/features/discover/presentation/discover_see_all_screen.dart';
import 'package:seekarr/features/settings/presentation/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/discover',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
            routes: [
              GoRoute(
                path: 'movies/all',
                builder: (context, state) =>
                    const DiscoverSeeAllScreen(type: 'movies', title: 'Movies'),
              ),
              GoRoute(
                path: 'tv/all',
                builder: (context, state) =>
                    const DiscoverSeeAllScreen(type: 'tv', title: 'TV Series'),
              ),
              GoRoute(
                path: 'trending/all',
                builder: (context, state) => const DiscoverSeeAllScreen(
                  type: 'trending',
                  title: 'Trending',
                ),
              ),
              GoRoute(
                path: 'movie/:id',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  final heroTag =
                      state.uri.queryParameters['heroTag'] ??
                      'discover_movie_$id';
                  final posterUrl =
                      state.uri.queryParameters['posterUrl'] != null
                      ? Uri.decodeComponent(
                          state.uri.queryParameters['posterUrl']!,
                        )
                      : null;
                  return RouteUtils.cupertinoPage(
                    key: state.pageKey,
                    child: DiscoverDetailScreen(
                      mediaId: id,
                      mediaType: 'movie',
                      heroTag: heroTag,
                      initialPosterUrl: posterUrl,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'tv/:id',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  final heroTag =
                      state.uri.queryParameters['heroTag'] ?? 'discover_tv_$id';
                  final posterUrl =
                      state.uri.queryParameters['posterUrl'] != null
                      ? Uri.decodeComponent(
                          state.uri.queryParameters['posterUrl']!,
                        )
                      : null;
                  return RouteUtils.cupertinoPage(
                    key: state.pageKey,
                    child: DiscoverDetailScreen(
                      mediaId: id,
                      mediaType: 'tv',
                      heroTag: heroTag,
                      initialPosterUrl: posterUrl,
                    ),
                  );
                },
              ),
            ],
          ),

          GoRoute(
            path: '/movies',
            builder: (context, state) => const MoviesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final movie = state.extra as RadarrMovie;
                  final heroTag =
                      state.uri.queryParameters['heroTag'] ??
                      'movie_${movie.id}';
                  return RouteUtils.cupertinoPage(
                    key: state.pageKey,
                    child: MovieDetailScreen(movie: movie, heroTag: heroTag),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/series',
            builder: (context, state) => const SeriesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final series = state.extra as SonarrSeries;
                  final heroTag =
                      state.uri.queryParameters['heroTag'] ??
                      'series_${series.id}';
                  return RouteUtils.cupertinoPage(
                    key: state.pageKey,
                    child: SeriesDetailScreen(series: series, heroTag: heroTag),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/music',
            builder: (context, state) => const MusicScreen(),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final artist = state.extra as LidarrArtist;
                  final heroTag =
                      state.uri.queryParameters['heroTag'] ??
                      'artist_${artist.id}';
                  return RouteUtils.cupertinoPage(
                    key: state.pageKey,
                    child: MusicDetailScreen(artist: artist, heroTag: heroTag),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/activity/:type',
        builder: (context, state) {
          final typeStr = state.pathParameters['type']!;
          final type = ServiceType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => ServiceType.movies,
          );
          return ActivityScreen(serviceType: type);
        },
      ),
    ],
  );
});
