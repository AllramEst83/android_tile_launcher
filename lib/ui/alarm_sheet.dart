import 'dart:math' as math;

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/services/alarm_service.dart';
import 'package:android_tile_launcher/ui/alarm_pad.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/timer_pad.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key alarmTabTimerKey = ValueKey<String>('alarm-tab-timer');
const Key alarmTabAlarmKey = ValueKey<String>('alarm-tab-alarm');
const Key alarmCloseKey = ValueKey<String>('alarm-close');

DateTime _systemNow() => DateTime.now();

/// What a tap on the alarm tile opens: a sheet with a timer and an alarm, a
/// tab each, and a close key. Both are set through the phone's own clock app,
/// which does the ringing; nothing is set until START or SET ALARM is tapped.
Future<void> showAlarmSheet(
  BuildContext context, {
  required AlarmService alarm,
  bool alarmTab = false,
  DateTime Function() clock = _systemNow,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    // Laid out below the status bar.
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      final MediaQueryData media = MediaQuery.of(sheetContext);
      return SizedBox(
        height: math.min(
          media.size.height * 0.92,
          media.size.height - media.padding.top - TileMetrics.margin,
        ),
        child: _AlarmSheet(alarm: alarm, alarmTab: alarmTab, clock: clock),
      );
    },
  );
}

class _AlarmSheet extends StatefulWidget {
  const _AlarmSheet({
    required this.alarm,
    required this.alarmTab,
    required this.clock,
  });

  final AlarmService alarm;
  final bool alarmTab;
  final DateTime Function() clock;

  @override
  State<_AlarmSheet> createState() => _AlarmSheetState();
}

class _AlarmSheetState extends State<_AlarmSheet> {
  late bool _alarm = widget.alarmTab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // So the tab row is not flush against the sheet's own top edge.
            const SizedBox(height: TileMetrics.gutter),
            Row(
              children: <Widget>[
                Expanded(
                  child: PadKey(
                    key: alarmTabTimerKey,
                    label: Messages.alarmTabTimer,
                    selected: !_alarm,
                    height: 44,
                    fontSize: 12,
                    onTap: () => setState(() => _alarm = false),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: PadKey(
                    key: alarmTabAlarmKey,
                    label: Messages.alarmTabAlarm,
                    selected: _alarm,
                    height: 44,
                    fontSize: 12,
                    onTap: () => setState(() => _alarm = true),
                  ),
                ),
                const SizedBox(width: TileMetrics.gutter),
                SizedBox(
                  width: 48,
                  child: PadKey(
                    key: alarmCloseKey,
                    label: 'X',
                    height: 44,
                    fontSize: 12,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TileMetrics.gutter),
            Expanded(
              child: SingleChildScrollView(
                // Both pads stay built, so switching tabs keeps what was keyed.
                child: IndexedStack(
                  index: _alarm ? 1 : 0,
                  children: <Widget>[
                    TimerPad(alarm: widget.alarm),
                    AlarmPad(alarm: widget.alarm, clock: widget.clock),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
