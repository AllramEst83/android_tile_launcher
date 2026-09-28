sealed class AlarmResult {
  const AlarmResult();
}

/// The clock app took it (or opened): a timer or alarm was set, or its list is
/// on screen.
class AlarmDone extends AlarmResult {
  const AlarmDone();
}

/// The clock app could not be reached; [reason] is short and printable.
class AlarmUnavailable extends AlarmResult {
  const AlarmUnavailable(this.reason);

  final String reason;
}

/// Timers and alarms, set through the phone's own clock app. It is what rings,
/// vibrates and survives a reboot, so an alarm is as reliable as one set by
/// hand and appears in the app the user already knows; this sets them (and
/// opens their lists) and reads the next one due, but never cancels one.
/// `setTimer`/`setAlarm`/`showTimers`/`showAlarms` are only ever called from
/// an explicit tap on START or SET; [next] is polled for the alarm tile.
abstract interface class AlarmService {
  /// Starts a timer of [length] (one second to 24 hours), running at once.
  /// Never throws; every failure is an [AlarmUnavailable].
  Future<AlarmResult> setTimer(Duration length, {String? label});

  /// Sets an alarm for [hour]:[minute] (24-hour). With no [weekdays] it rings
  /// once, next time the clock reads that; otherwise on those days, as
  /// `DateTime.monday` (1) to `DateTime.sunday` (7). Never throws.
  Future<AlarmResult> setAlarm({
    required int hour,
    required int minute,
    String? label,
    List<int> weekdays = const <int>[],
  });

  /// Opens the clock app's list of timers.
  Future<AlarmResult> showTimers();

  /// Opens the clock app's list of alarms.
  Future<AlarmResult> showAlarms();

  /// When the phone will next ring an alarm, or `null` if none is set. This
  /// is Android's one system-wide "next alarm clock", set by whichever app's
  /// alarm is soonest — not only ones set from here — since the clock app,
  /// not this launcher, owns them. A timer has no equivalent to read: Android
  /// exposes only the next *alarm*. Never throws; unreadable is `null`.
  Future<DateTime?> next();
}
