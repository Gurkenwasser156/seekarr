import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/features/import/domain/manual_import_models.dart';
import 'package:seekarr/features/import/presentation/manual_import_provider.dart';
import 'package:seekarr/features/import/presentation/manual_import_widgets.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

class ManualImportProgressScreen extends ConsumerStatefulWidget {
  final ServiceKey service;

  const ManualImportProgressScreen({super.key, required this.service});

  @override
  ConsumerState<ManualImportProgressScreen> createState() =>
      _ManualImportProgressScreenState();
}

class _ManualImportProgressScreenState
    extends ConsumerState<ManualImportProgressScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      ref.read(manualImportFlowProvider.notifier).pollCommand();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manualImportFlowProvider);
    final command = state.command;
    if (command == null || !command.isActive) {
      _pollTimer?.cancel();
    }

    return ManualImportFrame(
      service: widget.service,
      title: 'Import Results',
      subtitle:
          '${widget.service.title} · ${state.submittedItems.length} files',
      bottomBar: _ProgressButtons(
        service: widget.service,
        command: command,
        onDone: () => context.go('/activity'),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ImportStepPills(service: widget.service, activeStep: 3),
          if (command == null)
            const ImportMessage(
              icon: Icons.downloading_rounded,
              message: 'Import has not started',
              detail: 'Go back and confirm selected files to begin.',
            )
          else ...[
            _CommandStatusCard(
              service: widget.service,
              command: command,
              fileCount: state.submittedItems.length,
            ),
            for (final item in state.submittedItems)
              _ProgressFileRow(item: item, command: command),
          ],
        ],
      ),
    );
  }
}

class _CommandStatusCard extends StatelessWidget {
  final ServiceKey service;
  final ManualImportCommandStatus command;
  final int fileCount;

  const _CommandStatusCard({
    required this.service,
    required this.command,
    required this.fileCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = importStatusColor(command.status);
    final borderColor = command.isCompleted || command.isFailure
        ? statusColor.withValues(alpha: 0.35)
        : colorScheme.outlineVariant;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ManualImport',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              _StatusChip(label: command.status, color: statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'STARTED',
                  value: _timeValue(command.started),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'DURATION',
                  value: command.duration ?? 'Running',
                ),
              ),
              Expanded(
                child: _Metric(label: 'FILES', value: '$fileCount'),
              ),
            ],
          ),
          if (command.message?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              command.message!,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (command.exception?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: Text(
                command.exception!,
                style: const TextStyle(fontSize: 11, color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressFileRow extends StatelessWidget {
  final ManualImportItem item;
  final ManualImportCommandStatus command;

  const _ProgressFileRow({required this.item, required this.command});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = _ProgressItemState.fromCommand(command);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: state.isFailure
              ? AppColors.error.withValues(alpha: 0.35)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: state.color.withValues(alpha: 0.12),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: state.isActive
                ? SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: state.color,
                    ),
                  )
                : Icon(state.icon, size: 16, color: state.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.mediaTitle} → ${item.qualityLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  formatImportBytes(item.size),
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressButtons extends StatelessWidget {
  final ServiceKey service;
  final ManualImportCommandStatus? command;
  final VoidCallback onDone;

  const _ProgressButtons({
    required this.service,
    required this.command,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final showRetry = command?.isFailure == true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (showRetry) ...[
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Failed'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.12),
                  foregroundColor: AppColors.error,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: FilledButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.done_rounded, size: 18),
              label: const Text('Done'),
              style: FilledButton.styleFrom(
                backgroundColor: service.accent,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressItemState {
  final IconData icon;
  final Color color;
  final bool isActive;
  final bool isFailure;

  const _ProgressItemState({
    required this.icon,
    required this.color,
    this.isActive = false,
    this.isFailure = false,
  });

  factory _ProgressItemState.fromCommand(ManualImportCommandStatus command) {
    if (command.isFailure) {
      return const _ProgressItemState(
        icon: Icons.close_rounded,
        color: AppColors.error,
        isFailure: true,
      );
    }

    if (command.isCompleted) {
      return const _ProgressItemState(
        icon: Icons.check_rounded,
        color: AppColors.success,
      );
    }

    return const _ProgressItemState(
      icon: Icons.schedule_rounded,
      color: AppColors.info,
      isActive: true,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.45,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

String _timeValue(String? isoValue) {
  if (isoValue == null || isoValue.isEmpty) return 'Pending';
  final parsed = DateTime.tryParse(isoValue)?.toLocal();
  if (parsed == null) return isoValue;
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
