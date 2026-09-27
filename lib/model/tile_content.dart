/// What a live tile currently shows, from its `TileSource`. An app tile has
/// none of these — its label and glyph come straight from the `AppInfo` it
/// names — so this only grows a case when a kind actually needs one.
sealed class TileContent {
  const TileContent();
}

/// The clock tile's content: already formatted, so the view never has to
/// know about `DateTime` or locale.
class ClockContent extends TileContent {
  const ClockContent({required this.time, required this.date});

  final String time;
  final String date;

  @override
  bool operator ==(Object other) =>
      other is ClockContent && other.time == time && other.date == date;

  @override
  int get hashCode => Object.hash(time, date);

  @override
  String toString() => 'ClockContent($time, $date)';
}

/// A toggle tile's content — silent mode, vibration mode, flashlight all
/// show the same shape, just one bool, so they share this one case rather
/// than each getting their own.
class ToggleContent extends TileContent {
  const ToggleContent({required this.on});

  final bool on;

  @override
  bool operator ==(Object other) => other is ToggleContent && other.on == on;

  @override
  int get hashCode => on.hashCode;

  @override
  String toString() => 'ToggleContent($on)';
}
