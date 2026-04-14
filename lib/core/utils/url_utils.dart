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

  /// Validates a service URL for *arr and Seerr configuration.
  static String? validateServiceUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Server URL is required';
    }

    final trimmed = value.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return 'Enter a valid URL (e.g. http://192.168.1.100:7878)';
    }

    return null;
  }
}
