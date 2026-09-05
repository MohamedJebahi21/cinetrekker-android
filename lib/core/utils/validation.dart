String sanitizeSearchQuery(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= 200) return normalized;
  return normalized.substring(0, 200).trimRight();
}

bool isValidEmail(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > 254) return false;
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
}
