class UrlUtils {
  /// Constructs an authenticated URL for accessing images or other resources.
  /// Handles correct slash joining and query parameter attachment.
  static String buildAuthenticatedUrl(
    String baseUrl,
    String path,
    String apiKey,
  ) {
    if (baseUrl.isEmpty || path.isEmpty) return '';

    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBaseUrl$cleanPath?apikey=$apiKey';
  }
}
