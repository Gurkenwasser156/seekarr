/// Translates a grab-release error into a user-friendly message.
String translateGrabError(Object error) {
  final errorString = error.toString();
  final normalizedError = errorString.toLowerCase();
  final statusCode = RegExp(r'(\d{3})').firstMatch(errorString)?.group(1);

  if (normalizedError.contains('504') ||
      normalizedError.contains('gateway timeout')) {
    return 'Indexer timeout - the indexer took too long to respond. (Error 504)';
  }

  if (normalizedError.contains('500') ||
      normalizedError.contains('server error')) {
    return 'This release may already be downloading or available. Check your download queue.${statusCode != null ? ' (Error $statusCode)' : ''}';
  }

  if (normalizedError.contains('already')) {
    return 'This item is already in your library or download queue.';
  }

  if (normalizedError.contains('disk space') ||
      normalizedError.contains('space')) {
    return 'Not enough disk space for this download.';
  }

  if (normalizedError.contains('timeout')) {
    return 'Request timed out. Please try again.${statusCode != null ? ' (Error $statusCode)' : ''}';
  }

  return 'Failed to grab release${statusCode != null ? ' (Error $statusCode)' : ''}: ${errorString.split(':').last.trim()}';
}
