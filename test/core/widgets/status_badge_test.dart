import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seekarr/core/widgets/status_badge.dart';

void main() {
  group('StatusBadge.fromMedia', () {
    final cases = <({bool hasFile, String status, MediaStatus expected})>[
      (hasFile: true, status: 'released', expected: MediaStatus.available),
      (hasFile: false, status: 'released', expected: MediaStatus.missing),
      (
        hasFile: false,
        status: 'downloading',
        expected: MediaStatus.downloading,
      ),
      (
        hasFile: false,
        status: 'DOWNLOADING',
        expected: MediaStatus.downloading,
      ),
      (
        hasFile: false,
        status: 'Downloading',
        expected: MediaStatus.downloading,
      ),
      (hasFile: false, status: 'queued', expected: MediaStatus.queued),
    ];
    for (final c in cases) {
      test(
        'hasFile=${c.hasFile} status="${c.status}" -> ${c.expected.name}',
        () {
          final badge = StatusBadge.fromMedia(
            hasFile: c.hasFile,
            status: c.status,
          );
          expect(badge.status, c.expected);
        },
      );
    }

    test('fileCount >= totalCount -> available', () {
      final badge = StatusBadge.fromMedia(
        fileCount: 10,
        totalCount: 10,
        status: 'continuing',
      );
      expect(badge.status, MediaStatus.available);
    });

    test('fileCount > totalCount -> available', () {
      final badge = StatusBadge.fromMedia(
        fileCount: 15,
        totalCount: 10,
        status: 'continuing',
      );
      expect(badge.status, MediaStatus.available);
    });

    test('0 < fileCount < totalCount -> partial', () {
      final badge = StatusBadge.fromMedia(
        fileCount: 4,
        totalCount: 10,
        status: 'continuing',
      );
      expect(badge.status, MediaStatus.partial);
    });

    test('fileCount == 0 with totalCount > 0 -> missing', () {
      final badge = StatusBadge.fromMedia(
        fileCount: 0,
        totalCount: 10,
        status: 'continuing',
      );
      expect(badge.status, MediaStatus.missing);
    });

    test('fileCount == 0 with downloading status -> downloading', () {
      final badge = StatusBadge.fromMedia(
        fileCount: 0,
        totalCount: 10,
        status: 'downloading',
      );
      expect(badge.status, MediaStatus.downloading);
    });

    test('totalCount == 0 falls back to hasFile/status', () {
      final badge = StatusBadge.fromMedia(
        fileCount: 0,
        totalCount: 0,
        hasFile: false,
        status: 'released',
      );
      expect(badge.status, MediaStatus.missing);
    });

    test('null totalCount falls back to fileCount presence', () {
      final badge = StatusBadge.fromMedia(
        fileCount: 2,
        totalCount: null,
        status: 'continuing',
      );
      expect(badge.status, MediaStatus.available);
    });

    test('missing availability inputs throws ArgumentError', () {
      expect(
        () => StatusBadge.fromMedia(status: 'released'),
        throwsArgumentError,
      );
    });
  });

  group('StatusBadge.fromSeerr', () {
    final cases =
        <({int? statusCode, MediaStatus status, String label, IconData icon})>[
          (
            statusCode: null,
            status: MediaStatus.unknown,
            label: 'Available to Request',
            icon: Icons.add_circle_rounded,
          ),
          (
            statusCode: 2,
            status: MediaStatus.queued,
            label: 'Pending',
            icon: Icons.schedule_rounded,
          ),
          (
            statusCode: 3,
            status: MediaStatus.downloading,
            label: 'Processing',
            icon: Icons.sync_rounded,
          ),
          (
            statusCode: 4,
            status: MediaStatus.queued,
            label: 'Partially Available',
            icon: Icons.change_circle_rounded,
          ),
          (
            statusCode: 5,
            status: MediaStatus.available,
            label: 'Available',
            icon: Icons.check_circle_rounded,
          ),
          (
            statusCode: 6,
            status: MediaStatus.missing,
            label: 'Deleted',
            icon: Icons.delete_rounded,
          ),
          (
            statusCode: 999,
            status: MediaStatus.unknown,
            label: 'Unknown',
            icon: Icons.help_outline_rounded,
          ),
        ];

    for (final c in cases) {
      testWidgets(
        'renders ${c.label} for Seerr status ${c.statusCode ?? 'null'}',
        (tester) async {
          final badge = StatusBadge.fromSeerr(statusCode: c.statusCode);
          expect(badge.status, c.status);

          await tester.pumpWidget(MaterialApp(home: Scaffold(body: badge)));
          expect(find.text(c.label), findsOneWidget);
          expect(find.byIcon(c.icon), findsOneWidget);
        },
      );
    }
  });

  group('StatusBadge widget rendering', () {
    testWidgets('compact mode renders no label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: MediaStatus.available, compact: true),
          ),
        ),
      );
      expect(find.byType(StatusBadge), findsOneWidget);
      expect(find.text('Available'), findsNothing);
    });

    final fullModeCases = <({MediaStatus status, String label, IconData icon})>[
      (
        status: MediaStatus.available,
        label: 'Available',
        icon: Icons.check_circle_rounded,
      ),
      (
        status: MediaStatus.partial,
        label: 'Partial',
        icon: Icons.donut_large_rounded,
      ),
      (
        status: MediaStatus.missing,
        label: 'Missing',
        icon: Icons.cancel_rounded,
      ),
      (
        status: MediaStatus.downloading,
        label: 'Downloading',
        icon: Icons.downloading_rounded,
      ),
      (
        status: MediaStatus.queued,
        label: 'Queued',
        icon: Icons.schedule_rounded,
      ),
      (
        status: MediaStatus.unknown,
        label: 'Unknown',
        icon: Icons.help_outline_rounded,
      ),
    ];

    for (final c in fullModeCases) {
      testWidgets('full mode renders ${c.status.name}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StatusBadge(status: c.status)),
          ),
        );
        expect(find.text(c.label), findsOneWidget);
        expect(find.byIcon(c.icon), findsOneWidget);
      });
    }
  });
}
