import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/qr_icon.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The QR scanner tile's content: its name, a QR code picture, and on a
/// larger tile what it's for. A tap ([onTap]) opens the scanner; `null` in the
/// grid editor, where a tap selects the tile. There is nothing to read from
/// the outside world, so it never changes.
class QrScannerTileContentView extends StatelessWidget {
  const QrScannerTileContentView({super.key, required this.ink, this.onTap});

  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxWidth < 120;
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(Messages.qrScannerTitle, style: _text(compact ? 8 : 10)),
                  const SizedBox(height: 4),
                  QrCodeIcon(size: compact ? 22 : 32, color: ink),
                  if (!compact) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(Messages.qrScannerSubtitle, style: _text(8)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
    final VoidCallback? tap = onTap;
    if (tap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: body,
    );
  }

  TextStyle _text(double size) =>
      TextStyle(fontFamily: kPixelFontFamily, fontSize: size, color: ink);
}
