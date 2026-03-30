import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/utils/sheet_utils.dart';
import 'package:seekarr/features/discover/domain/models/discover_detail_model.dart';

class DiscoverVideosButton extends StatelessWidget {
  final List<RelatedVideo> videos;

  const DiscoverVideosButton({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: videos.isEmpty ? null : () => _showVideosSheet(context),
      icon: const Icon(Icons.play_circle_outline_rounded),
      label: const Text('Videos'),
    );
  }

  void _showVideosSheet(BuildContext context) {
    final pageContext = context;
    final sortedVideos = [...videos]..sort(_compareVideos);

    SheetUtils.showSeekarrModalSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Videos', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sortedVideos.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final video = sortedVideos[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_arrow_rounded),
                    title: Text(video.name),
                    subtitle: Text('${video.type} • ${video.site}'),
                    onTap: video.url.isEmpty
                        ? null
                        : () => _openVideo(
                            pageContext: pageContext,
                            sheetContext: sheetContext,
                            video: video,
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openVideo({
    required BuildContext pageContext,
    required BuildContext sheetContext,
    required RelatedVideo video,
  }) async {
    final messenger = ScaffoldMessenger.of(pageContext);
    final uri = Uri.tryParse(video.url);
    if (uri == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open this video.')),
      );
      return;
    }

    Navigator.of(sheetContext).pop();
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && pageContext.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open this video.')),
      );
    }
  }
}

int _compareVideos(RelatedVideo left, RelatedVideo right) {
  final leftPriority = _videoTypePriority(left.type);
  final rightPriority = _videoTypePriority(right.type);
  if (leftPriority != rightPriority) {
    return leftPriority.compareTo(rightPriority);
  }

  return left.name.compareTo(right.name);
}

int _videoTypePriority(String type) {
  return switch (type.toLowerCase()) {
    'trailer' => 0,
    'teaser' => 1,
    'clip' => 2,
    'featurette' => 3,
    _ => 99,
  };
}
