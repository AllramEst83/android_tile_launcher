import 'package:android_tile_launcher/model/tile.dart';

/// Device-wide toggles a system tile reads and flips: ringer mode (silent,
/// vibrate) and the torch (flashlight). Backs `ToggleTileSource` and the
/// toggle tile's own tap action.
abstract interface class SystemControlService {
  /// Whether [kind]'s toggle is on right now. Queried fresh every call —
  /// this can change outside the app (quick settings, an incoming call), so
  /// nothing here is cached.
  Future<bool> isOn(TileKind kind);

  /// Turns [kind]'s toggle on or off. Silent/vibration mode need Android's
  /// notification-policy access — a special permission granted only through
  /// Settings, never a runtime dialog — so the Android implementation opens
  /// that Settings screen instead of silently failing when it isn't granted
  /// yet.
  Future<void> setOn(TileKind kind, bool on);
}
