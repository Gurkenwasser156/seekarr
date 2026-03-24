class UrlUtils {
  /// Constructs a URL for accessing images or other resources.
  /// Handles correct slash joining. API key authentication is handled via
  /// HTTP headers, not query parameters.
  static String buildUrl(String baseUrl, String path) {
    if (baseUrl.isEmpty || path.isEmpty) return '';

    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBaseUrl$cleanPath';
  }
}
