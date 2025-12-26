import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seekarr/core/widgets/file_info_section.dart';

void main() {
  group('FileInfoSection', () {
    testWidgets('renders nothing when both path and filename are null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FileInfoSection())),
      );

      // Should render SizedBox.shrink()
      expect(find.byType(FileInfoSection), findsOneWidget);
      expect(find.text('File Information'), findsNothing);
    });

    testWidgets('renders path when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FileInfoSection(path: '/movies/Avatar')),
        ),
      );

      expect(find.text('File Information'), findsOneWidget);
      expect(find.text('/movies/Avatar'), findsOneWidget);
      // folder_rounded in header, folder_outlined in info row
      expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    });

    testWidgets('renders filename when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileInfoSection(filename: 'Avatar.2009.1080p.mkv'),
          ),
        ),
      );

      expect(find.text('File Information'), findsOneWidget);
      expect(find.text('Avatar.2009.1080p.mkv'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });

    testWidgets('renders both path and filename when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileInfoSection(
              path: '/movies/Avatar',
              filename: 'Avatar.2009.1080p.mkv',
            ),
          ),
        ),
      );

      expect(find.text('File Information'), findsOneWidget);
      expect(find.text('/movies/Avatar'), findsOneWidget);
      expect(find.text('Avatar.2009.1080p.mkv'), findsOneWidget);
    });

    testWidgets('handles long paths with ellipsis', (tester) async {
      const longPath =
          '/very/long/path/to/movies/that/should/be/truncated/with/ellipsis';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 200, child: FileInfoSection(path: longPath)),
          ),
        ),
      );

      expect(find.text('File Information'), findsOneWidget);
      // Text widget should handle overflow
      expect(find.byType(FileInfoSection), findsOneWidget);
    });
  });
}
