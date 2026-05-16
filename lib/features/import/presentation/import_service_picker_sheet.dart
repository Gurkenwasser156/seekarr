import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/features/import/presentation/manual_import_routes.dart';
import 'package:seekarr/features/import/presentation/manual_import_widgets.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

Future<void> showImportServicePickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.55 : 0.3,
    ),
    builder: (context) => const _ImportServicePickerSheet(),
  );
}

class _ImportServicePickerSheet extends StatelessWidget {
  const _ImportServicePickerSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                    borderRadius: AppRadius.borderRadiusFull,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'MANUAL IMPORT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.66,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final service in const [
                ServiceKey.radarr,
                ServiceKey.sonarr,
                ServiceKey.lidarr,
              ])
                _ServicePickerRow(service: service),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicePickerRow extends StatelessWidget {
  final ServiceKey service;

  const _ServicePickerRow({required this.service});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderRadiusMd,
        child: InkWell(
          borderRadius: AppRadius.borderRadiusMd,
          onTap: () {
            Navigator.of(context).pop();
            context.push(manualImportLocation(manualImportBrowsePath, service));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: service.accent.withValues(alpha: 0.14),
                    borderRadius: AppRadius.borderRadiusFull,
                  ),
                  child: Icon(
                    Icons.download_for_offline_rounded,
                    size: 22,
                    color: service.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        service.manualImportSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
