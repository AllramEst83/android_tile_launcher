import 'package:android_tile_launcher/services/alarm_service.dart';

/// Answers every request with [result] and records what was asked.
class FakeAlarmService implements AlarmService {
  AlarmResult result = const AlarmDone();

  /// Every timer length asked for, in order.
  final List<Duration> timers = <Duration>[];

  /// Every `(hour, minute, weekdays)` asked for, in order.
  final List<(int, int, List<int>)> alarms = <(int, int, List<int>)>[];

  int timerLists = 0;
  int alarmLists = 0;

  /// What [next] answers.
  DateTime? nextAlarm;

  @override
  Future<AlarmResult> setTimer(Duration length, {String? label}) async {
    timers.add(length);
    return result;
  }

  @override
  Future<AlarmResult> setAlarm({
    required int hour,
    required int minute,
    String? label,
    List<int> weekdays = const <int>[],
  }) async {
    alarms.add((hour, minute, weekdays));
    return result;
  }

  @override
  Future<AlarmResult> showTimers() async {
    timerLists++;
    return result;
  }

  @override
  Future<AlarmResult> showAlarms() async {
    alarmLists++;
    return result;
  }

  @override
  Future<DateTime?> next() async => nextAlarm;
}
