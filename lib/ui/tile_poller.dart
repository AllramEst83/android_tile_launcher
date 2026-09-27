import 'dart:async';

import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/tile_source.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds [builder] with fresh content from [source] every [interval], but
/// only while the launcher is resumed — a backgrounded launcher has no
/// visible tiles, so there is nothing to refresh for. Shared by every live
/// tile kind; a kind's own view only has to say what its content looks like.
/// [builder]'s third argument re-reads [source] immediately, for a kind
/// whose content view can trigger its own state change (a toggle tile,
/// straight after a tap) and doesn't want to wait for the next tick.
class TilePoller extends StatefulWidget {
  const TilePoller({
    super.key,
    required this.source,
    required this.interval,
    required this.builder,
  });

  final TileSource source;
  final Duration interval;
  final Widget Function(
    BuildContext context,
    TileContent content,
    VoidCallback refreshNow,
  )
  builder;

  @override
  State<TilePoller> createState() => _TilePollerState();
}

class _TilePollerState extends State<TilePoller> with WidgetsBindingObserver {
  TileContent? _content;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) => _refresh());
  }

  Future<void> _refresh() async {
    final TileContent content = await widget.source.read();
    if (!mounted) return;
    setState(() => _content = content);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TileContent? content = _content;
    if (content == null) return const SizedBox.shrink();
    return widget.builder(context, content, () => unawaited(_refresh()));
  }
}
