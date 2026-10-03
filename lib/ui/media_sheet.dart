import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/media_snapshot.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/media_service.dart';
import 'package:android_tile_launcher/services/media_tile_source.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_poller.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key mediaSheetArtKey = ValueKey<String>('media-sheet-art');
const Key mediaPlayPauseKey = ValueKey<String>('media-play-pause');
const Key mediaPrevKey = ValueKey<String>('media-prev');
const Key mediaNextKey = ValueKey<String>('media-next');
const Key mediaOpenSettingsKey = ValueKey<String>('media-open-settings');

/// What a tap on the Now Playing tile opens: the same session, bigger — art,
/// title, artist, album and the app it is playing in — with PREV, PLAY/PAUSE
/// and NEXT below it. It keeps reading [media] every couple of seconds, the
/// same as the tile itself, so a track change or a pause from elsewhere (the
/// lock screen, the app itself) shows here without a manual refresh. With no
/// access it offers the one fix there is: Android's own settings page.
Future<void> showMediaSheet(
  BuildContext context, {
  required MediaService media,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: TilePoller(
          source: MediaTileSource(service: media),
          interval: const Duration(seconds: 2),
          builder: (context, content, refreshNow) => _MediaSheetBody(
            snapshot: (content as MediaContent).snapshot,
            media: media,
            refreshNow: refreshNow,
          ),
        ),
      ),
    ),
  );
}

class _MediaSheetBody extends StatefulWidget {
  const _MediaSheetBody({
    required this.snapshot,
    required this.media,
    required this.refreshNow,
  });

  final MediaSnapshot snapshot;
  final MediaService media;
  final VoidCallback refreshNow;

  @override
  State<_MediaSheetBody> createState() => _MediaSheetBodyState();
}

class _MediaSheetBodyState extends State<_MediaSheetBody> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (!mounted) return;
    setState(() => _busy = false);
    widget.refreshNow();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return switch (widget.snapshot) {
      final MediaPlaying media => _playing(text, media),
      MediaNone() => _message(text, Messages.mediaNothingPlaying),
      MediaUnavailable(:final String reason) => _message(
        text,
        reason.toUpperCase(),
        retry: true,
      ),
      MediaNeedsNotificationAccess() => _needsAccess(text),
    };
  }

  Widget _playing(TextTheme text, MediaPlaying media) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (media.artwork != null)
          ClipRect(
            child: Image.memory(
              media.artwork!,
              key: mediaSheetArtKey,
              width: 160,
              height: 160,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox(width: 160, height: 160),
            ),
          ),
        const SizedBox(height: TileMetrics.margin),
        Text(
          media.title.toUpperCase(),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: TileColors.textBright),
        ),
        const SizedBox(height: 4),
        Text(
          media.artist.toUpperCase(),
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
        if (media.album != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            media.album!.toUpperCase(),
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: TileColors.muted),
          ),
        ],
        if (media.appLabel != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            media.appLabel!.toUpperCase(),
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              fontSize: 10,
              color: TileColors.muted,
            ),
          ),
        ],
        const SizedBox(height: TileMetrics.margin),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _ControlButton(
              key: mediaPrevKey,
              label: Messages.mediaPrev,
              onTap: _busy
                  ? null
                  : () => unawaited(_run(widget.media.previous)),
            ),
            const SizedBox(width: TileMetrics.gutter),
            _ControlButton(
              key: mediaPlayPauseKey,
              label: media.isPlaying ? Messages.mediaPause : Messages.mediaPlay,
              onTap: _busy
                  ? null
                  : () => unawaited(_run(widget.media.playPause)),
            ),
            const SizedBox(width: TileMetrics.gutter),
            _ControlButton(
              key: mediaNextKey,
              label: Messages.mediaNext,
              onTap: _busy ? null : () => unawaited(_run(widget.media.next)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _message(TextTheme text, String line, {bool retry = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TileMetrics.margin),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(line, textAlign: TextAlign.center, style: text.bodyMedium),
          if (retry) ...<Widget>[
            const SizedBox(height: TileMetrics.gutter),
            _ControlButton(
              label: Messages.mediaTapToRetry,
              onTap: widget.refreshNow,
            ),
          ],
        ],
      ),
    );
  }

  Widget _needsAccess(TextTheme text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TileMetrics.margin),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            Messages.mediaTapToAllow,
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
          const SizedBox(height: TileMetrics.gutter),
          _ControlButton(
            key: mediaOpenSettingsKey,
            label: Messages.mediaTapToAllow,
            onTap: () => unawaited(widget.media.openAccessSettings()),
          ),
        ],
      ),
    );
  }
}

/// A bordered text button in the launcher's own look, same shape as the
/// contact sheet's own action buttons. `null` [onTap] greys it.
class _ControlButton extends StatelessWidget {
  const _ControlButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color colour = onTap == null
        ? TileColors.textDim
        : TileColors.textBright;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colour, width: TileMetrics.bevel),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize: 10, color: colour),
        ),
      ),
    );
  }
}
