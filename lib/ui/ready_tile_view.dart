import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key readyCursorKey = ValueKey<String>('ready-cursor');

/// The READY. tile: the C64 prompt with its blinking cursor. A tap
/// ([onTap]) runs the day's summary; `null` in the grid editor, where a tap
/// selects the tile.
class ReadyTileContentView extends StatefulWidget {
  const ReadyTileContentView({
    super.key,
    required this.ink,
    this.onTap,
    this.blink = const Duration(milliseconds: 500),
  });

  final Color ink;
  final VoidCallback? onTap;

  /// How long the cursor stays on, and then off.
  final Duration blink;

  @override
  State<ReadyTileContentView> createState() => _ReadyTileContentViewState();
}

class _ReadyTileContentViewState extends State<ReadyTileContentView> {
  Timer? _timer;
  bool _on = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.blink, (_) {
      if (mounted) setState(() => _on = !_on);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  TextStyle _text(double size) => TextStyle(
    fontFamily: kPixelFontFamily,
    fontSize: size,
    color: widget.ink,
  );

  @override
  Widget build(BuildContext context) {
    final Widget body = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxWidth < 120;
            // The whole stack shrinks to whatever room there is, as on the
            // alarm tile.
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(Messages.bootReady, style: _text(compact ? 12 : 16)),
                  const SizedBox(height: 4),
                  // A solid block while on, the same width blank while off, so
                  // the tile does not shift as it blinks.
                  Container(
                    key: readyCursorKey,
                    width: compact ? 12 : 16,
                    height: compact ? 12 : 16,
                    color: _on ? widget.ink : Colors.transparent,
                  ),
                  if (!compact) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(Messages.readyTileHint, style: _text(8)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
    final VoidCallback? tap = widget.onTap;
    if (tap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: body,
    );
  }
}
