String formatShortLocalDateTime(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${formatTime(dateTime)}';
}

String formatShortDateTime(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month} ${formatTime(dateTime)}';
}

String formatTime(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final period = dateTime.hour < 12 ? 'AM' : 'PM';
  return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
}

/// Formats a duration given in seconds as a human-readable string.
///   < 1 min  → "45s"
///   < 1 hour → "18m 30s"
///   >= 1 hour → "1h 18m"
String formatDurationSeconds(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h == 0) {
    final s = seconds % 60;
    return s > 0 ? '${m}m ${s}s' : '${m}m';
  }
  return m > 0 ? '${h}h ${m}m' : '${h}h';
}