import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/discover/domain/models/discover_detail_model.dart';
import 'package:seekarr/features/discover/presentation/widgets/discover_seasons_list.dart';

void main() {
  testWidgets('shows episodes for the selected season pill', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiscoverSeasonsList(
            seasons: [
              TvSeason(
                id: 1,
                seasonNumber: 1,
                name: 'Season 1',
                episodeCount: 1,
                episodes: [TvEpisodeSummary(name: 'Pilot', episodeNumber: 1)],
              ),
              TvSeason(
                id: 2,
                seasonNumber: 2,
                name: 'Season 2',
                episodeCount: 1,
                episodes: [
                  TvEpisodeSummary(name: 'Second Start', episodeNumber: 1),
                ],
              ),
            ],
            mediaInfo: null,
          ),
        ),
      ),
    );

    expect(find.text('Pilot'), findsOneWidget);
    expect(find.text('Second Start'), findsNothing);

    await tester.tap(find.text('Season 2'));
    await tester.pumpAndSettle();

    expect(find.text('Second Start'), findsOneWidget);
    expect(find.text('Pilot'), findsNothing);
  });
}
