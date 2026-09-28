/// The phone's ringer state — what the volume rocker cycles through. Exactly
/// one at a time. Separate from Do Not Disturb, which filters alerts on top
/// of it (see `SystemControlService`).
enum SoundMode {
  normal,
  vibrate,
  silent;

  /// What one tap on the sound tile moves to: normal, vibrate, silent, back
  /// to normal.
  SoundMode get next => SoundMode.values[(index + 1) % SoundMode.values.length];

  String get label => switch (this) {
    SoundMode.normal => '[RING]',
    SoundMode.vibrate => '[VIBRATE]',
    SoundMode.silent => '[SILENT]',
  };
}
