import 'dart:async';

import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/model/weather_snapshot.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/agenda_tile_source.dart';
import 'package:android_tile_launcher/services/clock_tile_source.dart';
import 'package:android_tile_launcher/services/device_tile_source.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/services/mail_tile_source.dart';
import 'package:android_tile_launcher/services/sound_mode_tile_source.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
import 'package:android_tile_launcher/services/text_tv_repository.dart';
import 'package:android_tile_launcher/services/text_tv_tile_source.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/services/toggle_tile_source.dart';
import 'package:android_tile_launcher/services/weather_repository.dart';
import 'package:android_tile_launcher/services/weather_tile_source.dart';
import 'package:android_tile_launcher/ui/agenda_sheet.dart';
import 'package:android_tile_launcher/ui/agenda_tile_view.dart';
import 'package:android_tile_launcher/ui/alarm_sheet.dart';
import 'package:android_tile_launcher/ui/alarm_tile_view.dart';
import 'package:android_tile_launcher/ui/calc_sheet.dart';
import 'package:android_tile_launcher/ui/calc_tile_view.dart';
import 'package:android_tile_launcher/ui/clock_tile_view.dart';
import 'package:android_tile_launcher/ui/contact_sheet.dart';
import 'package:android_tile_launcher/ui/device_tile_view.dart';
import 'package:android_tile_launcher/ui/haptics.dart';
import 'package:android_tile_launcher/ui/mail_setup_sheet.dart';
import 'package:android_tile_launcher/ui/mail_sheet.dart';
import 'package:android_tile_launcher/ui/mail_tile_view.dart';
import 'package:android_tile_launcher/ui/state_tile_view.dart';
import 'package:android_tile_launcher/ui/text_tv_screen.dart';
import 'package:android_tile_launcher/ui/text_tv_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_poller.dart';
import 'package:android_tile_launcher/ui/weather_tile_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The chrome every tile shares regardless of kind: a flat VIC-II fill with a
/// 2px light-top-left/dark-bottom-right bevel (never a shadow or gradient),
/// or — in the grid editor — a bright outline if [selected] and a delete
/// badge if [onDelete] is given. [content] draws whatever the tile's kind
/// wants inside that frame; see [tileContent].
///
/// While a finger is on it the bevel flips (dark top-left, light bottom-right)
/// and the content moves down-right by the bevel's width, so the tile reads as
/// a key being pushed in. A tap ticks, a long-press thuds (unless haptics are
/// off in settings). The press is read from the raw pointer, not the tap
/// recogniser, so a tile whose content takes the tap itself (a toggle) still
/// sinks; it lets go once the finger has slid past touch slop, i.e. when it is
/// scrolling instead.
class TileView extends StatefulWidget {
  const TileView({
    super.key,
    required this.colour,
    required this.content,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
    this.onDelete,
    this.deleteKey,
  });

  final C64Colour colour;
  final Widget content;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final VoidCallback? onDelete;

  /// Key for the delete badge, so a test can target one tile's badge among
  /// several. Only meaningful when [onDelete] is given.
  final Key? deleteKey;

  /// How long the bevel takes to flip.
  static const Duration pressDuration = Duration(milliseconds: 60);

  @override
  State<TileView> createState() => _TileViewState();
}

class _TileViewState extends State<TileView> {
  bool _pressed = false;
  Offset _down = Offset.zero;

