import 'dart:async';

import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/ready_script.dart';
import 'package:android_tile_launcher/model/todo_item.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/services/todo_list.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key readyCloseKey = ValueKey<String>('ready-close');
const Key readyTextKey = ValueKey<String>('ready-text');
const Key readyBorderKey = ValueKey<String>('ready-border');

DateTime _systemNow() => DateTime.now();

/// Runs the day's summary over the whole screen like a Commodore 64 loading a
/// program: `LOAD "TODAY",8` is typed, the border flashes while it "loads",
/// and then the date, the next events, the open to-dos and the unread mail
/// are printed. A tap skips the typing; the close key (or back) leaves.
Future<void> showReadyScreen(
  BuildContext context, {
  required AgendaRepository agenda,
  required TodoList todos,
  required MailService mail,
  DateTime Function() clock = _systemNow,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext context) =>
          ReadyScreen(agenda: agenda, todos: todos, mail: mail, clock: clock),
    ),
  );
}

class ReadyScreen extends StatefulWidget {
  const ReadyScreen({
    super.key,
    required this.agenda,
    required this.todos,
    required this.mail,
    this.clock = _systemNow,
    this.tick = const Duration(milliseconds: 30),
  });

  final AgendaRepository agenda;
  final TodoList todos;
  final MailService mail;
  final DateTime Function() clock;

  /// One step of the typing and of the border's flashing.
  final Duration tick;

  @override
  State<ReadyScreen> createState() => _ReadyScreenState();
}

enum _Phase { intro, loading, body, done }

class _ReadyScreenState extends State<ReadyScreen> {
  /// How many ticks the border flashes for, and how long a typed line rests
  /// before the next one starts.
  static const int _loadingTicks = 24;
  static const int _lineRest = 8;

  final ScrollController _scroll = ScrollController();
  Timer? _timer;

  ReadyScript? _script;
  _Phase _phase = _Phase.intro;

  /// What is on screen: whole lines, and the line being typed so far.
  final List<String> _shown = <String>[];
  int _line = 0;

  /// How many lines were on screen before the line being typed's run began.
  int _base = 0;
  int _char = 0;
  int _rest = 0;
  int _loadingLeft = _loadingTicks;
  bool _cursorOn = true;
  int _borderStep = 0;

  /// The intro is typed before the data is in, so it needs a script of its own.
  late final List<String> _intro = readyScript(
    now: widget.clock(),
    events: const <CalendarEvent>[],
    todos: const <TodoItem>[],
  ).intro;

  @override
  void initState() {
    super.initState();
    unawaited(_gather());
    _timer = Timer.periodic(widget.tick, (_) => _step());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _gather() async {
    final DateTime now = widget.clock();
    final AgendaSnapshot agenda = await widget.agenda.between(
      now,
      now.add(const Duration(days: 7)),
    );
    final MailResult mail = await widget.mail.latest(count: 1);
    if (!mounted) return;
    setState(() {
      _script = readyScript(
        now: now,
        events: agenda is AgendaReady ? agenda.events : null,
        todos: widget.todos.items,
        unread: mail is MailMessages ? mail.unread : null,
      );
    });
  }

  void _step() {
    if (!mounted) return;
    setState(() {
      _borderStep++;
      if (_borderStep % 12 == 0) _cursorOn = !_cursorOn;
      switch (_phase) {
        case _Phase.intro:
          _type(_intro, perTick: 1, next: _Phase.loading);
        case _Phase.loading:
          // Waits for the data too: the "load" is not over until it is in.
          if (_loadingLeft > 0) {
            _loadingLeft--;
          } else if (_script != null) {
            // What was typed stays on screen; the program's output follows it.
            _phase = _Phase.body;
            _base = _shown.length;
            _line = 0;
            _char = 0;
            _rest = 0;
          }
        case _Phase.body:
          _type(_script!.body, perTick: 3, next: _Phase.done);
        case _Phase.done:
          break;
      }
    });
    _followText();
  }

  /// Types [lines] [perTick] characters at a time into [_shown], resting a
  /// little between lines, and moves on to [next] after the last.
  void _type(List<String> lines, {required int perTick, required _Phase next}) {
    if (_rest > 0) {
      _rest--;
      return;
    }
    if (_line >= lines.length) {
      _phase = next;
      return;
    }
    final String line = lines[_line];
    _char = (_char + perTick).clamp(0, line.length);
    if (_shown.length <= _base + _line) _shown.add('');
    _shown[_base + _line] = line.substring(0, _char);
    if (_char >= line.length) {
      _line++;
      _char = 0;
      _rest = _phase == _Phase.intro ? _lineRest : 0;
    }
  }

  void _followText() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  /// A tap finishes the typing: straight to the whole summary once it is in.
  void _skip() {
    final ReadyScript? script = _script;
    if (script == null) return;
    setState(() {
      _phase = _Phase.done;
      _shown
        ..clear()
        ..addAll(_intro)
        ..addAll(script.body);
    });
    _followText();
  }

  /// The border cycles through the palette while "loading", then is the light
  /// blue of the real thing.
  Color get _border => _phase == _Phase.loading
      ? C64.rainbow[_borderStep % C64.rainbow.length]
      : C64.lightBlue;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontFamily: kPixelFontFamily,
      fontSize: 12,
      height: 1.6,
      color: C64.lightBlue,
    );
    final bool typing = _phase != _Phase.done || _cursorOn;
    return Scaffold(
      backgroundColor: _border,
      body: SafeArea(
        child: Container(
          key: readyBorderKey,
          margin: const EdgeInsets.all(14),
          color: C64.blue,
          child: Stack(
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _skip,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 56, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text.rich(
                      // The cursor is always there and only its colour
                      // blinks: a blank in its place has another height, and
                      // the whole text would shift with every blink.
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(text: _shown.join('\n')),
                          TextSpan(
                            text: '\u2588',
                            style: typing
                                ? null
                                : const TextStyle(color: Colors.transparent),
                          ),
                        ],
                      ),
                      key: readyTextKey,
                      style: style,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  key: readyCloseKey,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: C64.lightBlue,
                        width: TileMetrics.bevel,
                      ),
                    ),
                    child: Text('X', style: style.copyWith(height: 1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
