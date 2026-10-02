import 'dart:async';

import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/media_snapshot.dart';
import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/model/weather_snapshot.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/agenda_tile_source.dart';
import 'package:android_tile_launcher/services/alarm_service.dart';
import 'package:android_tile_launcher/services/alarm_tile_source.dart';
import 'package:android_tile_launcher/services/app_repository.dart';
import 'package:android_tile_launcher/services/attachment_download_service.dart';
import 'package:android_tile_launcher/services/clock_tile_source.dart';
import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/device_tile_source.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/services/mail_tile_source.dart';
import 'package:android_tile_launcher/services/media_service.dart';
import 'package:android_tile_launcher/services/media_tile_source.dart';
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
import 'package:android_tile_launcher/ui/app_icon.dart';
import 'package:android_tile_launcher/ui/calc_sheet.dart';
import 'package:android_tile_launcher/ui/calc_tile_view.dart';
import 'package:android_tile_launcher/ui/clock_tile_view.dart';
import 'package:android_tile_launcher/ui/contact_sheet.dart';
import 'package:android_tile_launcher/ui/device_tile_view.dart';
import 'package:android_tile_launcher/ui/files_sheet.dart';
import 'package:android_tile_launcher/ui/files_tile_view.dart';
import 'package:android_tile_launcher/ui/haptics.dart';
import 'package:android_tile_launcher/ui/mail_setup_sheet.dart';
import 'package:android_tile_launcher/ui/mail_sheet.dart';
import 'package:android_tile_launcher/ui/mail_tile_view.dart';
import 'package:android_tile_launcher/ui/media_sheet.dart';
import 'package:android_tile_launcher/ui/media_tile_view.dart';
import 'package:android_tile_launcher/ui/press_listener.dart';
import 'package:android_tile_launcher/ui/qr_scanner_screen.dart';
import 'package:android_tile_launcher/ui/qr_scanner_tile_view.dart';
import 'package:android_tile_launcher/ui/scene_sheet.dart';
import 'package:android_tile_launcher/ui/scene_tile_view.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/state_tile_view.dart';
import 'package:android_tile_launcher/ui/text_tv_screen.dart';
import 'package:android_tile_launcher/ui/text_tv_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_gloss.dart';
import 'package:android_tile_launcher/ui/tile_poller.dart';
import 'package:android_tile_launcher/ui/weather_tile_view.dart';
import 'package:flutter/material.dart';

/// The chrome every tile shares regardless of kind: a flat VIC-II fill with a
/// bevel, light on the top and left (3px) and thicker and dark on the bottom
/// and right (5px), never a blurred shadow or gradient, and (unless switched
/// off in settings) a shine, scanlines and dithered shade drawn over it by
/// [TileGloss]; or, in the grid editor, a bright outline if [selected] and a
/// delete badge if [onDelete] is given. [content] draws whatever the tile's kind
/// wants inside that frame; see [tileContent].
///
/// While it is pressed the bevel flips (dark top-left, light bottom-right),
/// which moves the content down and right by the difference of the two widths
/// and takes the shine off, so the tile reads as a key being pushed in. What
/// counts as pressed, and when a tap ticks, is [PressListener]'s: a finger that
/// is only scrolling never sinks a tile. A long-press thuds (unless haptics are
/// off in settings).
class TileView extends StatelessWidget {
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

