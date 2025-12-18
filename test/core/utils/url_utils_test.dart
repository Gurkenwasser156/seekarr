import 'package:flutter_test/flutter_test.dart';
import 'package:seekarr/core/utils/url_utils.dart';

void main() {
  group('UrlUtils', () {
    group('buildAuthenticatedUrl', () {
      test('builds correct URL with trailing slash in baseUrl', () {
        final result = UrlUtils.buildAuthenticatedUrl(
          'http://localhost:7878/',
          '/api/v3/image.jpg',
          'test-api-key',
        );
        expect(
          result,
          'http://localhost:7878/api/v3/image.jpg?apikey=test-api-key',
        );
      });

      test('builds correct URL without trailing slash in baseUrl', () {
        final result = UrlUtils.buildAuthenticatedUrl(
          'http://localhost:7878',
          '/api/v3/image.jpg',
          'test-api-key',
        );
        expect(
          result,
          'http://localhost:7878/api/v3/image.jpg?apikey=test-api-key',
        );
      });

      test('handles path without leading slash', () {
        final result = UrlUtils.buildAuthenticatedUrl(
          'http://localhost:7878',
          'api/v3/image.jpg',
          'test-api-key',
        );
        expect(
          result,
          'http://localhost:7878/api/v3/image.jpg?apikey=test-api-key',
        );
      });

      test('returns empty string when baseUrl is empty', () {
        final result = UrlUtils.buildAuthenticatedUrl(
          '',
          '/api/v3/image.jpg',
          'test-api-key',
        );
        expect(result, '');
      });

      test('returns empty string when path is empty', () {
        final result = UrlUtils.buildAuthenticatedUrl(
          'http://localhost:7878',
          '',
          'test-api-key',
        );
        expect(result, '');
      });
    });
  });
}
