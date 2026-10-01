import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/camera_access.dart';
import 'package:android_tile_launcher/services/camera_service.dart';
import 'package:android_tile_launcher/services/clipboard_service.dart';
import 'package:android_tile_launcher/services/link_service.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Keys so tests can find the parts.
const Key qrScannerCloseKey = ValueKey<String>('qr-scanner-close');
const Key qrScannerAllowKey = ValueKey<String>('qr-scanner-allow');
const Key qrScannerOpenKey = ValueKey<String>('qr-scanner-open');
const Key qrScannerCopyKey = ValueKey<String>('qr-scanner-copy');
const Key qrScannerScanAgainKey = ValueKey<String>('qr-scanner-scan-again');
const Key qrScannerReticleKey = ValueKey<String>('qr-scanner-reticle');

/// Opens the QR scanner over the whole screen, the same `fullscreenDialog`
/// route Text TV and Help open as. A close button sits over either the live
/// camera preview (once CAMERA is granted) or the same "tap to allow"/"allow
/// in settings" wording every other permission-gated tile uses. The preview
/// carries an aiming reticle that flashes red when a code-shaped thing is
/// seen but cannot be decoded; reading one successfully washes the result
/// screen green for an instant as it appears. A decoded value offers OPEN
/// (when it looks like a web link) and COPY, and SCAN AGAIN to go back to
/// the viewfinder.
Future<void> showQrScannerScreen(
  BuildContext context, {
  required CameraService camera,
  required LinkService link,
  required ClipboardService clipboard,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext context) =>
          QrScannerScreen(camera: camera, link: link, clipboard: clipboard),
    ),
  );
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
    required this.camera,
    required this.link,
    required this.clipboard,
    this.scannerBuilder,
  });

  final CameraService camera;
  final LinkService link;
  final ClipboardService clipboard;

  /// Builds the live viewfinder once CAMERA is granted, given a callback to
  /// report a decoded value and one to report a code-shaped thing that could
  /// not be decoded; defaults to a real [MobileScanner]. A test overrides
  /// this to avoid touching real camera hardware.
  final Widget Function(
    ValueChanged<String> onDetect,
    VoidCallback onUnreadable,
  )?
  scannerBuilder;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  CameraAccess? _access;
  String? _scanned;
  String? _message;

  /// The reticle's last flash colour (red: a code-shaped thing was seen but
  /// could not be decoded) and a token that changes on every flash so the
  /// reticle restarts its fade-to-white animation even when the colour
  /// repeats. Cleared on SCAN AGAIN so a stale flash never replays.
  Color? _reticleFlash;
  int _reticleFlashToken = 0;

  /// Bumped on every successful read; a screen-wide green wash fades in and
  /// out over the result the instant it appears (the reticle itself is gone
  /// by then, since the live view gives way to the result at once).
  int _successFlashToken = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_allow());
  }

  Future<void> _allow() async {
    final CameraAccess access = await widget.camera.request();
    if (!mounted) return;
    setState(() => _access = access);
  }

  void _onDetect(String value) {
    // Already showing a result; ignore further frames until SCAN AGAIN.
    if (_scanned != null) return;
    setState(() {
      _scanned = value;
      _message = null;
      _successFlashToken++;
    });
  }

  /// A barcode-shaped thing was seen but gave up no usable value (damaged,
  /// blurry, or an empty code) — flash the reticle red rather than staying
  /// silent about it.
  void _onUnreadable() {
    if (_scanned != null) return;
    setState(() {
      _reticleFlash = C64.red;
      _reticleFlashToken++;
    });
  }

  void _scanAgain() {
    setState(() {
      _scanned = null;
      _message = null;
      _reticleFlash = null;
    });
  }

  Future<void> _open(String value) async {
    final LinkResult result = await widget.link.open(value);
    if (!mounted) return;
    if (result is LinkFailed) {
      setState(() => _message = Messages.qrScannerOpenFailed);
    }
  }

  Future<void> _copy(String value) async {
    final bool ok = await widget.clipboard.write(value);
    if (!mounted) return;
    setState(() => _message = ok ? Messages.qrScannerCopied : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TileColors.canvas,
      body: Column(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(TileMetrics.gutter),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 48,
                    child: PadKey(
                      key: qrScannerCloseKey,
                      label: 'X',
                      height: 32,
                      fontSize: 12,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: TileMetrics.margin),
                  Expanded(
                    child: Text(
                      Messages.qrScannerTitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _body(context)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(TileMetrics.gutter),
              child: _footer(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final CameraAccess? access = _access;
    if (access == null) return const SizedBox.shrink();
    return switch (access) {
      CameraGranted() => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _scanned == null
              ? _Viewfinder(
                  builder: widget.scannerBuilder,
                  onDetect: _onDetect,
                  onUnreadable: _onUnreadable,
                )
              : _Result(value: _scanned!),
          if (_scanned == null)
            _Reticle(
              key: qrScannerReticleKey,
              flashColor: _reticleFlash,
              token: _reticleFlashToken,
            ),
          if (_successFlashToken > 0)
            _FlashOverlay(color: C64.green, token: _successFlashToken),
        ],
      ),
      CameraDenied(:final permanent) => Center(
        child: Padding(
          padding: const EdgeInsets.all(TileMetrics.margin),
          child: permanent
              ? Text(
                  Messages.qrScannerAllowInSettings,
                  style: text.bodyMedium,
                  textAlign: TextAlign.center,
                )
              : PadKey(
                  key: qrScannerAllowKey,
                  label: Messages.qrScannerTapToAllow,
                  onTap: _allow,
                ),
        ),
      ),
    };
  }

  Widget _footer(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    if (_access is! CameraGranted) return const SizedBox.shrink();
    final String? message = _message;
    if (message != null) {
      return Text(message, style: text.bodySmall, textAlign: TextAlign.center);
    }
    final String? scanned = _scanned;
    if (scanned == null) {
      return Text(
        Messages.qrScannerAim,
        style: text.bodySmall,
        textAlign: TextAlign.center,
      );
    }
    final Uri? url = Uri.tryParse(scanned);
    final bool isWebLink =
        url != null && (url.scheme == 'http' || url.scheme == 'https');
    // IntrinsicHeight + stretch: SCAN AGAIN is the longest label and, on a
    // narrow phone, wraps to two lines — without this the other keys stay a
    // single line's height and the row looks ragged instead of an even bar.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isWebLink) ...<Widget>[
            Expanded(
              child: PadKey(
                key: qrScannerOpenKey,
                label: Messages.qrScannerOpen,
                height: 44,
                fontSize: 10,
                onTap: () => _open(scanned),
              ),
            ),
            const SizedBox(width: TileMetrics.gutter),
          ],
          Expanded(
            child: PadKey(
              key: qrScannerCopyKey,
              label: Messages.qrScannerCopy,
              height: 44,
              fontSize: 10,
              onTap: () => _copy(scanned),
            ),
          ),
          const SizedBox(width: TileMetrics.gutter),
          Expanded(
            child: PadKey(
              key: qrScannerScanAgainKey,
              label: Messages.qrScannerScanAgain,
              height: 44,
              fontSize: 10,
              onTap: _scanAgain,
            ),
          ),
        ],
      ),
    );
  }
}

