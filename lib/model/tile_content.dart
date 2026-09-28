import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/model/sound_mode.dart';

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

/// The sound tile's content: which of normal/vibrate/silent the ringer is in.
class SoundContent extends TileContent {
  const SoundContent({required this.mode});

  final SoundMode mode;

  @override
  bool operator ==(Object other) => other is SoundContent && other.mode == mode;

  @override
  int get hashCode => mode.hashCode;

  @override
  String toString() => 'SoundContent($mode)';
}

/// A two-state toggle tile's content — Do Not Disturb and the flashlight
/// share this one case, just one bool.
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

/// The device tile's content: battery and storage.
class DeviceContent extends TileContent {
  const DeviceContent({required this.status});

  final DeviceStatus status;

  @override
  bool operator ==(Object other) =>
      other is DeviceContent && other.status == status;

  @override
  int get hashCode => status.hashCode;

  @override
  String toString() => 'DeviceContent($status)';
}
