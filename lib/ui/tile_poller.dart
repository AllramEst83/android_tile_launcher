import 'dart:async';

import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/tile_source.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds [builder] with fresh content from [source] every [interval], but
/// only while the launcher is resumed — a backgrounded launcher has no
/// visible tiles, so there is nothing to refresh for. Shared by every live
/// tile kind; a kind's own view only has to say what its content looks like.
class TilePoller extends StatefulWidget {
  const TilePoller({
    super.key,
    required this.source,
    required this.interval,
    required this.builder,
  });

  final TileSource source;
  final Duration interval;
  final Widget Function(BuildContext context, TileContent content) builder;

  @override
  State<TilePoller> createState() => _TilePollerState();
}

class _TilePollerState extends State<TilePoller> with WidgetsBindingObserver {
  late TileContent _content;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _content = widget.source.read();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) => _refresh());
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _content = widget.source.read());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
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
  Widget build(BuildContext context) => widget.builder(context, _content);
}
