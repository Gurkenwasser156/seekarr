import 'package:flutter/material.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/features/activity/presentation/widgets/activity_tab_helpers.dart';

/// Builds one standard activity section sliver group.
List<Widget> buildActivitySliverSection({
  required ActivityTabHelpers helpers,
  required BuildContext context,
  required String title,
  required Future<List<dynamic>> future,
  required Widget Function(dynamic) itemBuilder,
  Widget Function(List<dynamic>)? groupingBuilder,
  bool isLast = false,
}) {
  return [
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: helpers.buildSectionHeaderSliver(context, title),
    ),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: groupingBuilder != null
          ? helpers.buildAsyncSliverListWithGrouping(
              future,
              itemBuilder,
              groupingBuilder: groupingBuilder,
            )
          : helpers.buildAsyncSliverList(future, itemBuilder),
    ),
    if (!isLast)
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
  ];
}
