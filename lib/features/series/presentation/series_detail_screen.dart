import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seekarr/core/api/quality_profile_mixin.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/image_utils.dart';
import 'package:seekarr/core/widgets/delete_media_dialog.dart';
import 'package:seekarr/core/widgets/file_info_section.dart';
import 'package:seekarr/core/widgets/interactive_search_sheet.dart';
import 'package:seekarr/core/widgets/media_detail_view.dart';
import 'package:seekarr/core/widgets/media_management_row.dart';
import 'package:seekarr/core/widgets/media_search_action_row.dart';
import 'package:seekarr/core/widgets/media_search_popup_menu.dart';
import 'package:seekarr/core/widgets/rating_chips_row.dart';
import 'package:seekarr/core/widgets/status_badge.dart';
import 'package:seekarr/core/widgets/tag_chip.dart';
import 'package:seekarr/features/series/data/sonarr_service.dart';
import 'package:seekarr/features/series/domain/models/sonarr_series.dart';
import 'package:seekarr/features/series/presentation/series_provider.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final SonarrSeries series;
  final String heroTag;

  const SeriesDetailScreen({
    super.key,
    required this.series,
    required this.heroTag,
  });

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen>
    with QualityProfileMixin<SeriesDetailScreen> {
  bool _isSearching = false;
  bool _isLoadingReleases = false;
  bool _isDeleting = false;
  List<dynamic> _episodes = [];
  bool _episodesLoaded = false;
  final Set<int> _searchingSeasons = {};
  final Set<int> _searchingEpisodes = {};

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
    loadQualityProfiles(
      fetchProfiles: () => ref.read(sonarrServiceProvider).getQualityProfiles(),
      initialProfileId: widget.series.qualityProfileId,
    );
  }

  Future<void> _loadEpisodes() async {
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      final episodes = await sonarrService.getEpisodes(widget.series.id);
      if (mounted) {
        setState(() {
          _episodes = episodes;
          _episodesLoaded = true;
        });
      }
    } catch (e) {
      // Episodes loading failed, continue without them
      if (mounted) setState(() => _episodesLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(currentSettingsProvider);
    final series = widget.series;
    final title = series.title;
    final network = series.network ?? '';
    final overview = series.overview ?? 'No description available.';
    final status = series.status;
    final genres = series.genres.join(', ');
    final seasons = List<dynamic>.from(series.seasons);

    seasons.sort(
      (a, b) => (a['seasonNumber'] as int).compareTo(b['seasonNumber'] as int),
    );

    final imageSource = ImageUtils.extractPosterUrl(
      series.images,
      baseUrl: settings.sonarrUrl,
      apiKey: settings.sonarrApiKey,
    );

    // Determine status based on episode files
    final stats = series.statistics;
    final episodeFileCount = stats?['episodeFileCount'] as int? ?? 0;
    final hasFiles = episodeFileCount > 0;

    final tags = <Widget>[];
    // Status badge first
    tags.add(StatusBadge.fromMedia(hasFile: hasFiles, status: status));
    if (network.isNotEmpty) tags.add(TagChip(text: network));
    tags.add(
      Text(
        genres,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
      ),
    );

    return MediaDetailView(
      heroTag: widget.heroTag,
      posterUrl: imageSource.url,
      posterHeaders: imageSource.headers,
      contentSections: [
        MediaDetailTitleSection(title: title),
        const SizedBox(height: AppSpacing.sm),
        if (tags.isNotEmpty) ...[
          MediaDetailTagSection(tags: tags),
          const SizedBox(height: AppSpacing.xl),
        ],
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RatingChipsRow(ratings: series.ratings),
              MediaSearchActionRow(
                isSearching: _isSearching,
                isLoadingReleases: _isLoadingReleases,
                onAutomaticSearch: () => _triggerSearch(context, series.id),
                onInteractiveSearch: () =>
                    _showInteractiveSearch(context, series.id),
              ),
              // File info section (only when available)
              if (hasFiles && series.path != null) ...[
                const SizedBox(height: AppSpacing.xl),
                FileInfoSection(path: series.path),
              ],
              // Profile selector (split button) + delete button
              if (currentProfileName != null) ...[
                const SizedBox(height: AppSpacing.lg),
                MediaManagementRow(
                  currentProfileName: currentProfileName!,
                  currentProfileId: currentProfileId,
                  qualityProfiles: qualityProfiles,
                  onProfileSelected: _updateProfile,
                  isDeleting: _isDeleting,
                  onDelete: () => _confirmDelete(context),
                  deleteTooltip: 'Delete Series',
                ),
              ],
            ],
          ),
        ),
        if (overview.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          MediaDetailOverviewSection(overview: overview),
        ],
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seasons', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildSeasonsAccordion(context, seasons),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonsAccordion(BuildContext context, List<dynamic> seasons) {
    return Column(
      children: seasons.map((season) {
        final seasonNumber = season['seasonNumber'] as int;
        final stats = season['statistics'];
        final episodeCount = stats?['episodeFileCount'] ?? 0;
        final totalCount = stats?['totalEpisodeCount'] ?? 0;
        final percent = totalCount > 0 ? (episodeCount / totalCount) : 0.0;
        final isMonitored = season['monitored'] as bool? ?? false;

        // Get episodes for this season
        final seasonEpisodes =
            _episodes.where((e) => e['seasonNumber'] == seasonNumber).toList()
              ..sort(
                (a, b) => (a['episodeNumber'] as int).compareTo(
                  b['episodeNumber'] as int,
                ),
              );

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                seasonNumber.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              seasonNumber == 0 ? 'Specials' : 'Season $seasonNumber',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('$episodeCount / $totalCount Episodes'),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percent.toDouble(),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent == 1.0 ? Colors.green : Colors.orange,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchMenu(
                  context: context,
                  onAutoSearch: () => _searchSeason(context, seasonNumber),
                  onInteractiveSearch: () =>
                      _interactiveSearchSeason(context, seasonNumber),
                  isLoading: _searchingSeasons.contains(seasonNumber),
                ),
                const SizedBox(width: 8),
                Icon(
                  isMonitored ? Icons.bookmark : Icons.bookmark_border,
                  color: isMonitored
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey,
                ),
              ],
            ),
            children: !_episodesLoaded
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ]
                : seasonEpisodes.map<Widget>((episode) {
                    final epNumber = episode['episodeNumber'] as int;
                    final epTitle =
                        episode['title'] as String? ?? 'Episode $epNumber';
                    final hasFile = episode['hasFile'] as bool? ?? false;
                    final episodeId = episode['id'] as int;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: hasFile ? Colors.green : Colors.grey,
                        child: Text(
                          epNumber.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        epTitle,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: _buildSearchMenu(
                        context: context,
                        onAutoSearch: () => _searchEpisode(context, episodeId),
                        onInteractiveSearch: () =>
                            _interactiveSearchEpisode(context, episodeId),
                        isLoading: _searchingEpisodes.contains(episodeId),
                      ),
                      dense: true,
                    );
                  }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchMenu({
    required BuildContext context,
    required VoidCallback onAutoSearch,
    required VoidCallback onInteractiveSearch,
    bool isLoading = false,
  }) {
    return MediaSearchPopupMenu(
      onAutoSearch: onAutoSearch,
      onInteractiveSearch: onInteractiveSearch,
      isLoading: isLoading,
    );
  }

  Future<void> _triggerSearch(BuildContext context, int seriesId) async {
    setState(() => _isSearching = true);
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      await sonarrService.searchSeries(seriesId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search started for entire series')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _showInteractiveSearch(
    BuildContext context,
    int seriesId, {
    int? seasonNumber,
  }) async {
    final sonarrService = ref.read(sonarrServiceProvider);
    await InteractiveSearchSheet.showAsync(
      context: context,
      title: seasonNumber != null
          ? 'Releases for ${widget.series.title} - Season $seasonNumber'
          : 'Releases for ${widget.series.title}',
      fetchReleases: (token) => sonarrService.getReleases(
        seriesId: seriesId,
        seasonNumber: seasonNumber ?? 1,
        cancelToken: token,
      ),
      onGrabRelease: (guid, indexerId) async {
        await sonarrService.grabRelease(guid: guid, indexerId: indexerId);
      },
    );
  }

  Future<void> _searchSeason(BuildContext context, int seasonNumber) async {
    setState(() => _searchingSeasons.add(seasonNumber));
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      await sonarrService.searchSeason(widget.series.id, seasonNumber);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search started for Season $seasonNumber')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _searchingSeasons.remove(seasonNumber));
    }
  }

  Future<void> _interactiveSearchSeason(
    BuildContext context,
    int seasonNumber,
  ) async {
    setState(() => _searchingSeasons.add(seasonNumber));
    try {
      await _showInteractiveSearch(
        context,
        widget.series.id,
        seasonNumber: seasonNumber,
      );
    } finally {
      if (mounted) setState(() => _searchingSeasons.remove(seasonNumber));
    }
  }

  Future<void> _searchEpisode(BuildContext context, int episodeId) async {
    setState(() => _searchingEpisodes.add(episodeId));
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      await sonarrService.searchEpisodes([episodeId]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Episode search started')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _searchingEpisodes.remove(episodeId));
    }
  }

  Future<void> _interactiveSearchEpisode(
    BuildContext context,
    int episodeId,
  ) async {
    final sonarrService = ref.read(sonarrServiceProvider);
    await InteractiveSearchSheet.showAsync(
      context: context,
      title: 'Episode Releases',
      fetchReleases: (token) =>
          sonarrService.getReleases(episodeId: episodeId, cancelToken: token),
      onGrabRelease: (guid, indexerId) async {
        await sonarrService.grabRelease(guid: guid, indexerId: indexerId);
      },
    );
  }

  Future<void> _updateProfile(int profileId) async {
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      await sonarrService.updateSeriesProfile(widget.series.id, profileId);
      if (mounted) {
        updateProfileState(profileId);
        // Invalidate series provider so list refreshes with new data
        ref.invalidate(seriesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quality profile updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDeleteMediaDialog(
      context: context,
      title: widget.series.title,
      mediaType: 'series',
    );

    if (!result.confirmed || !context.mounted) return;

    setState(() => _isDeleting = true);
    try {
      final sonarrService = ref.read(sonarrServiceProvider);
      await sonarrService.deleteSeries(
        widget.series.id,
        deleteFiles: result.deleteFiles,
        addImportListExclusion: result.addExclusion,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Series deleted')));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete series: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}
