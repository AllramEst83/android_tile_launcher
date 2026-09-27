import 'package:android_tile_launcher/services/app_info.dart';

/// Every app whose label matches [query], best first: exact, then prefix,
/// then substring (case-insensitive). An empty query returns no apps — the
/// drawer's search field only narrows, it isn't another way to browse
/// everything (that's the alphabetical list with an empty query).
///
/// Ported from the sibling terminal launcher's `terminal/app_matcher.dart`.
List<AppInfo> rankApps(List<AppInfo> apps, String query) {
  final String needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];

  final List<AppInfo> ranked = <AppInfo>[];
  final List<bool Function(String label)> tiers = <bool Function(String)>[
    (label) => label == needle,
    (label) => label.startsWith(needle),
    (label) => label.contains(needle),
  ];
  for (final bool Function(String label) matches in tiers) {
    for (final AppInfo app in apps) {
      if (matches(app.label.toLowerCase()) && !ranked.contains(app)) {
        ranked.add(app);
      }
    }
  }
  return ranked;
}
