import 'dart:typed_data';

import 'package:android_tile_launcher/services/app_repository.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:flutter/material.dart';

/// An app's own icon at [size], fetched with [loader] (`AppRepository.icon`).
/// Shows [fallback] in its place while the icon loads, when the app has none,
/// when the picture cannot be read, and when APP ICONS is switched off in
/// settings. Never throws and never takes a touch.
class AppIcon extends StatefulWidget {
  const AppIcon({
    super.key,
    required this.packageName,
    required this.loader,
    required this.size,
    required this.fallback,
  });

  final String packageName;
  final AppIconLoader loader;
  final double size;
  final Widget fallback;

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AppIcon old) {
    super.didUpdateWidget(old);
    if (old.packageName != widget.packageName || old.loader != widget.loader) {
      _bytes = null;
      _load();
    }
  }

  Future<void> _load() async {
    final String wanted = widget.packageName;
    Uint8List? bytes;
    try {
      bytes = await widget.loader(wanted);
    } on Object {
      bytes = null;
    }
    // The tile may since have been given another app, or gone.
    if (!mounted || wanted != widget.packageName) return;
    if (bytes == null || bytes.isEmpty) return;
    setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = _bytes;
    final bool show = SettingsScope.of(context).appIcons && bytes != null;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: IgnorePointer(
        child: show
            ? Image.memory(
                bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (BuildContext context, Object e, StackTrace? s) =>
                    widget.fallback,
              )
            : widget.fallback,
      ),
    );
  }
}
