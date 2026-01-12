import 'package:flutter_test/flutter_test.dart';
import 'package:seekarr/core/utils/release_utils.dart';

void main() {
  group('InteractiveSearchSheet', () {
    group('formatReleaseSize', () {
      test('formats bytes correctly', () {
        expect(formatReleaseSize(0), '0 B');
        expect(formatReleaseSize(512), '512 B');
        expect(formatReleaseSize(1024), '1.0 KB');
        expect(formatReleaseSize(1536), '1.5 KB');
        expect(formatReleaseSize(1048576), '1.0 MB');
        expect(formatReleaseSize(1073741824), '1.00 GB');
        expect(formatReleaseSize(2147483648), '2.00 GB');
      });
    });

    group('formatReleaseAge', () {
      test('formats minutes correctly', () {
        expect(formatReleaseAge(0), '0m');
        expect(formatReleaseAge(30), '30m');
        expect(formatReleaseAge(60), '1h');
        expect(formatReleaseAge(120), '2h');
        expect(formatReleaseAge(1440), '1d');
        expect(formatReleaseAge(2880), '2d');
      });
    });

    group('release data parsing', () {
      test('handles int values for numeric fields', () {
        final release = {
          'title': 'Test Release',
          'indexer': 'TestIndexer',
          'size': 1073741824,
          'seeders': 100,
          'leechers': 50,
          'ageMinutes': 1440,
          'approved': true,
        };

        final sizeNum = release['size'] as num? ?? 0;
        final seeders = (release['seeders'] as num?)?.toInt() ?? 0;
        final leechers = (release['leechers'] as num?)?.toInt() ?? 0;
        final ageNum = release['ageMinutes'] as num? ?? 0;

        expect(sizeNum.toInt(), 1073741824);
        expect(seeders, 100);
        expect(leechers, 50);
        expect(ageNum.toInt(), 1440);
      });

      test('handles double values for numeric fields', () {
        final release = {
          'title': 'Test Release',
          'indexer': 'TestIndexer',
          'size': 1073741824.5,
          'seeders': 100.0,
          'leechers': 50.0,
          'ageMinutes': 1440.5,
          'approved': true,
        };

        final sizeNum = release['size'] as num? ?? 0;
        final seeders = (release['seeders'] as num?)?.toInt() ?? 0;
        final leechers = (release['leechers'] as num?)?.toInt() ?? 0;
        final ageNum = release['ageMinutes'] as num? ?? 0;

        // Should convert doubles to int without throwing
        expect(sizeNum.toInt(), 1073741824);
        expect(seeders, 100);
        expect(leechers, 50);
        expect(ageNum.toInt(), 1440);
      });

      test('handles null values for numeric fields', () {
        final release = <String, dynamic>{
          'title': 'Test Release',
          'indexer': 'TestIndexer',
          'size': null,
          'seeders': null,
          'leechers': null,
          'ageMinutes': null,
          'approved': null,
        };

        final sizeNum = release['size'] as num? ?? 0;
        final seeders = (release['seeders'] as num?)?.toInt() ?? 0;
        final leechers = (release['leechers'] as num?)?.toInt() ?? 0;
        final ageNum = release['ageMinutes'] as num? ?? 0;
        final isApproved = release['approved'] as bool? ?? false;

        expect(sizeNum.toInt(), 0);
        expect(seeders, 0);
        expect(leechers, 0);
        expect(ageNum.toInt(), 0);
        expect(isApproved, false);
      });
    });

    // Sorting logic tests using the extracted pure function
    group('sorting logic', () {
      late List<Map<String, dynamic>> testReleases;

      setUp(() {
        testReleases = [
          {
            'title': 'Release A',
            'customFormatScore': 100,
            'size': 5000000000,
            'seeders': 50,
            'ageMinutes': 1440, // 1 day old
            'indexer': 'Indexer1',
            'rejections': <dynamic>[],
          },
          {
            'title': 'Release B',
            'customFormatScore': 200,
            'size': 3000000000,
            'seeders': 100,
            'ageMinutes': 60, // 1 hour old (newest)
            'indexer': 'Indexer2',
            'rejections': <dynamic>[],
          },
          {
            'title': 'Release C',
            'customFormatScore': 150,
            'size': 8000000000,
            'seeders': 25,
            'ageMinutes': 2880, // 2 days old (oldest)
            'indexer': 'Indexer1',
            'rejections': <dynamic>['Bad quality'],
          },
        ];
      });

      group('sort by CF Score', () {
        test('sorts by CF score descending by default', () {
          final sorted = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'Release B'); // 200
          expect(sorted[1]['title'], 'Release C'); // 150
          expect(sorted[2]['title'], 'Release A'); // 100
        });

        test('sorts by CF score ascending when toggled', () {
          final sorted = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.score,
            sortAscending: true,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'Release A'); // 100
          expect(sorted[1]['title'], 'Release C'); // 150
          expect(sorted[2]['title'], 'Release B'); // 200
        });

        test('handles null CF score - treats as 0', () {
          final releases = [
            {'title': 'With Score', 'customFormatScore': 50, 'rejections': []},
            {'title': 'No Score', 'customFormatScore': null, 'rejections': []},
            {'title': 'Missing Score', 'rejections': []},
          ];

          final sorted = filterAndSortReleases(
            releases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'With Score'); // 50
          // Both null/missing should be at the end with same value (0)
          expect(sorted.sublist(1).map((r) => r['title']).toSet(), {
            'No Score',
            'Missing Score',
          });
        });
      });

      group('sort by Size', () {
        test('sorts by size descending by default', () {
          final sorted = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.size,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'Release C'); // 8GB
          expect(sorted[1]['title'], 'Release A'); // 5GB
          expect(sorted[2]['title'], 'Release B'); // 3GB
        });

        test('sorts by size ascending when toggled', () {
          final sorted = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.size,
            sortAscending: true,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'Release B'); // 3GB
          expect(sorted[1]['title'], 'Release A'); // 5GB
          expect(sorted[2]['title'], 'Release C'); // 8GB
        });

        test('handles null size - treats as 0', () {
          final releases = [
            {'title': 'With Size', 'size': 1000, 'rejections': []},
            {'title': 'No Size', 'size': null, 'rejections': []},
          ];

          final sorted = filterAndSortReleases(
            releases,
            sortType: ReleaseSortType.size,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'With Size');
          expect(sorted[1]['title'], 'No Size');
        });
      });

      group('sort by Seeders', () {
        test('sorts by seeders descending by default', () {
          final sorted = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.seeders,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'Release B'); // 100
          expect(sorted[1]['title'], 'Release A'); // 50
          expect(sorted[2]['title'], 'Release C'); // 25
        });

        test('sorts by seeders ascending when toggled', () {
          final sorted = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.seeders,
            sortAscending: true,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'Release C'); // 25
          expect(sorted[1]['title'], 'Release A'); // 50
          expect(sorted[2]['title'], 'Release B'); // 100
        });

        test('handles zero seeders correctly', () {
          final releases = [
            {'title': 'With Seeders', 'seeders': 10, 'rejections': []},
            {'title': 'Zero Seeders', 'seeders': 0, 'rejections': []},
          ];

          final sorted = filterAndSortReleases(
            releases,
            sortType: ReleaseSortType.seeders,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'With Seeders');
          expect(sorted[1]['title'], 'Zero Seeders');
        });
      });

      group('sort by Age', () {
        test('sorts by age ascending by default (newest first)', () {
          final sorted = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.age,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          // Age default is ascending (newest = smallest ageMinutes first)
          // But with sortAscending=false, we negate, so we get: newest first
          expect(sorted[0]['title'], 'Release B'); // 60 min (newest)
          expect(sorted[1]['title'], 'Release A'); // 1440 min
          expect(sorted[2]['title'], 'Release C'); // 2880 min (oldest)
        });

        test('sorts by age descending when toggled (oldest first)', () {
          final sorted = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.age,
            sortAscending: true,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'Release C'); // 2880 min (oldest)
          expect(sorted[1]['title'], 'Release A'); // 1440 min
          expect(sorted[2]['title'], 'Release B'); // 60 min (newest)
        });

        test('handles null age - treats as 0 (newest)', () {
          final releases = [
            {'title': 'Old', 'ageMinutes': 1440, 'rejections': []},
            {'title': 'Unknown Age', 'ageMinutes': null, 'rejections': []},
          ];

          final sorted = filterAndSortReleases(
            releases,
            sortType: ReleaseSortType.age,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted[0]['title'], 'Unknown Age'); // 0 = newest
          expect(sorted[1]['title'], 'Old');
        });
      });

      group('edge cases', () {
        test('handles empty release list', () {
          final sorted = filterAndSortReleases(
            [],
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted, isEmpty);
        });

        test('handles single release', () {
          final releases = [
            {'title': 'Only One', 'customFormatScore': 100, 'rejections': []},
          ];

          final sorted = filterAndSortReleases(
            releases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted.length, 1);
          expect(sorted[0]['title'], 'Only One');
        });

        test('handles releases with all null values', () {
          final releases = [
            <String, dynamic>{
              'title': 'All Null',
              'customFormatScore': null,
              'size': null,
              'seeders': null,
              'ageMinutes': null,
              'indexer': null,
              'rejections': null,
            },
          ];

          // Should not throw
          final sorted = filterAndSortReleases(
            releases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(sorted.length, 1);
        });

        test('maintains stable sort order when values are equal', () {
          final releases = [
            {'title': 'First', 'customFormatScore': 100, 'rejections': []},
            {'title': 'Second', 'customFormatScore': 100, 'rejections': []},
            {'title': 'Third', 'customFormatScore': 100, 'rejections': []},
          ];

          // Run multiple times to check stability
          for (var i = 0; i < 5; i++) {
            final sorted = filterAndSortReleases(
              releases,
              sortType: ReleaseSortType.score,
              sortAscending: false,
              hideRejected: false,
              selectedIndexer: null,
            );

            // Dart's sort is stable, so order should be preserved
            expect(sorted[0]['title'], 'First');
            expect(sorted[1]['title'], 'Second');
            expect(sorted[2]['title'], 'Third');
          }
        });
      });
    });

    // Filtering logic tests
    group('filtering logic', () {
      late List<Map<String, dynamic>> testReleases;

      setUp(() {
        testReleases = [
          {
            'title': 'Approved Release',
            'indexer': 'Indexer1',
            'rejections': <dynamic>[],
            'customFormatScore': 100,
          },
          {
            'title': 'Rejected Release',
            'indexer': 'Indexer2',
            'rejections': <dynamic>['Bad quality', 'Wrong format'],
            'customFormatScore': 50,
          },
          {
            'title': 'Another Approved',
            'indexer': 'Indexer1',
            'rejections': <dynamic>[],
            'customFormatScore': 75,
          },
          {
            'title': 'Rejected from Indexer1',
            'indexer': 'Indexer1',
            'rejections': <dynamic>['Size too small'],
            'customFormatScore': 25,
          },
        ];
      });

      group('hide rejected filter', () {
        test('shows all releases when hideRejected is false', () {
          final filtered = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(filtered.length, 4);
        });

        test('hides rejected releases when hideRejected is true', () {
          final filtered = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: true,
            selectedIndexer: null,
          );

          expect(filtered.length, 2);
          expect(
            filtered.every((r) => (r['rejections'] as List).isEmpty),
            isTrue,
          );
        });

        test('handles null rejections field', () {
          final releases = [
            {'title': 'No Rejections Field', 'customFormatScore': 100},
          ];

          final filtered = filterAndSortReleases(
            releases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: true,
            selectedIndexer: null,
          );

          // null rejections = empty = should be shown
          expect(filtered.length, 1);
        });

        test('handles rejections as object format {reason: String}', () {
          final releases = [
            {
              'title': 'Object Rejections',
              'rejections': [
                {'reason': 'Bad quality'},
              ],
              'customFormatScore': 100,
            },
            {
              'title': 'No Rejections',
              'rejections': <dynamic>[],
              'customFormatScore': 50,
            },
          ];

          final filtered = filterAndSortReleases(
            releases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: true,
            selectedIndexer: null,
          );

          // Only the one without rejections should show
          expect(filtered.length, 1);
          expect(filtered[0]['title'], 'No Rejections');
        });
      });

      group('indexer filter', () {
        test('shows all indexers when selectedIndexer is null', () {
          final filtered = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: null,
          );

          expect(filtered.length, 4);
        });

        test('filters to specific indexer', () {
          final filtered = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: 'Indexer1',
          );

          expect(filtered.length, 3);
          expect(filtered.every((r) => r['indexer'] == 'Indexer1'), isTrue);
        });

        test('returns empty when indexer not found', () {
          final filtered = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: 'NonExistentIndexer',
          );

          expect(filtered, isEmpty);
        });

        test('handles null indexer field', () {
          final releases = [
            {'title': 'No Indexer', 'indexer': null, 'rejections': []},
            {'title': 'Has Indexer', 'indexer': 'Indexer1', 'rejections': []},
          ];

          final filtered = filterAndSortReleases(
            releases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: false,
            selectedIndexer: 'Indexer1',
          );

          expect(filtered.length, 1);
          expect(filtered[0]['title'], 'Has Indexer');
        });
      });

      group('combined filters', () {
        test('applies both hideRejected and indexer filter', () {
          final filtered = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: true,
            selectedIndexer: 'Indexer1',
          );

          // Only approved releases from Indexer1
          expect(filtered.length, 2);
          expect(
            filtered.every(
              (r) =>
                  r['indexer'] == 'Indexer1' &&
                  (r['rejections'] as List).isEmpty,
            ),
            isTrue,
          );
        });

        test('filters are applied before sorting', () {
          final filtered = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: true,
            selectedIndexer: null,
          );

          // Should have 2 approved releases, sorted by score desc
          expect(filtered.length, 2);
          expect(filtered[0]['title'], 'Approved Release'); // 100
          expect(filtered[1]['title'], 'Another Approved'); // 75
        });

        test('returns empty when all filtered out', () {
          final filtered = filterAndSortReleases(
            testReleases,
            sortType: ReleaseSortType.score,
            sortAscending: false,
            hideRejected: true,
            selectedIndexer: 'Indexer2',
          );

          // Indexer2 only has rejected releases
          expect(filtered, isEmpty);
        });
      });
    });

    // Available indexers extraction tests
    group('available indexers extraction', () {
      test('extracts unique indexer names', () {
        final releases = [
          {'indexer': 'Indexer1'},
          {'indexer': 'Indexer2'},
          {'indexer': 'Indexer1'},
          {'indexer': 'Indexer3'},
        ];

        final indexers = extractAvailableIndexers(releases);

        expect(indexers, {'Indexer1', 'Indexer2', 'Indexer3'});
      });

      test('handles missing indexer field - returns Unknown', () {
        final releases = [
          {'title': 'No Indexer'},
          {'indexer': 'Indexer1'},
        ];

        final indexers = extractAvailableIndexers(releases);

        expect(indexers, {'Unknown', 'Indexer1'});
      });

      test('handles null indexer value - returns Unknown', () {
        final releases = [
          {'indexer': null},
          {'indexer': 'Indexer1'},
        ];

        final indexers = extractAvailableIndexers(releases);

        expect(indexers, {'Unknown', 'Indexer1'});
      });

      test('returns empty set for no releases', () {
        final indexers = extractAvailableIndexers([]);

        expect(indexers, isEmpty);
      });

      test('returns single indexer for single release', () {
        final releases = [
          {'indexer': 'OnlyIndexer'},
        ];

        final indexers = extractAvailableIndexers(releases);

        expect(indexers, {'OnlyIndexer'});
      });
    });
  });

  // Run additional test groups
  ReleaseSortTypeTest.runTests();
}

// Test class for ReleaseSortType enum
class ReleaseSortTypeTest {
  static void runTests() {
    group('ReleaseSortType enum', () {
      test('has correct number of values', () {
        expect(ReleaseSortType.values.length, 4);
      });

      test('has correct labels', () {
        expect(ReleaseSortType.score.label, 'CF Score');
        expect(ReleaseSortType.size.label, 'Size');
        expect(ReleaseSortType.seeders.label, 'Seeders');
        expect(ReleaseSortType.age.label, 'Age');
      });
    });
  }
}
