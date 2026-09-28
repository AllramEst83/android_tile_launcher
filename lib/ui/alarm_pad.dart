import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/alarm_entry.dart';
import 'package:android_tile_launcher/model/clock_input.dart';
import 'package:android_tile_launcher/services/alarm_service.dart';
import 'package:android_tile_launcher/ui/digit_pad.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const String alarmPadPrefix = 'alarm';
const Key alarmDisplayKey = ValueKey<String>('alarm-display');
const Key alarmNextKey = ValueKey<String>('alarm-next');
const Key alarmSetKey = ValueKey<String>('alarm-set');
const Key alarmSeeKey = ValueKey<String>('alarm-see');
const Key alarmStatusKey = ValueKey<String>('alarm-status');
Key alarmDayKey(int day) => ValueKey<String>('alarm-day-$day');
Key alarmRepeatKey(String label) => ValueKey<String>('alarm-repeat-$label');

DateTime _systemNow() => DateTime.now();

const List<(String, List<int>)> _repeats = <(String, List<int>)>[
  (Messages.alarmOnce, <int>[]),
  (Messages.alarmWeekdays, <int>[1, 2, 3, 4, 5]),
  (Messages.alarmWeekend, <int>[6, 7]),
  (Messages.alarmDaily, <int>[1, 2, 3, 4, 5, 6, 7]),
];

/// The alarm: a time keyed like a page number (`07:30`), the days it repeats
/// on (none: it rings once), and SET ALARM, which hands the alarm to the
/// phone's clock app. Nothing is set until SET ALARM is tapped.
class AlarmPad extends StatefulWidget {
  const AlarmPad({super.key, required this.alarm, this.clock = _systemNow});

  final AlarmService alarm;

  /// What "now" is, for saying when a once-only alarm will ring.
  final DateTime Function() clock;

  @override
  State<AlarmPad> createState() => _AlarmPadState();
}

class _AlarmPadState extends State<AlarmPad> {
  AlarmEntry _entry = const AlarmEntry();
  final Set<int> _days = <int>{};
  bool _busy = false;
  String? _status;

  void _change(AlarmEntry entry) => setState(() {
    _entry = entry;
    _status = null;
  });

  void _toggleDay(int day) => setState(() {
    if (!_days.remove(day)) _days.add(day);
    _status = null;
  });

  void _setDays(List<int> days) => setState(() {
    _days
      ..clear()
      ..addAll(days);
    _status = null;
  });

  /// When the alarm as keyed will ring: `TUE 07:30` for the next time today or
  /// tomorrow, or the days it repeats on.
  String? _when() {
    final ClockTime? time = _entry.time;
    if (time == null) return null;
    final String at = clockText(time.hour, time.minute);
    if (_days.isNotEmpty) return '${describeDays(_days)} $at';
    final DateTime next = nextOccurrence(widget.clock(), time);
    final DateTime today = widget.clock();
    final bool isToday =
        next.year == today.year &&
        next.month == today.month &&
        next.day == today.day;
    return '${isToday ? 'TODAY' : 'TOMORROW'} $at';
  }

  Future<void> _set() async {
    final ClockTime? time = _entry.time;
    if (time == null || _busy) return;
    final String when = _when()!;
    setState(() => _busy = true);
    final AlarmResult result = await widget.alarm.setAlarm(
      hour: time.hour,
      minute: time.minute,
      weekdays: (_days.toList()..sort()),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = switch (result) {
        AlarmDone() => Messages.alarmAlarmSet(when),
        AlarmUnavailable(:final String reason) =>
          '${Messages.failedPrefix}${reason.toUpperCase()}',
      };
    });
  }

  Future<void> _see() async {
    final AlarmResult result = await widget.alarm.showAlarms();
    if (!mounted) return;
    if (result is AlarmUnavailable) {
      setState(
        () =>
            _status = '${Messages.failedPrefix}${result.reason.toUpperCase()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? when = _when();
    final String? status = _status;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(top: TileMetrics.margin),
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _entry.display,
              key: alarmDisplayKey,
              style: TextStyle(
                fontFamily: kPixelFontFamily,
                fontSize: 32,
                color: _entry.digits.isEmpty
                    ? TileColors.textDim
                    : TileColors.textBright,
              ),
            ),
          ),
        ),
        Container(
          height: 24,
          alignment: Alignment.centerRight,
          child: when == null
              ? null
              : Text(
                  Messages.alarmNext(when),
                  key: alarmNextKey,
                  style: TextStyle(
                    fontFamily: kPixelFontFamily,
                    fontSize: 10,
                    color: TileColors.accent,
                  ),
                ),
        ),
        const _Label(text: Messages.alarmDays),
        SizedBox(
          height: 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final int day in <int>[1, 2, 3, 4, 5, 6, 7]) ...<Widget>[
                  PadKey(
                    key: alarmDayKey(day),
                    label: dayName(day),
                    selected: _days.contains(day),
                    height: 40,
                    fontSize: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onTap: () => _toggleDay(day),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final (String label, List<int> days)
                    in _repeats) ...<Widget>[
                  PadKey(
                    key: alarmRepeatKey(label),
                    label: label,
                    accent: true,
                    height: 40,
                    fontSize: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onTap: () => _setDays(days),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: TileMetrics.gutter),
        DigitPad(
          keyPrefix: alarmPadPrefix,
          onDigit: (int d) => _change(_entry.press(d)),
          onDelete: () => _change(_entry.backspace()),
          onClear: () => _change(_entry.clear()),
        ),
        PadRow(
          keys: <(Widget, int)>[
            (
              PadKey(
                key: alarmSetKey,
                label: _busy ? Messages.calcRatesLoading : Messages.alarmSet,
                selected: _entry.complete && !_busy,
                fontSize: 12,
                onTap: _entry.complete && !_busy ? _set : null,
              ),
              2,
            ),
            (
              PadKey(
                key: alarmSeeKey,
                label: Messages.alarmSeeAlarms,
                fontSize: 8,
                accent: true,
                onTap: _see,
              ),
              1,
            ),
          ],
        ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(top: TileMetrics.gutter),
            child: Text(
              status,
              key: alarmStatusKey,
              style: TextStyle(
                fontFamily: kPixelFontFamily,
                fontSize: 10,
                color: TileColors.accent,
              ),
            ),
          ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kPixelFontFamily,
          fontSize: 8,
          color: TileColors.muted,
        ),
      ),
    );
  }
}
