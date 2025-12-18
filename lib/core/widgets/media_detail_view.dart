import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MediaDetailView extends StatelessWidget {
  final String title;
  final String heroTag;
  final String? posterUrl;
  final Widget? actions;
  final List<Widget> tags;
  final String overview;
  final List<Widget> slivers;
  final Widget? background;

  const MediaDetailView({
    super.key,
    required this.title,
    required this.heroTag,
    this.posterUrl,
    this.actions,
    this.tags = const [],
    required this.overview,
    this.slivers = const [],
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: heroTag,
                    child: Material(
                      type: MaterialType.transparency,
                      child: posterUrl != null && posterUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: posterUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  Container(color: Colors.grey[900]),
                            )
                          : Container(color: Colors.grey[900]),
                    ),
                  ),
                  // Gradient Overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  if (background != null) background!,
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Area
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (tags.isNotEmpty) ...[
                    Wrap(spacing: 12, runSpacing: 8, children: tags),
                    const SizedBox(height: 24),
                  ],

                  // Actions
                  if (actions != null) ...[
                    actions!,
                    const SizedBox(height: 24),
                  ],

                  // Description
                  if (overview.isNotEmpty) ...[
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overview,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ],

                  // Extra content padding before slivers if needed,
                  // but slivers come next in the CustomScrollView list
                  // so here we just end the "Header" box.
                  if (slivers.isEmpty)
                    const SizedBox(
                      height: 100,
                    ), // Bottom padding if no extra slivers
                ],
              ),
            ),
          ),
          ...slivers,
          if (slivers.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
