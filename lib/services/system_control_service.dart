import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/tile.dart';

/// Device-wide controls the system tiles read and change: the ringer
/// ([soundMode]) and the two-state kinds ([isOn]/[setOn]): the torch and
/// locking the screen's orientation.
///
/// Do Not Disturb is deliberately not controlled: Android couples it to the
/// ringer (an app's request for silent turns DND on), and the tile is meant
/// to mirror the volume rocker's normal/vibrate/silent.
///
/// Entering or leaving silent needs Android's notification-policy access, and
/// locking or unlocking the orientation needs `WRITE_SETTINGS` — both special
/// permissions granted only through Settings (never a runtime dialog), so the
/// Android implementation opens the right Settings screen instead of silently
/// failing when one isn't granted yet.
abstract interface class SystemControlService {
  /// The ringer mode right now. Queried fresh every call — it changes
  /// outside the app (volume rocker).
  Future<SoundMode> soundMode();

  /// Moves the ringer to [mode], reaching silent the way the volume rocker
  /// does so the system shows its own silent state.
  Future<void> setSoundMode(SoundMode mode);

  /// Whether the two-state [kind] ([TileKind.flashlight],
  /// [TileKind.orientationLock]) is on. Queried fresh every call — for
  /// [TileKind.orientationLock] this reflects Android's own auto-rotate
  /// setting, which can change outside the app (the quick-settings tile).
  Future<bool> isOn(TileKind kind);

  Future<void> setOn(TileKind kind, bool on);
}
