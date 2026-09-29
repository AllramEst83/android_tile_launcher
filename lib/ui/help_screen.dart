import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/section_box.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key helpCloseKey = ValueKey<String>('help-close');

/// Reached from Settings' own `?`: a full-screen, read-only explanation of
/// what is on the home screen and how to change it — the same
/// `fullscreenDialog` route Settings itself opens as, not a sheet, since the
/// content is long enough to want the whole screen and its own scrollbar
/// rather than a bottom sheet's partial height.
Future<void> showHelpScreen(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext context) => const HelpScreen(),
    ),
  );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
                  PadKey(
                    key: helpCloseKey,
                    label: 'X',
                    height: 48,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: TileMetrics.margin),
                  Text(
                    Messages.helpTitle,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                TileMetrics.margin,
                0,
                TileMetrics.margin,
                TileMetrics.margin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SectionBox(
                    title: Messages.helpGettingAroundTitle,
                    children: <Widget>[_Body(Messages.helpGettingAroundBody)],
                  ),
                  SectionBox(
                    title: Messages.helpTilesTitle,
                    children: <Widget>[_Body(Messages.helpTilesBody)],
                  ),
                  SectionBox(
                    title: Messages.helpResizingTitle,
                    children: <Widget>[_Body(Messages.helpResizingBody)],
                  ),
                  SectionBox(
                    title: Messages.helpSettingsTitle,
                    children: <Widget>[_Body(Messages.helpSettingsBody)],
                  ),
                  SectionBox(
                    title: Messages.helpPrivacyTitle,
                    children: <Widget>[_Body(Messages.helpPrivacyBody)],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section's own explanation, in the same dimmer, roomier-line style
/// `settings_screen.dart`'s `_Note` already reads notes in.
class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: kPixelFontFamily,
        fontSize: 10,
        color: TileColors.textDim,
        height: 1.6,
      ),
    );
  }
}
