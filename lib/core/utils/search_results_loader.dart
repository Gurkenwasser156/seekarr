Future<List<T>?> loadNullableSearchResults<T>({
  required String query,
  required Future<List<T>> Function(String query) lookup,
}) async {
  if (query.isEmpty) {
    return null;
  }

  try {
    return await lookup(query);
  } catch (_) {
    return [];
  }
}
