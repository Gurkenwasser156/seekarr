import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/widgets/release_list_widgets.dart';

void main() {
  group('InfoChip', () {
    testWidgets('renders its icon and text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoChip(icon: Icons.dns_outlined, text: 'NZBgeek'),
          ),
        ),
      );

      expect(find.byIcon(Icons.dns_outlined), findsOneWidget);
      expect(find.text('NZBgeek'), findsOneWidget);
    });
  });

  group('CustomFormatChip', () {
    testWidgets('renders positive scores with a plus sign', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomFormatChip(name: 'HDR', score: 10)),
        ),
      );

      expect(find.text('HDR'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
    });

    testWidgets('renders negative scores without a plus sign', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomFormatChip(name: 'BR-DISK', score: -5)),
        ),
      );

      expect(find.text('BR-DISK'), findsOneWidget);
      expect(find.text('-5'), findsOneWidget);
    });

    testWidgets('treats zero as a positive score', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomFormatChip(name: 'x265', score: 0)),
        ),
      );

      expect(find.text('+0'), findsOneWidget);
    });
  });

  group('ReleaseListItem', () {
    testWidgets('renders the title and subtitle metadata', (tester) async {
      await _pumpReleaseItem(
        tester,
        release: buildRelease(
          title: 'My.Movie.2024.1080p',
          indexer: 'NZBgeek',
          size: 1073741824,
          seeders: 42,
          quality: {
            'quality': {'name': 'Bluray-1080p'},
          },
          ageMinutes: 2880,
        ),
      );

      expect(find.text('My.Movie.2024.1080p'), findsOneWidget);
      expect(find.text('NZBgeek'), findsOneWidget);
      expect(find.text('1.00 GB'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Bluray-1080p'), findsOneWidget);
      expect(find.text('2d'), findsOneWidget);
      expect(find.text('+0'), findsOneWidget);
      expect(find.text('CF'), findsOneWidget);
    });

    testWidgets('falls back to Unknown when the title is missing', (
      tester,
    ) async {
      await _pumpReleaseItem(tester, release: buildRelease(title: null));

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('calls onGrab when the download button is tapped', (
      tester,
    ) async {
      var grabbed = false;

      await _pumpReleaseItem(
        tester,
        release: buildRelease(),
        onGrab: () => grabbed = true,
      );

      await tester.tap(find.byTooltip('Grab Release'));
      await tester.pump();

      expect(grabbed, isTrue);
    });

    testWidgets('uses a green action color for approved releases', (
      tester,
    ) async {
      await _pumpReleaseItem(
        tester,
        release: buildRelease(approved: true, rejections: const []),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.color, Colors.green);
    });

    testWidgets('uses an orange action color for pending releases', (
      tester,
    ) async {
      await _pumpReleaseItem(
        tester,
        release: buildRelease(approved: false, rejections: const []),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.color, Colors.orange);
    });

    testWidgets('shows string rejection reasons for rejected releases', (
      tester,
    ) async {
      await _pumpReleaseItem(
        tester,
        release: buildRelease(
          approved: false,
          rejections: const ['Minimum seeders not met'],
        ),
      );

      await _expandRelease(tester);

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.color, Colors.red);
      expect(find.text('Rejection Reasons'), findsOneWidget);
      expect(find.text('Minimum seeders not met'), findsOneWidget);
    });

    testWidgets('shows object rejection reasons for rejected releases', (
      tester,
    ) async {
      await _pumpReleaseItem(
        tester,
        release: buildRelease(
          approved: false,
          rejections: const [
            {'reason': 'Protocol not allowed'},
          ],
        ),
      );

      await _expandRelease(tester);

      expect(find.text('Protocol not allowed'), findsOneWidget);
    });

    testWidgets('shows custom formats and a score badge when expanded', (
      tester,
    ) async {
      await _pumpReleaseItem(
        tester,
        release: buildRelease(
          customFormatScore: 4,
          customFormats: const [
            {'name': 'HDR', 'score': 5},
            {'name': 'DV', 'score': -1},
          ],
        ),
      );

      await _expandRelease(tester);

      expect(find.text('Custom Formats'), findsOneWidget);
      expect(find.text('Score: +4'), findsOneWidget);
      expect(find.text('HDR'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('DV'), findsOneWidget);
      expect(find.text('-1'), findsOneWidget);
    });

    testWidgets('shows an empty custom format message when appropriate', (
      tester,
    ) async {
      await _pumpReleaseItem(
        tester,
        release: buildRelease(customFormats: const [], rejections: const []),
      );

      await _expandRelease(tester);

      expect(find.text('No custom format data available'), findsOneWidget);
    });

    testWidgets('formats file sizes across units', (tester) async {
      await _pumpReleaseItem(tester, release: buildRelease(size: 500));
      expect(find.text('500 B'), findsOneWidget);

      await _pumpReleaseItem(tester, release: buildRelease(size: 1536));
      expect(find.text('1.5 KB'), findsOneWidget);

      await _pumpReleaseItem(tester, release: buildRelease(size: 5242880));
      expect(find.text('5.0 MB'), findsOneWidget);
    });

    testWidgets('formats ages across minutes, hours, and days', (tester) async {
      await _pumpReleaseItem(tester, release: buildRelease(ageMinutes: 30));
      expect(find.text('30m'), findsOneWidget);

      await _pumpReleaseItem(tester, release: buildRelease(ageMinutes: 120));
      expect(find.text('2h'), findsOneWidget);

      await _pumpReleaseItem(tester, release: buildRelease(ageMinutes: 4320));
      expect(find.text('3d'), findsOneWidget);
    });
  });
}

Map<String, dynamic> buildRelease({
  String? title = 'Test Release',
  String indexer = 'NZBgeek',
  num size = 1073741824,
  num seeders = 10,
  Map<String, dynamic>? quality,
  num ageMinutes = 60,
  int customFormatScore = 0,
  List<dynamic> customFormats = const [],
  List<dynamic> rejections = const [],
  bool approved = true,
}) {
  return {
    'title': title,
    'indexer': indexer,
    'size': size,
    'seeders': seeders,
    'quality':
        quality ??
        {
          'quality': {'name': 'Bluray-1080p'},
        },
    'ageMinutes': ageMinutes,
    'customFormatScore': customFormatScore,
    'customFormats': customFormats,
    'rejections': rejections,
    'approved': approved,
  };
}

Future<void> _pumpReleaseItem(
  WidgetTester tester, {
  required Map<String, dynamic> release,
  VoidCallback onGrab = _noop,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReleaseListItem(release: release, onGrab: onGrab),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expandRelease(WidgetTester tester) async {
  await tester.tap(find.byType(ExpansionTile));
  await tester.pumpAndSettle();
}

void _noop() {}
