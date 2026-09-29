/// One device the phone is already paired with — never one this app
/// discovers itself; see `BluetoothService`'s own note on why only paired
/// devices are shown at all.
class PairedDevice {
  const PairedDevice({
    required this.name,
    required this.address,
    required this.connected,
  });

  final String name;
  final String address;

  /// Whether any Bluetooth profile (audio, headset, ...) has this device
  /// connected right now — a public, per-profile read (`BluetoothProfile
  /// .getConnectionState`), unlike connecting or disconnecting one, which is
  /// not.
  final bool connected;

  @override
  bool operator ==(Object other) =>
      other is PairedDevice &&
      other.name == name &&
      other.address == address &&
      other.connected == connected;

  @override
  int get hashCode => Object.hash(name, address, connected);

  @override
  String toString() => 'PairedDevice($name, $address, connected: $connected)';
}

/// Bluetooth right now, from `BluetoothService.status`. Never a "connecting"
/// or "disconnecting" state: this app can only read what Android already
/// knows and hand the rest to Android's own screens (see `BluetoothService`).
sealed class BluetoothStatus {
  const BluetoothStatus();
}

/// The adapter is on. [devices] is every paired device, in no particular
/// order beyond however Android returned them.
class BluetoothOn extends BluetoothStatus {
  const BluetoothOn(this.devices);

  final List<PairedDevice> devices;

  @override
  String toString() => 'BluetoothOn($devices)';
}

/// The adapter is off. Android hides its paired devices while it is, so
/// there is nothing to list until it is back on.
class BluetoothOff extends BluetoothStatus {
  const BluetoothOff();
}

/// The phone has no Bluetooth radio at all. Genuinely rare — reserved for
/// when the platform side itself says so cleanly, never used as a catch-all
/// for a native error (see [BluetoothUnavailable], which a real crash or
/// platform exception becomes instead — conflating the two once already
/// showed a phone that plainly has Bluetooth this message, hiding a real bug
/// as if it were expected hardware absence).
class BluetoothUnsupported extends BluetoothStatus {
  const BluetoothUnsupported();
}

/// Something on the platform side actually went wrong reading Bluetooth's
/// state — a real, printable [reason], not silently reinterpreted as
/// [BluetoothUnsupported].
class BluetoothUnavailable extends BluetoothStatus {
  const BluetoothUnavailable(this.reason);

  final String reason;
}

/// `BluetoothService.allow` has not been asked yet, or was refused.
/// [permanent] is the same idea as the weather tile's own location-denied
/// flag: Android stops showing the dialog after a refusal or two, so the
/// only way back is the app's own settings page.
class BluetoothNeedsPermission extends BluetoothStatus {
  const BluetoothNeedsPermission({required this.permanent});

  final bool permanent;
}
