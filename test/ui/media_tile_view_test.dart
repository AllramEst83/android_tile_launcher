import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/media_snapshot.dart';
import 'package:android_tile_launcher/ui/media_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  MediaSnapshot snapshot, {
  Size size = const Size(185, 185),
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: MediaTileContentView(
            snapshot: snapshot,
            ink: Colors.white,
            onTap: onTap,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  group('a playing session', () {
    const MediaPlaying media = MediaPlaying(
      title: 'A Song Title',
      artist: 'A Band',
      isPlaying: true,
    );

    testWidgets('compact: title and artist, no state marker', (
      WidgetTester tester,
    ) async {
      await _pump(tester, media, size: const Size(100, 100));

      expect(find.textContaining('A SONG TITLE'), findsOneWidget);
      expect(find.textContaining('A BAND'), findsOneWidget);
      expect(find.text('[PLAYING]'), findsNothing);
    });

    testWidgets('medium: adds whether it is playing', (
      WidgetTester tester,
    ) async {
      await _pump(tester, media, size: const Size(185, 185));

      expect(find.text('[PLAYING]'), findsOneWidget);
    });

    testWidgets('paused shows [PAUSED] instead', (WidgetTester tester) async {
      await _pump(
        tester,
        const MediaPlaying(
          title: 'A Song Title',
          artist: 'A Band',
          isPlaying: false,
        ),
        size: const Size(185, 185),
      );

      expect(find.text('[PAUSED]'), findsOneWidget);
    });
  });

  group('nothing to show', () {
    testWidgets('no session says so', (WidgetTester tester) async {
      await _pump(tester, const MediaNone());

      expect(find.textContaining(Messages.mediaNothingPlaying), findsOneWidget);
    });

    testWidgets('needing access says to tap to allow it', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const MediaNeedsNotificationAccess());

      expect(find.textContaining(Messages.mediaTapToAllow), findsOneWidget);
    });

    testWidgets('a tap calls onTap', (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, const MediaNone(), onTap: () => taps++);

      await tester.tap(find.byType(MediaTileContentView));

      expect(taps, 1);
    });
  });
}
