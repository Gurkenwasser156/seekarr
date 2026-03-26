import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/models/rating_source.dart';
import 'package:seekarr/core/widgets/rating_chip.dart';
import 'package:seekarr/core/widgets/rating_chips_row.dart';

void main() {
  group('RatingChipsRow', () {
    testWidgets('renders nothing when ratings list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RatingChipsRow(ratings: [])),
        ),
      );

      expect(find.byType(RatingChip), findsNothing);
    });

    testWidgets('renders correct number of RatingChip widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatingChipsRow(
              ratings: const [
                RatingSource(name: 'IMDb', value: 7.5, votes: 1000, icon: 'IM'),
                RatingSource(name: 'RT', value: 85.0, votes: 500, icon: 'RT'),
                RatingSource(name: 'MC', value: 70.0, votes: 200, icon: 'MC'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(RatingChip), findsNWidgets(3));
    });

    testWidgets('displays formatted rating values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatingChipsRow(
              ratings: const [
                RatingSource(
                  name: 'IMDb',
                  value: 7.567,
                  votes: 1000,
                  icon: 'IM',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining('7.6'), findsOneWidget);
    });

    testWidgets('has trailing spacing when non-empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatingChipsRow(
              ratings: const [
                RatingSource(name: 'IMDb', value: 7.5, votes: 1000, icon: 'IM'),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == AppSpacing.lg,
        ),
        findsOneWidget,
      );
    });
  });
}
