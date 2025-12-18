import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InteractiveSearchSheet', () {
    group('_formatSize', () {
      test('formats bytes correctly', () {
        expect(_formatSize(0), '0 B');
        expect(_formatSize(512), '512 B');
        expect(_formatSize(1024), '1.0 KB');
        expect(_formatSize(1536), '1.5 KB');
        expect(_formatSize(1048576), '1.0 MB');
        expect(_formatSize(1073741824), '1.00 GB');
        expect(_formatSize(2147483648), '2.00 GB');
      });
    });

    group('_formatAge', () {
      test('formats minutes correctly', () {
        expect(_formatAge(0), '0m');
        expect(_formatAge(30), '30m');
        expect(_formatAge(60), '1h');
        expect(_formatAge(120), '2h');
        expect(_formatAge(1440), '1d');
        expect(_formatAge(2880), '2d');
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
  });
}

// Copied from InteractiveSearchSheet for testing
String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String _formatAge(int minutes) {
  if (minutes < 60) return '${minutes}m';
  if (minutes < 1440) return '${(minutes / 60).round()}h';
  return '${(minutes / 1440).round()}d';
}
