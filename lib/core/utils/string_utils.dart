/// Formats an ISO-8601 date string to `YYYY-MM-DD`.
///
/// Returns the original string if parsing fails.
String formatIsoDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return isoDate;
  }
}

/// Capitalizes the first character of [value].
///
/// Returns [value] unchanged if it is empty.
String capitalizeFirst(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
