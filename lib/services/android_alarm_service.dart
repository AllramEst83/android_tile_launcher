import 'dart:async';

import 'package:android_tile_launcher/services/alarm_service.dart';
import 'package:flutter/services.dart';

/// [AlarmService] backed by the Kotlin `AlarmChannelHandler`, which asks the
/// phone's clock app through Android's `AlarmClock` intents. The only file that
/// knows about the channel.
class AndroidAlarmService implements AlarmService {
  const AndroidAlarmService({
    this.channel = const MethodChannel(channelName),
    this.timeout = const Duration(seconds: 10),
  });

  static const String channelName =
      'com.codedbykay.android_tile_launcher/alarm';

  final MethodChannel channel;

  /// Only guards against a reply that never comes.
  final Duration timeout;

  @override
  Future<AlarmResult> setTimer(Duration length, {String? label}) => _invoke(
    'timer',
    <String, Object?>{'seconds': length.inSeconds, 'label': label},
  );

  @override
  Future<AlarmResult> setAlarm({
    required int hour,
    required int minute,
    String? label,
    List<int> weekdays = const <int>[],
  }) => _invoke('alarm', <String, Object?>{
    'hour': hour,
    'minute': minute,
    'label': label,
    'days': weekdays,
  });

  @override
  Future<AlarmResult> showTimers() =>
      _invoke('showTimers', const <String, Object?>{});

  @override
  Future<AlarmResult> showAlarms() =>
      _invoke('showAlarms', const <String, Object?>{});

  Future<AlarmResult> _invoke(String method, Map<String, Object?> args) async {
    try {
      final bool? done = await channel
          .invokeMethod<bool>(method, args)
          .timeout(timeout);
      return done == true
          ? const AlarmDone()
          : const AlarmUnavailable('the clock app did not answer');
    } on PlatformException catch (error) {
      return AlarmUnavailable(switch (error.code) {
        'NO_PERMISSION' => 'not allowed to set alarms (check app permissions)',
        'NO_APP' => 'no clock app found',
        _ => error.message ?? 'could not reach the clock app',
      });
    } on MissingPluginException {
      return const AlarmUnavailable('alarms are not supported here');
    } on TimeoutException {
      return const AlarmUnavailable('the clock app did not answer');
    }
  }
}
