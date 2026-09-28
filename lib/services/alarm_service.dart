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
/// hand and appears in the app the user already knows; this only sets them
/// (and opens their lists), it does not read or cancel them. Only ever called
/// from an explicit tap on START or SET.
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
}
