import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/model/weather_snapshot.dart';

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

/// The agenda tile's content: the coming events, or the reason there are none
/// to show, and the moment they were read (what "now" and "today" mean to the
/// view, so it never asks the clock itself).
class AgendaContent extends TileContent {
  const AgendaContent({required this.snapshot, required this.now});

  final AgendaSnapshot snapshot;
  final DateTime now;

  @override
  String toString() => 'AgendaContent($snapshot, $now)';
}

/// The mail tile's content: the newest messages and the unread count, or the
/// reason there are none to show, and the moment they were read (what "today"
/// means to the view, so it never asks the clock itself).
class MailContent extends TileContent {
  const MailContent({required this.result, required this.now});

  final MailResult result;
  final DateTime now;

  @override
  String toString() => 'MailContent($result, $now)';
}

/// The Text TV tile's content: the headline page, or the reason there is none.
class TextTvContent extends TileContent {
  const TextTvContent({required this.result});

  final TextTvResult result;

  @override
  String toString() => 'TextTvContent($result)';
}

/// The weather tile's content: a forecast, or the reason there is none.
class WeatherContent extends TileContent {
  const WeatherContent({required this.snapshot});

  final WeatherSnapshot snapshot;

  @override
  String toString() => 'WeatherContent($snapshot)';
}