  void _onLongPress(BuildContext context) {
    haptic(context, Haptic.press);
    onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Color fill = colour.fill;
    final Color light = Color.lerp(fill, C64.white, 0.35)!;
    final Color dark = Color.lerp(fill, C64.black, 0.35)!;
    final bool effects = SettingsScope.of(context).effects;

    return PressListener(
      // A tile in the editor takes taps (to select it); on home only a tile
      // that does something is worth a tick. Contents that take the tap
      // themselves (a toggle) pass `onTap: null` and still sink, but do not
      // tick here.
      hasTap: onTap != null,
      builder: (BuildContext context, bool pressed) {
        final bool sunk = pressed && !selected;
        final Color topLeft = sunk ? dark : light;
        final Color bottomRight = sunk ? light : dark;
        const double inset = TileMetrics.gutter / 2;
        const double lit = TileMetrics.tileBevelLight;
        const double shaded = TileMetrics.tileBevelDark;
        final double topLeftWidth = sunk ? shaded : lit;
        final double bottomRightWidth = sunk ? lit : shaded;
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            InkWell(
              onTap: onTap,
              onLongPress: onLongPress == null
                  ? null
                  : () => _onLongPress(context),
              // Ours: the built-in feedback would buzz even with haptics off
              // and twice on a long-press.
              enableFeedback: false,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: pressDuration,
                decoration: BoxDecoration(
                  color: fill,
                  border: selected
                      ? Border.all(
                          color: TileColors.textBright,
                          width: TileMetrics.bevel * 2,
                        )
                      : Border(
                          top: BorderSide(color: topLeft, width: topLeftWidth),
                          left: BorderSide(color: topLeft, width: topLeftWidth),
                          right: BorderSide(
                            color: bottomRight,
                            width: bottomRightWidth,
                          ),
                          bottom: BorderSide(
                            color: bottomRight,
                            width: bottomRightWidth,
                          ),
                        ),
                ),
                padding: const EdgeInsets.all(inset),
                child: Stack(
                  children: <Widget>[
                    content,
                    if (onDelete != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _DeleteBadge(key: deleteKey, onTap: onDelete!),
                      ),
                  ],
                ),
              ),
            ),
            if (effects) TileGloss(sunk: sunk, outlined: selected),
          ],
        );
      },
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
      return AppTileContent(
        label: labelFor(tile),
        ink: tile.colour.ink,
        packageName: tile.id,
        iconOf: services.icons,
      );
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
                    _mailTap(
                      context,
                      mail,
                      mailContent.result,
                      refreshNow,
                      attachmentDownload: services.attachmentDownload,
                      contacts: services.contacts,
                    ),
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
    case TileKind.files:
      // Nothing to read from outside either: it opens the file explorer, and
      // that is all it does.
      return Builder(
        builder: (context) => FilesTileContentView(
          ink: tile.colour.ink,
          onTap: interactive
              ? () => unawaited(
                  showFilesSheet(
                    context,
                    service: services.files,
                    settings: SettingsScope.stateOf(context)!,
                  ),
                )
              : null,
        ),
      );
    case TileKind.qrScanner:
      // Nothing to read from outside either: it opens the scanner, and that
      // is all it does.
      return Builder(
        builder: (context) => QrScannerTileContentView(
          ink: tile.colour.ink,
          onTap: interactive
              ? () => unawaited(
                  showQrScannerScreen(
                    context,
                    camera: services.camera,
                    link: services.link,
                    clipboard: services.clipboard,
                  ),
                )
              : null,
        ),
      );
    case TileKind.alarm:
      final AlarmService alarm = services.alarm;
      return TilePoller(
        source: AlarmTileSource(service: alarm),
        // The next alarm rarely changes on its own; a resumed launcher and
        // closing the sheet below both refresh it sooner than this.
        interval: const Duration(minutes: 1),
        builder: (context, content, refreshNow) => AlarmTileContentView(
          next: (content as AlarmContent).next,
          ink: tile.colour.ink,
          // The sheet only sets or opens lists (never here itself), so the
          // tile re-reads once it closes rather than waiting on the poll.
          onTap: interactive
              ? () => unawaited(
                  showAlarmSheet(
                    context,
                    alarm: alarm,
                  ).then((_) => refreshNow()),
                )
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
    case TileKind.orientationLock:
      return TilePoller(
        source: ToggleTileSource(kind: tile.kind, control: systemControl),
        interval: const Duration(seconds: 5),
        builder: (context, content, refreshNow) {
          final bool on = (content as ToggleContent).on;
          return StateTileContentView(
            label: displayNameOf(tile.kind),
            state: _toggleStateOf(tile.kind, on),
            ink: tile.colour.ink,
            onTap: interactive
                ? () => unawaited(
                    _act(() => systemControl.setOn(tile.kind, !on), refreshNow),
                  )
                : null,
          );
        },
      );
    case TileKind.scene:
      // Nothing to read from outside: its content is a setting
      // (LauncherSettings.sceneAnimation), not a platform read, so it reads
      // SettingsScope directly instead of going through a TileSource/
      // TilePoller — the same "nothing to poll, just a tap" shape the calc,
      // files and QR scanner tiles use, via the same Builder for a context
      // of its own.
      return Builder(
        builder: (context) => SceneTileContentView(
          animation: SettingsScope.of(context).sceneAnimation,
          onTap: interactive
              ? () => unawaited(
                  showSceneSheet(
                    context,
                    settings: SettingsScope.stateOf(context)!,
                  ),
                )
              : null,
        ),
      );
    case TileKind.media:
      final MediaService media = services.media;
      return TilePoller(
        source: MediaTileSource(service: media),
        interval: const Duration(seconds: 5),
        builder: (context, content, refreshNow) {
          final MediaSnapshot snapshot = (content as MediaContent).snapshot;
          return MediaTileContentView(
            snapshot: snapshot,
            ink: tile.colour.ink,
            onTap: interactive
                ? () =>
                      unawaited(_mediaTap(context, media, snapshot, refreshNow))
                : null,
          );
        },
      );
  }
}

