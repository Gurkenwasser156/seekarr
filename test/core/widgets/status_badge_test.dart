import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seekarr/core/widgets/status_badge.dart';

void main() {
  group('MediaStatus enum', () {
    test('has all expected values', () {
      expect(MediaStatus.values.length, 5);
      expect(MediaStatus.available, isNotNull);
      expect(MediaStatus.missing, isNotNull);
      expect(MediaStatus.downloading, isNotNull);
      expect(MediaStatus.queued, isNotNull);
      expect(MediaStatus.unknown, isNotNull);
    });
  });

  group('StatusBadge factory', () {
    test('returns available status when hasFile is true', () {
      final badge = StatusBadge.fromMedia(hasFile: true, status: 'released');
      expect(badge.status, MediaStatus.available);
    });

    test(
      'returns missing status when hasFile is false and status is not special',
      () {
        final badge = StatusBadge.fromMedia(hasFile: false, status: 'released');
        expect(badge.status, MediaStatus.missing);
      },
    );

    test('returns downloading status when status is downloading', () {
      final badge = StatusBadge.fromMedia(
        hasFile: false,
        status: 'downloading',
      );
      expect(badge.status, MediaStatus.downloading);
    });

    test('returns queued status when status is queued', () {
      final badge = StatusBadge.fromMedia(hasFile: false, status: 'queued');
      expect(badge.status, MediaStatus.queued);
    });

    test('is case insensitive for status', () {
      final badge1 = StatusBadge.fromMedia(
        hasFile: false,
        status: 'DOWNLOADING',
      );
      final badge2 = StatusBadge.fromMedia(
        hasFile: false,
        status: 'Downloading',
      );
      expect(badge1.status, MediaStatus.downloading);
      expect(badge2.status, MediaStatus.downloading);
    });
  });

  group('StatusBadge widget', () {
    testWidgets('renders compact mode correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: MediaStatus.available, compact: true),
          ),
        ),
      );

      // Compact mode should render a small circle, not text
      expect(find.byType(StatusBadge), findsOneWidget);
      // Should not find text in compact mode
      expect(find.text('Available'), findsNothing);
    });

    testWidgets('renders full mode with icon and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: MediaStatus.available, compact: false),
          ),
        ),
      );

      expect(find.text('Available'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders missing status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusBadge(status: MediaStatus.missing)),
        ),
      );

      expect(find.text('Missing'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    });

    testWidgets('renders downloading status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusBadge(status: MediaStatus.downloading)),
        ),
      );

      expect(find.text('Downloading'), findsOneWidget);
      expect(find.byIcon(Icons.downloading_rounded), findsOneWidget);
    });

    testWidgets('renders queued status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusBadge(status: MediaStatus.queued)),
        ),
      );

      expect(find.text('Queued'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('renders unknown status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusBadge(status: MediaStatus.unknown)),
        ),
      );

      expect(find.text('Unknown'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    });
  });
}
