import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/activity/presentation/widgets/grouped_series_list.dart';

void main() {
  group('GroupedSeriesList', () {
    testWidgets('groups episodes by series title', (tester) async {
      final items = [
        {
          'series': {'title': 'Show B'},
          'seasonNumber': 1,
          'episodeNumber': 2,
          'title': 'Ep2',
        },
        {
          'series': {'title': 'Show A'},
          'seasonNumber': 1,
          'episodeNumber': 1,
          'title': 'Pilot',
        },
        {
          'series': {'title': 'Show B'},
          'seasonNumber': 1,
          'episodeNumber': 1,
          'title': 'Ep1',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: GroupedSeriesList(items: items)),
          ),
        ),
      );

      expect(find.text('Show A'), findsOneWidget);
      expect(find.text('Show B'), findsOneWidget);
      expect(find.text('1 episode'), findsOneWidget);
      expect(find.text('2 episodes'), findsOneWidget);
    });

    testWidgets('sorts episodes by season then episode number', (tester) async {
      final items = [
        {
          'series': {'title': 'Show'},
          'seasonNumber': 2,
          'episodeNumber': 1,
          'title': 'S2E1',
        },
        {
          'series': {'title': 'Show'},
          'seasonNumber': 1,
          'episodeNumber': 3,
          'title': 'S1E3',
        },
        {
          'series': {'title': 'Show'},
          'seasonNumber': 1,
          'episodeNumber': 1,
          'title': 'S1E1',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: GroupedSeriesList(items: items)),
          ),
        ),
      );

      expect(find.text('Show'), findsOneWidget);
      expect(find.text('3 episodes'), findsOneWidget);
    });

    testWidgets('handles seriesTitle fallback field', (tester) async {
      final items = [
        {
          'seriesTitle': 'Fallback Show',
          'seasonNumber': 1,
          'episodeNumber': 1,
          'title': 'Ep1',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: GroupedSeriesList(items: items)),
          ),
        ),
      );

      expect(find.text('Fallback Show'), findsOneWidget);
    });

    testWidgets('uses Unknown Series when no series info', (tester) async {
      final items = [
        {'seasonNumber': 1, 'episodeNumber': 1, 'title': 'Orphan Episode'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: GroupedSeriesList(items: items)),
          ),
        ),
      );

      expect(find.text('Unknown Series'), findsOneWidget);
    });

    testWidgets('renders empty column for empty items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: GroupedSeriesList(items: [])),
          ),
        ),
      );

      expect(find.byType(ExpansionTile), findsNothing);
    });
  });
}
