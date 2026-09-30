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

/// Opens the QR scanner over the whole screen, the same `fullscreenDialog`
/// route Text TV and Help open as. A close button sits over either the live
/// camera preview (once CAMERA is granted) or the same "tap to allow"/"allow
/// in settings" wording every other permission-gated tile uses. A decoded
/// value offers OPEN (when it looks like a web link) and COPY, and SCAN AGAIN
/// to go back to the viewfinder.
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
  /// report a decoded value; defaults to a real [MobileScanner]. A test
  /// overrides this to avoid touching real camera hardware.
  final Widget Function(ValueChanged<String> onDetect)? scannerBuilder;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  CameraAccess? _access;
  String? _scanned;
  String? _message;

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
    });
  }

  void _scanAgain() {
    setState(() {
      _scanned = null;
      _message = null;
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
      CameraGranted() =>
        _scanned == null
            ? _Viewfinder(builder: widget.scannerBuilder, onDetect: _onDetect)
            : _Result(value: _scanned!),
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
    return Row(
      children: <Widget>[
        if (isWebLink) ...<Widget>[
          Expanded(
            child: PadKey(
              key: qrScannerOpenKey,
              label: Messages.qrScannerOpen,
              onTap: () => _open(scanned),
            ),
          ),
          const SizedBox(width: TileMetrics.gutter),
        ],
        Expanded(
          child: PadKey(
            key: qrScannerCopyKey,
            label: Messages.qrScannerCopy,
            onTap: () => _copy(scanned),
          ),
        ),
        const SizedBox(width: TileMetrics.gutter),
        Expanded(
          child: PadKey(
            key: qrScannerScanAgainKey,
            label: Messages.qrScannerScanAgain,
            onTap: _scanAgain,
          ),
        ),
      ],
    );
  }
}

/// The live camera preview, filling the black area between the close button
/// and the footer.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.builder, required this.onDetect});

  final Widget Function(ValueChanged<String> onDetect)? builder;
  final ValueChanged<String> onDetect;

  @override
  Widget build(BuildContext context) {
    final Widget Function(ValueChanged<String>) build = builder ?? _realScanner;
    return ColoredBox(color: C64.black, child: build(onDetect));
  }
}

Widget _realScanner(ValueChanged<String> onDetect) => MobileScanner(
  onDetect: (BarcodeCapture capture) {
    for (final Barcode barcode in capture.barcodes) {
      final String? value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        onDetect(value);
        return;
      }
    }
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
