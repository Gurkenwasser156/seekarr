import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/features/import/domain/manual_import_models.dart';
import 'package:seekarr/features/import/presentation/manual_import_provider.dart';
import 'package:seekarr/features/import/presentation/manual_import_routes.dart';
import 'package:seekarr/features/import/presentation/manual_import_widgets.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

class ManualImportBrowseScreen extends ConsumerStatefulWidget {
  final ServiceKey service;
  final int? targetId;

  const ManualImportBrowseScreen({
    super.key,
    required this.service,
    this.targetId,
  });

  @override
  ConsumerState<ManualImportBrowseScreen> createState() =>
      _ManualImportBrowseScreenState();
}

class _ManualImportBrowseScreenState
    extends ConsumerState<ManualImportBrowseScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(manualImportFlowProvider.notifier)
          .start(widget.service, targetId: widget.targetId);
    });
  }

  @override
  void didUpdateWidget(covariant ManualImportBrowseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.targetId != widget.targetId) {
      Future.microtask(() {
        ref
            .read(manualImportFlowProvider.notifier)
            .start(widget.service, targetId: widget.targetId, force: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manualImportFlowProvider);
    final selectedFolder = state.selectedFolder;

    return ManualImportFrame(
      service: widget.service,
      title: 'Choose Folder',
      subtitle: '${widget.service.title} · Manual Import',
      bottomBar: ImportPrimaryButton(
        service: widget.service,
        icon: Icons.folder_open_rounded,
        label: selectedFolder == null
            ? 'Select Folder'
            : 'Use "${manualImportPathName(selectedFolder)}"',
        onPressed: selectedFolder == null
            ? null
            : () => context.push(
                manualImportLocation(
                  manualImportFolderPath,
                  widget.service,
                  targetId: widget.targetId,
                ),
              ),
      ),
      child: _BrowseBody(service: widget.service, state: state),
    );
  }
}

class _BrowseBody extends ConsumerWidget {
  final ServiceKey service;
  final ManualImportFlowState state;

  const _BrowseBody({required this.service, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.error != null && state.rootFolders.isEmpty) {
      return ImportMessage(
        icon: Icons.cloud_off_rounded,
        message: 'Manual import unavailable',
        detail: state.error,
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (state.rootFolders.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                for (final folder in state.rootFolders) ...[
                  FilterChip(
                    selected: folder.path == state.selectedFolder,
                    label: Text(folder.displayName),
                    avatar: Icon(
                      Icons.folder_rounded,
                      size: 16,
                      color: service.accent,
                    ),
                    selectedColor: service.accent.withValues(alpha: 0.16),
                    checkmarkColor: service.accent,
                    side: BorderSide(
                      color: folder.path == state.selectedFolder
                          ? service.accent.withValues(alpha: 0.45)
                          : colorScheme.outlineVariant,
                    ),
                    onSelected: (_) => ref
                        .read(manualImportFlowProvider.notifier)
                        .selectFolder(folder.path),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ImportBreadcrumb(
          service: service,
          path: state.currentPath,
          onSegmentTap: (path) =>
              ref.read(manualImportFlowProvider.notifier).selectFolder(path),
        ),
        if (state.isLoadingBrowse && state.fileSystem == null)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _TipRow(service: service),
          _DirectoryCard(service: service, state: state),
        ],
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  final ServiceKey service;

  const _TipRow({required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: service.accent),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Tap a folder to select it as the import source',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryCard extends ConsumerWidget {
  final ServiceKey service;
  final ManualImportFlowState state;

  const _DirectoryCard({required this.service, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final directories = state.fileSystem?.directories ?? const [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: directories.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: ImportMessage(
                icon: Icons.folder_off_rounded,
                message: 'No subfolders found',
                detail: 'This folder can still be used as the import source.',
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < directories.length; index++)
                  _DirectoryRow(
                    service: service,
                    entry: directories[index],
                    selected: directories[index].path == state.selectedFolder,
                    showDivider: index != directories.length - 1,
                    onTap: () => ref
                        .read(manualImportFlowProvider.notifier)
                        .selectFolder(directories[index].path),
                  ),
              ],
            ),
    );
  }
}

class _DirectoryRow extends StatelessWidget {
  final ServiceKey service;
  final ManualImportFileSystemEntry entry;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  const _DirectoryRow({
    required this.service,
    required this.entry,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? service.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? service.accent : Colors.transparent,
                width: 2,
              ),
              bottom: showDivider
                  ? BorderSide(color: colorScheme.outlineVariant)
                  : BorderSide.none,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.folder_rounded, color: service.accent, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected
                            ? service.accent
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      entry.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 16, color: service.accent),
            ],
          ),
        ),
      ),
    );
  }
}
