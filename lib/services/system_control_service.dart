import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/tile.dart';

/// Device-wide controls the system tiles read and change: the ringer
/// ([soundMode]), Do Not Disturb and the torch (the two-state [isOn]/[setOn]
/// kinds).
///
/// Ringer mode and Do Not Disturb are separate settings that Android couples:
/// while DND is on the ringer *reads* as silent whatever it was set to, and
/// leaving silent turns "alarms only"/"total silence" DND off. So
/// [setSoundMode] always clears DND first — a tap on the sound tile is an
/// explicit request for that sound, and would otherwise appear to do nothing
/// while DND masks it.
///
/// Both need Android's notification-policy access, a special permission
/// granted only through Settings (never a runtime dialog), so the Android
/// implementation opens that Settings screen instead of silently failing when
/// it isn't granted yet.
abstract interface class SystemControlService {
  /// The ringer mode right now. Queried fresh every call — it changes
  /// outside the app (volume rocker, DND).
  Future<SoundMode> soundMode();

  Future<void> setSoundMode(SoundMode mode);

  /// Whether the two-state [kind] ([TileKind.doNotDisturb] or
  /// [TileKind.flashlight]) is on. Queried fresh every call.
  Future<bool> isOn(TileKind kind);

  /// Turns [kind] on or off. Turning DND on selects "priority only", the
  /// same as the stock quick-settings tile, so the user's own DND
  /// exceptions (alarms, starred contacts) keep applying.
  Future<void> setOn(TileKind kind, bool on);
}
