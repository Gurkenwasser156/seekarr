import 'package:seekarr/core/utils/url_utils.dart';

/// Utility class for extracting and building image URLs from *arr service responses.
class ImageUtils {
  /// Extracts a poster URL from an images list returned by Radarr/Sonarr/Lidarr.
  ///
  /// The method searches for images with specified cover types and builds
  /// authenticated URLs when needed.
  ///
  /// Parameters:
  /// - [images]: List of image objects from the API response
  /// - [baseUrl]: Base URL of the *arr service (for local images)
  /// - [apiKey]: API key for authentication (for local images)
  /// - [coverTypes]: List of cover type strings to search for (default: ['poster', 'cover'])
  ///
  /// Returns the image URL or an empty string if not found.
  static String extractPosterUrl(
    List<dynamic>? images, {
    required String baseUrl,
    required String apiKey,
    List<String> coverTypes = const ['poster', 'cover'],
  }) {
    if (images == null || images.isEmpty) return '';

    // Find the first matching cover type
    dynamic coverImage;
    for (final type in coverTypes) {
      final matches = images.where((img) => img['coverType'] == type);
      if (matches.isNotEmpty) {
        coverImage = matches.first;
        break;
      }
    }

    if (coverImage == null) return '';

    final remoteUrl = coverImage['remoteUrl'] as String?;
    final localUrl = coverImage['url'] as String?;

    // Prefer remote URL if it's a full HTTP URL
    if (remoteUrl != null && remoteUrl.startsWith('http')) {
      return remoteUrl;
    }

    // Fall back to building authenticated local URL
    final path = remoteUrl ?? localUrl;
    if (path != null) {
      return UrlUtils.buildAuthenticatedUrl(baseUrl, path, apiKey);
    }

    return '';
  }

  /// Builds a TMDB poster URL from a poster path.
  ///
  /// Parameters:
  /// - [posterPath]: The poster path from TMDB (e.g., "/abc123.jpg")
  /// - [size]: Image size (default: 'w500', options: 'w92', 'w154', 'w185', 'w342', 'w500', 'w780', 'original')
  static String buildTmdbPosterUrl(String? posterPath, {String size = 'w500'}) {
    if (posterPath == null || posterPath.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/$size$posterPath';
  }
}
