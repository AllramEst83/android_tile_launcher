import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/clock_input.dart';
import 'package:android_tile_launcher/model/timer_entry.dart';
import 'package:android_tile_launcher/services/alarm_service.dart';
import 'package:android_tile_launcher/ui/digit_pad.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const String timerPadPrefix = 'timer';
const Key timerDisplayKey = ValueKey<String>('timer-display');
const Key timerStartKey = ValueKey<String>('timer-start');
const Key timerSeeKey = ValueKey<String>('timer-see');
const Key timerStatusKey = ValueKey<String>('timer-status');
Key timerPresetKey(int minutes) => ValueKey<String>('timer-preset-$minutes');

/// The lengths one tap away, in minutes.
const List<(int, String)> timerPresets = <(int, String)>[
  (1, '1 MIN'),
  (5, '5 MIN'),
  (10, '10 MIN'),
  (15, '15 MIN'),
  (30, '30 MIN'),
  (60, '1 H'),
];

/// The timer: a length keyed like a microwave's (or chosen from the presets),
/// and START, which hands the timer to the phone's clock app to run. Nothing is
/// started until START is tapped.
class TimerPad extends StatefulWidget {
  const TimerPad({super.key, required this.alarm});

  final AlarmService alarm;

  @override
  State<TimerPad> createState() => _TimerPadState();
}

class _TimerPadState extends State<TimerPad> {
  TimerEntry _entry = const TimerEntry();
  bool _busy = false;
  String? _status;

  void _change(TimerEntry entry) => setState(() {
    _entry = entry;
    _status = null;
  });

  Future<void> _start() async {
    if (!_entry.canStart || _busy) return;
    final Duration length = _entry.length;
    setState(() => _busy = true);
    final AlarmResult result = await widget.alarm.setTimer(length);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = switch (result) {
        AlarmDone() => Messages.alarmTimerSet(
          formatDuration(length).toUpperCase(),
        ),
        AlarmUnavailable(:final String reason) =>
          '${Messages.failedPrefix}${reason.toUpperCase()}',
      };
    });
  }

  Future<void> _see() async {
    final AlarmResult result = await widget.alarm.showTimers();
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
    final String? status = _status;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(vertical: TileMetrics.margin),
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _entry.display,
              key: timerDisplayKey,
              style: TextStyle(
                fontFamily: kPixelFontFamily,
                fontSize: 32,
                color: _entry.digits.isEmpty
                    ? TileColors.textDim
                    : (_entry.tooLong ? C64.lightRed : TileColors.textBright),
              ),
            ),
          ),
        ),
        if (_entry.tooLong)
          const Padding(
            padding: EdgeInsets.only(bottom: TileMetrics.gutter),
            child: Text(
              Messages.alarmTooLong,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: kPixelFontFamily,
                fontSize: 8,
                color: C64.lightRed,
              ),
            ),
          ),
        SizedBox(
          height: 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final (int minutes, String label)
                    in timerPresets) ...<Widget>[
                  PadKey(
                    key: timerPresetKey(minutes),
                    label: label,
                    height: 40,
                    fontSize: 10,
                    accent: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onTap: () =>
                        _change(TimerEntry.of(Duration(minutes: minutes))),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: TileMetrics.gutter),
        DigitPad(
          keyPrefix: timerPadPrefix,
          onDigit: (int d) => _change(_entry.press(d)),
          onDelete: () => _change(_entry.backspace()),
          onClear: () => _change(_entry.clear()),
        ),
        PadRow(
          keys: <(Widget, int)>[
            (
              PadKey(
                key: timerStartKey,
                label: _busy ? Messages.calcRatesLoading : Messages.alarmStart,
                selected: _entry.canStart && !_busy,
                fontSize: 12,
                onTap: _entry.canStart && !_busy ? _start : null,
              ),
              2,
            ),
            (
              PadKey(
                key: timerSeeKey,
                label: Messages.alarmSeeTimers,
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
              key: timerStatusKey,
              style: const TextStyle(
                fontFamily: kPixelFontFamily,
                fontSize: 10,
                color: C64.cyan,
              ),
            ),
          ),
      ],
    );
  }
}
