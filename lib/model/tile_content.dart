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