/// The live camera preview, filling the black area between the close button
/// and the footer.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.builder,
    required this.onDetect,
    required this.onUnreadable,
  });

  final Widget Function(
    ValueChanged<String> onDetect,
    VoidCallback onUnreadable,
  )?
  builder;
  final ValueChanged<String> onDetect;
  final VoidCallback onUnreadable;

  @override
  Widget build(BuildContext context) {
    final build = builder ?? _realScanner;
    return ColoredBox(color: C64.black, child: build(onDetect, onUnreadable));
  }
}

Widget _realScanner(ValueChanged<String> onDetect, VoidCallback onUnreadable) =>
    MobileScanner(
      onDetect: (BarcodeCapture capture) {
        for (final Barcode barcode in capture.barcodes) {
          final String? value = barcode.rawValue;
          if (value != null && value.isNotEmpty) {
            onDetect(value);
            return;
          }
        }
        // MLKit found something barcode-shaped but could not read a value
        // out of it (damaged, blurry, or an unsupported/empty payload).
        if (capture.barcodes.isNotEmpty) onUnreadable();
      },
    );

/// What a decoded code said, centred where the viewfinder was.
class _Result extends StatelessWidget {
  const _Result({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: C64.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(TileMetrics.margin),
          child: SingleChildScrollView(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: C64.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// The aiming frame over the live preview: four corner brackets, centred,
/// resting white. [flashColor] (with [token] changing on every flash, so the
/// animation restarts even when the colour repeats) sets the colour it
/// starts at; it always eases back to white over half a second on its own,
/// so neither a read nor an unreadable code needs its own timer to clear.
class _Reticle extends StatelessWidget {
  const _Reticle({super.key, required this.flashColor, required this.token});

  final Color? flashColor;
  final int token;

  static const double _side = 220;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<Color?>(
          key: ValueKey<int>(token),
          tween: ColorTween(begin: flashColor ?? C64.white, end: C64.white),
          duration: const Duration(milliseconds: 500),
          builder: (BuildContext context, Color? color, Widget? child) =>
              SizedBox(
                width: _side,
                height: _side,
                child: CustomPaint(
                  painter: _ReticlePainter(color: color ?? C64.white),
                ),
              ),
        ),
      ),
    );
  }
}

/// Four L-shaped corner brackets around [size], hard-edged like every other
/// frame in the app (no rounding, no blur).
class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double arm = size.shortestSide * 0.2;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final List<Offset> corners = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    for (final Offset corner in corners) {
      final double dx = corner.dx == 0 ? arm : -arm;
      final double dy = corner.dy == 0 ? arm : -arm;
      canvas.drawLine(corner, corner + Offset(dx, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A screen-wide wash of [color] (green, for a successful read) that fades
/// from a quarter-opaque flash down to nothing over the first instant the
/// result appears — the reticle itself is already gone by then, since the
/// live view gives way to the result the same instant a code is read.
class _FlashOverlay extends StatelessWidget {
  const _FlashOverlay({required this.color, required this.token});

  final Color color;
  final int token;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(token),
        tween: Tween<double>(begin: 0.35, end: 0),
        duration: const Duration(milliseconds: 400),
        builder: (BuildContext context, double opacity, Widget? child) =>
            ColoredBox(color: color.withValues(alpha: opacity)),
      ),
    );
  }
}