  /// Runs out when the finger has been down long enough to be a long-press,
  /// after which its release is not a tap.
  Timer? _longPressTimer;
  bool _longHeld = false;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    // A dragged tile is taken out of the tree while its pointer is still
    // down, so the release can arrive after dispose.
    if (!mounted || _pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  void _onDown(PointerDownEvent event) {
    _down = event.position;
    _longHeld = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(kLongPressTimeout, () => _longHeld = true);
    _setPressed(true);
  }

  void _onMove(PointerMoveEvent event) {
    if ((event.position - _down).distance > kTouchSlop) _setPressed(false);
  }

  void _onUp(PointerUpEvent event) {
    final bool tapped = _pressed && !_longHeld && widget.onTap != null;
    _longPressTimer?.cancel();
    _setPressed(false);
    if (tapped && mounted) haptic(context, Haptic.tap);
  }

  void _onLongPress() {
    haptic(context, Haptic.press);
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Color fill = widget.colour.fill;
    final Color light = Color.lerp(fill, C64.white, 0.35)!;
    final Color dark = Color.lerp(fill, C64.black, 0.35)!;
    final bool sunk = _pressed && !widget.selected;
    final Color topLeft = sunk ? dark : light;
    final Color bottomRight = sunk ? light : dark;
    const double inset = TileMetrics.gutter / 2;
    final double shift = sunk ? TileMetrics.bevel : 0;

    return Listener(
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: (_) {
        _longPressTimer?.cancel();
        _setPressed(false);
      },
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress == null ? null : _onLongPress,
        // Ours, below: the built-in feedback would buzz even with haptics off
        // and twice on a long-press.
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: TileView.pressDuration,
          decoration: BoxDecoration(
            color: fill,
            border: widget.selected
                ? Border.all(
                    color: TileColors.textBright,
                    width: TileMetrics.bevel * 2,
                  )
                : Border(
                    top: BorderSide(color: topLeft, width: TileMetrics.bevel),
                    left: BorderSide(color: topLeft, width: TileMetrics.bevel),
                    right: BorderSide(
                      color: bottomRight,
                      width: TileMetrics.bevel,
                    ),
                    bottom: BorderSide(
                      color: bottomRight,
                      width: TileMetrics.bevel,
                    ),
                  ),
          ),
          padding: EdgeInsets.fromLTRB(
            inset + shift,
            inset + shift,
            inset - shift,
            inset - shift,
          ),
          child: Stack(
            children: <Widget>[
              widget.content,
              if (widget.onDelete != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _DeleteBadge(
                    key: widget.deleteKey,
                    onTap: widget.onDelete!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What goes inside [TileView] for [tile], dispatched by kind — the one
/// place a new tile kind's view gets wired in (see "Adding a tile kind" in
/// .agents/architecture.md). [labelFor] only matters for [TileKind.app].
/// [services] backs every live kind that reads from the platform; [interactive]
/// turns tap-to-toggle off in the grid editor, where a tap selects the tile
/// instead.
Widget tileContent(
  Tile tile, {
  required String Function(Tile tile) labelFor,
  required TileServices services,
  bool interactive = true,
}) {
  final SystemControlService systemControl = services.systemControl;
  switch (tile.kind) {
    case TileKind.app:
      return AppTileContent(label: labelFor(tile), ink: tile.colour.ink);
    case TileKind.clock:
      return TilePoller(
        source: const ClockTileSource(),
        interval: const Duration(seconds: 30),
        builder: (context, content, refreshNow) => ClockTileContentView(
          content: content as ClockContent,
          ink: tile.colour.ink,
        ),
      );
    case TileKind.device:
      return TilePoller(
        source: DeviceTileSource(repository: services.device),
        interval: const Duration(seconds: 60),
        builder: (context, content, refreshNow) => DeviceTileContentView(
          status: (content as DeviceContent).status,
          ink: tile.colour.ink,
        ),
      );
    case TileKind.weather:
      final WeatherRepository weather = services.weather;
      return TilePoller(
        source: WeatherTileSource(repository: weather),
        interval: const Duration(minutes: 15),
        builder: (context, content, refreshNow) {
          final WeatherSnapshot snapshot = (content as WeatherContent).snapshot;
          return WeatherTileContentView(
            snapshot: snapshot,
            ink: tile.colour.ink,
            onTap: interactive
                ? () => unawaited(
                    _act(() => _weatherTap(weather, snapshot), refreshNow),
                  )
                : null,
          );
        },
      );
    case TileKind.agenda:
      final AgendaRepository agenda = services.agenda;
      return TilePoller(
        source: AgendaTileSource(repository: agenda),
        interval: const Duration(minutes: 1),
        builder: (context, content, refreshNow) {
          final AgendaContent agendaContent = content as AgendaContent;
          return AgendaTileContentView(
            snapshot: agendaContent.snapshot,
            now: agendaContent.now,
            ink: tile.colour.ink,
            onTap: interactive
                ? () => _agendaTap(
                    context,
                    agenda,
                    agendaContent.snapshot,
                    refreshNow,
                  )
                : null,
          );
        },
      );
    case TileKind.contact:
      final Widget person = AppTileContent(
        label: labelFor(tile),
        ink: tile.colour.ink,
      );
      final String? key = contactKeyOf(tile);
      if (!interactive || key == null) return person;
      // Opens the person's sheet; nothing is dialled or sent by this tap.
      return Builder(
        builder: (context) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(
            showContactSheet(
              context,
              services: services,
              contactKey: key,
              name: labelFor(tile),
            ),
          ),
          child: SizedBox.expand(child: person),
        ),
      );
    case TileKind.mail:
      final MailService mail = services.mail;
      return TilePoller(
        source: MailTileSource(service: mail),
        // The service keeps a listing for a few minutes, so coming back to the
        // launcher between polls costs no login.
        interval: const Duration(minutes: 5),
        builder: (context, content, refreshNow) {
          final MailContent mailContent = content as MailContent;
          return MailTileContentView(
            result: mailContent.result,
            ink: tile.colour.ink,
            onTap: interactive
                ? () => unawaited(
                    _mailTap(context, mail, mailContent.result, refreshNow),
                  )
                : null,
          );
        },
      );
    case TileKind.textTv:
      final TextTvRepository textTv = services.textTv;
      return TilePoller(
        source: TextTvTileSource(repository: textTv),
        interval: const Duration(minutes: 10),
        builder: (context, content, refreshNow) => TextTvTileContentView(
          result: (content as TextTvContent).result,
          ink: tile.colour.ink,
          // Opens the viewer over the whole screen; when it is closed the tile
          // reads again, so its headlines match what was just read.
          onTap: interactive
              ? () => unawaited(
                  showTextTv(
                    context,
                    repository: textTv,
                  ).then((_) => refreshNow()),
                )
              : null,
        ),
      );
    case TileKind.calc:
      // Nothing to read from outside, so no poller: it opens the calculator
      // and converter, and that is all it does.
      return Builder(
        builder: (context) => CalcTileContentView(
          ink: tile.colour.ink,
          onTap: interactive
              ? () => unawaited(showCalcSheet(context, rates: services.rates))
              : null,
        ),
      );
    case TileKind.alarm:
      // Nothing to read from outside (the clock app owns the timers and
      // alarms), so no poller: it opens the sheet that sets them.
      return Builder(
        builder: (context) => AlarmTileContentView(
          ink: tile.colour.ink,
          onTap: interactive
              ? () => unawaited(showAlarmSheet(context, alarm: services.alarm))
              : null,
        ),
      );
    case TileKind.soundMode:
      return TilePoller(
        source: SoundModeTileSource(control: systemControl),
        interval: const Duration(seconds: 5),
        builder: (context, content, refreshNow) {
          final SoundMode mode = (content as SoundContent).mode;
          return StateTileContentView(
            label: displayNameOf(tile.kind),
            state: mode.label,
            ink: tile.colour.ink,
            onTap: interactive
                ? () => unawaited(
                    _act(
                      () => systemControl.setSoundMode(mode.next),
                      refreshNow,
                    ),
                  )
                : null,
          );
        },
      );
    case TileKind.flashlight:
      return TilePoller(
        source: ToggleTileSource(kind: tile.kind, control: systemControl),
        interval: const Duration(seconds: 5),
        builder: (context, content, refreshNow) {
          final bool on = (content as ToggleContent).on;
          return StateTileContentView(
            label: displayNameOf(tile.kind),
            state: on ? '[ON]' : '[OFF]',
            ink: tile.colour.ink,
            onTap: interactive
                ? () => unawaited(
                    _act(() => systemControl.setOn(tile.kind, !on), refreshNow),
                  )
                : null,
          );
        },
      );
  }
}

/// Runs a state-changing [action], then re-reads the tile so it shows the
/// result at once instead of at the next poll — and again shortly after,
/// because the platform applies some changes (ringer mode, torch) just after
/// the call returns, and a stale first read would show the old state (and
/// invite a second tap based on it) until the next poll.
Future<void> _act(
  Future<void> Function() action,
  VoidCallback refreshNow,
) async {
  await action();
  refreshNow();
  await Future<void>.delayed(const Duration(milliseconds: 400));
  refreshNow();
}

/// What a tap on the weather tile does: ask for the phone's location when
/// there is no place (or it was refused, and Android will still ask), else
/// fetch afresh. Nothing when Android has stopped asking — the tile says where
/// the setting is.
Future<void> _weatherTap(WeatherRepository weather, WeatherSnapshot snapshot) {
  return switch (snapshot) {
    WeatherLocationDenied(permanent: true) => Future<void>.value(),
    WeatherNeedsPlace() ||
    WeatherLocationDenied() ||
    WeatherLocationUnavailable() => weather.locate(),
    WeatherReady() || WeatherOffline() => weather.current(force: true),
  };
}

/// What a tap on the agenda tile does: open the day and week when there are
/// events to show; otherwise fix what is in the way (ask for the calendar, or
/// read it again). Nothing when Android has stopped asking — the tile says
/// where the setting is.
void _agendaTap(
  BuildContext context,
  AgendaRepository agenda,
  AgendaSnapshot snapshot,
  VoidCallback refreshNow,
) {
  switch (snapshot) {
    case AgendaReady():
      unawaited(showAgendaSheet(context, repository: agenda));
    case AgendaDenied(permanent: true):
      break;
    case AgendaNeedsPermission() || AgendaDenied():
      unawaited(_act(agenda.allow, refreshNow));
    case AgendaUnavailable():
      refreshNow();
  }
}

/// What a tap on the mail tile does: set mail up when there is no account,
/// open the inbox when there is one, read again when the last read failed.
/// The tile reads again once a sheet closes, since either may have changed it.
Future<void> _mailTap(
  BuildContext context,
  MailService mail,
  MailResult result,
  VoidCallback refreshNow,
) async {
  switch (result) {
    case MailNotSetUp():
      await showMailSetupSheet(context, mail: mail);
    case MailMessages():
      await showMailSheet(context, mail: mail);
    case MailUnavailable():
      // A saved account that cannot be read (its key is gone) never will be:
      // set it up again. Anything else is worth another try.
      if (await mail.account() == null && context.mounted) {
        await showMailSetupSheet(context, mail: mail);
      }
  }
  refreshNow();
}

/// An app tile's content: a monochrome glyph — its label's first letter,
/// since no real app icons are drawn yet (plan.md, "Not implemented") — and
/// the label itself along the bottom edge.
class AppTileContent extends StatelessWidget {
  const AppTileContent({super.key, required this.label, required this.ink});

  final String label;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final String glyph = label.isEmpty ? '?' : label[0].toUpperCase();
    return Stack(
      children: <Widget>[
        Center(
          child: FittedBox(
            child: Text(
              glyph,
              style: TextStyle(fontFamily: kPixelFontFamily, color: ink),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: kPixelFontFamily,
              fontSize: 8,
              color: ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DeleteBadge extends StatelessWidget {
  const _DeleteBadge({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        color: C64.black,
        child: const Text(
          'X',
          style: TextStyle(
            fontFamily: kPixelFontFamily,
            fontSize: 8,
            color: C64.white,
          ),
        ),
      ),
    );
  }
}
