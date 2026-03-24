import 'package:flutter_test/flutter_test.dart';
import 'package:seekarr/core/utils/url_utils.dart';

void main() {
  group('UrlUtils', () {
    group('buildUrl', () {
      test('builds correct URL with trailing slash in baseUrl', () {
        final result = UrlUtils.buildUrl(
          'http://localhost:7878/',
          '/api/v3/image.jpg',
        );
        expect(result, 'http://localhost:7878/api/v3/image.jpg');
      });

      test('builds correct URL without trailing slash in baseUrl', () {
        final result = UrlUtils.buildUrl(
          'http://localhost:7878',
          '/api/v3/image.jpg',
        );
        expect(result, 'http://localhost:7878/api/v3/image.jpg');
      });

      test('handles path without leading slash', () {
        final result = UrlUtils.buildUrl(
          'http://localhost:7878',
          'api/v3/image.jpg',
        );
        expect(result, 'http://localhost:7878/api/v3/image.jpg');
      });

      test('returns empty string when baseUrl is empty', () {
        final result = UrlUtils.buildUrl('', '/api/v3/image.jpg');
        expect(result, '');
      });

      test('returns empty string when path is empty', () {
        final result = UrlUtils.buildUrl('http://localhost:7878', '');
        expect(result, '');
      });
    });
  });
}
