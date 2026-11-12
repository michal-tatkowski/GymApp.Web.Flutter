// Time and distance of timed / cardio sets (API: seconds and metres).

/// "45 s", "1:30", "1:02:03".
String formatDuration(int seconds) {
  if (seconds < 60) return '$seconds s';
  final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// "800 m", "5.2 km" (comma in Polish — [decimalSeparator]).
String formatDistance(double meters, {String decimalSeparator = '.'}) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  final text = km >= 100 ? km.round().toString() : (km * 10).round() % 10 == 0 ? km.round().toString() : km.toStringAsFixed(1);
  return '${text.replaceAll('.', decimalSeparator)} km';
}

/// Pace of a run: minutes per km, "5:12 /km"; null when it can't be computed.
String? formatPace(int seconds, double meters) {
  if (seconds <= 0 || meters < 100) return null;
  final perKm = (seconds / (meters / 1000)).round();
  return '${formatDuration(perKm < 60 ? 60 : perKm)} /km';
}

/// Reads "1:30", "90", "1:02:03" or "45 s" as seconds; null when invalid.
int? parseDuration(String text) {
  final t = text.trim().replaceAll(RegExp(r'\s*s$'), '');
  if (t.isEmpty) return null;
  final parts = t.split(':');
  if (parts.length > 3 || parts.any((p) => int.tryParse(p) == null)) return null;
  return parts.map(int.parse).fold<int>(0, (total, p) => total * 60 + p);
}
