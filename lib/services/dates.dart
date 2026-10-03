/// Local ISO day key "YYYY-MM-DD" for a DateTime.
String isoDay(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String isoFromParts(int y, int m1to12, int day) {
  return '$y-${m1to12.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

int daysInMonth(int y, int m1to12) {
  return DateTime(y, m1to12 + 1, 0).day;
}

/// The ISO day key for `offset` days before today (offset 0 = today).
String isoDaysAgo(int offset) {
  final d = DateTime.now().subtract(Duration(days: offset));
  return isoDay(d);
}

/// Seed a realistic set of "bloom" days ending yesterday, so the calendar
/// never shows a wake in the future.
Set<String> seedBloomDays({int back = 40}) {
  final set = <String>{};
  for (var offset = 1; offset <= back; offset++) {
    if (offset > 13 && offset % 6 == 0) continue;
    set.add(isoDaysAgo(offset));
  }
  return set;
}