/// The flashlight's `[ON]`/`[OFF]`, or the rotation lock's own
/// `[LOCKED]`/`[AUTO]` — both are `on`/`off`, but "on" reads oddly for a lock.
String _toggleStateOf(TileKind kind, bool on) => switch (kind) {
  TileKind.orientationLock => on ? '[LOCKED]' : '[AUTO]',
  _ => on ? '[ON]' : '[OFF]',
};

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
/// where the setting is. The tile reads again once the sheet closes: an event
/// may have been added, changed or deleted there, or a calendar hidden, and
/// the next poll is up to a minute away.
void _agendaTap(
  BuildContext context,
  AgendaRepository agenda,
  AgendaSnapshot snapshot,
  VoidCallback refreshNow,
) {
  switch (snapshot) {
    case AgendaReady():
      unawaited(
        showAgendaSheet(context, repository: agenda).then((_) => refreshNow()),
      );
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
  VoidCallback refreshNow, {
  required AttachmentDownloadService attachmentDownload,
  required ContactsRepository contacts,
}) async {
  switch (result) {
    case MailNotSetUp():
      await showMailSetupSheet(context, mail: mail);
    case MailMessages():
      await showMailSheet(
        context,
        mail: mail,
        attachmentDownload: attachmentDownload,
        contacts: contacts,
      );
    case MailUnavailable():
      // A saved account that cannot be read (its key is gone) never will be:
      // set it up again. Anything else is worth another try.
      if (await mail.account() == null && context.mounted) {
        await showMailSetupSheet(context, mail: mail);
      }
  }
  refreshNow();
}

/// What a tap on the Now Playing tile does: open the full pane when
/// something is playing, open Android's notification-access settings when
/// that is what is missing (there is no runtime dialog for it to ask
/// instead), or just read again.
Future<void> _mediaTap(
  BuildContext context,
  MediaService media,
  MediaSnapshot snapshot,
  VoidCallback refreshNow,
) async {
  switch (snapshot) {
    case MediaNeedsNotificationAccess():
      await media.openAccessSettings();
    case MediaPlaying() || MediaNone() || MediaUnavailable():
      await showMediaSheet(context, media: media);
  }
  refreshNow();
}

/// An app tile's content: the app's own icon (its first letter as a glyph while
/// that loads, when it has none, or with APP ICONS off) and the label itself
/// along the bottom edge. Without a [packageName] and [iconOf] (a contact's
/// tile) it is always the letter.
class AppTileContent extends StatelessWidget {
  const AppTileContent({
    super.key,
    required this.label,
    required this.ink,
    this.packageName,
    this.iconOf,
  });

  final String label;
  final Color ink;
  final String? packageName;
  final AppIconLoader? iconOf;

  /// The room the label takes along the bottom.
  static const double labelSpace = 14;

  /// The largest an icon is drawn; a big tile does not need a bigger one.
  static const double maxIcon = 72;

  @override
  Widget build(BuildContext context) {
    final String glyph = label.isEmpty ? '?' : label[0].toUpperCase();
    final Widget letter = FittedBox(
      child: Text(
        glyph,
        style: TextStyle(fontFamily: kPixelFontFamily, color: ink),
      ),
    );
    final String? package = packageName;
    final AppIconLoader? loader = iconOf;
    return Stack(
      children: <Widget>[
        if (package != null && loader != null)
          Positioned.fill(
            bottom: labelSpace,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints box) {
                final double side = (box.biggest.shortestSide * 0.9).clamp(
                  0.0,
                  maxIcon,
                );
                return Center(
                  child: AppIcon(
                    packageName: package,
                    loader: loader,
                    size: side,
                    fallback: Center(child: letter),
                  ),
                );
              },
            ),
          )
        else
          Center(child: letter),
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
