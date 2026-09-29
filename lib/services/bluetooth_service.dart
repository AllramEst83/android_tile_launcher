import 'package:android_tile_launcher/model/bluetooth_status.dart';

/// Bluetooth, read and — as far as a third-party app is actually allowed to
/// — changed.
///
/// Two things Android has never let an ordinary app do, and this does not
/// try to work around: silently turn the radio on or off (`BluetoothAdapter
/// .enable`/`.disable` were removed for apps targeting Android 13+; only the
/// user, from Android's own UI, can now), and connect or disconnect a paired
/// device (`BluetoothProfile.connect`/`.disconnect` are restricted to system
/// apps — this app can only *read* a profile's connection state, which is
/// public). So both actions hand off to Android's own screens rather than
/// pretending to do them here: [openPanel] turns it on through a quick
/// system confirm dialog when it's off (there is no equivalent "turn off"
/// dialog, so this opens the full settings screen instead when it's already
/// on), [openSettings] always opens that full screen, where a paired device
/// is actually connected, disconnected or forgotten.
abstract interface class BluetoothService {
  /// The adapter's state and, when it is on, every paired device. Never
  /// throws.
  Future<BluetoothStatus> status();

  /// Asks for the runtime permission [status] needs to read paired devices
  /// (Android 12+'s `BLUETOOTH_CONNECT`; older Android grants it at install,
  /// so this returns at once there).
  Future<void> allow();

  /// Turns Bluetooth on through Android's own quick confirm dialog when it's
  /// off; when it's already on, opens the full settings screen instead
  /// ([openSettings]), since Android has no equivalent quick dialog for
  /// turning it off.
  Future<void> openPanel();

  /// Opens Android's own Bluetooth settings screen, where a paired device is
  /// actually connected, disconnected or forgotten.
  Future<void> openSettings();
}
