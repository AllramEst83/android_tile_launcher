import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/camera_access.dart';
import 'package:android_tile_launcher/services/link_service.dart';
import 'package:android_tile_launcher/ui/qr_scanner_screen.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_camera_service.dart';
import '../fakes/fake_clipboard_service.dart';
import '../fakes/fake_link_service.dart';

const Key _fakeScannerKey = ValueKey<String>('fake-scanner');
const Key _fakeUnreadableKey = ValueKey<String>('fake-unreadable');

/// Stands in for the real camera preview: one button that reports [value] as
/// a decoded code when tapped, and another that reports a code-shaped thing
/// that could not be decoded, so a test never touches real camera hardware.
Widget Function(ValueChanged<String>, VoidCallback) _fakeScannerDetecting(
  String value,
) =>
    (ValueChanged<String> onDetect, VoidCallback onUnreadable) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextButton(
          key: _fakeScannerKey,
          onPressed: () => onDetect(value),
          child: const Text('DETECT'),
        ),
        TextButton(
          key: _fakeUnreadableKey,
          onPressed: onUnreadable,
          child: const Text('UNREADABLE'),
        ),
      ],
    );

Future<void> _open(
  WidgetTester tester, {
  required FakeCameraService camera,
  FakeLinkService? link,
  FakeClipboardService? clipboard,
  Widget Function(ValueChanged<String>, VoidCallback)? scanner,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => QrScannerScreen(
                camera: camera,
                link: link ?? FakeLinkService(),
                clipboard: clipboard ?? FakeClipboardService(),
                scannerBuilder: scanner,
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the close key closes the screen', (WidgetTester tester) async {
    await _open(tester, camera: FakeCameraService());

    await tester.tap(find.byKey(qrScannerCloseKey));
    await tester.pumpAndSettle();

    expect(find.text(Messages.qrScannerTitle), findsNothing);
  });

  testWidgets('once granted, shows the viewfinder and says to aim', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      camera: FakeCameraService(),
      scanner: _fakeScannerDetecting('hello'),
    );

    expect(find.byKey(_fakeScannerKey), findsOneWidget);
    expect(find.text(Messages.qrScannerAim), findsOneWidget);
  });

  group('needs permission', () {
    testWidgets('offers to allow it, and asks again when tapped', (
      WidgetTester tester,
    ) async {
      final camera = FakeCameraService(
        result: const CameraDenied(permanent: false),
      );
      await _open(tester, camera: camera);

      expect(find.byKey(qrScannerAllowKey), findsOneWidget);
      expect(camera.requests, 1);

      await tester.tap(find.byKey(qrScannerAllowKey));
      await tester.pumpAndSettle();

      expect(camera.requests, 2);
    });

    testWidgets('permanently denied says to allow in settings, no retry', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        camera: FakeCameraService(result: const CameraDenied(permanent: true)),
      );

      expect(find.text(Messages.qrScannerAllowInSettings), findsOneWidget);
      expect(find.byKey(qrScannerAllowKey), findsNothing);
    });
  });

  group('a decoded code', () {
    testWidgets('plain text offers COPY and SCAN AGAIN, but not OPEN', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        camera: FakeCameraService(),
        scanner: _fakeScannerDetecting('just some text'),
      );

      await tester.tap(find.byKey(_fakeScannerKey));
      await tester.pumpAndSettle();

      expect(find.text('just some text'), findsOneWidget);
      expect(find.byKey(qrScannerCopyKey), findsOneWidget);
      expect(find.byKey(qrScannerScanAgainKey), findsOneWidget);
      expect(find.byKey(qrScannerOpenKey), findsNothing);
    });

    testWidgets('a web link also offers OPEN', (WidgetTester tester) async {
      final link = FakeLinkService();
      await _open(
        tester,
        camera: FakeCameraService(),
        link: link,
        scanner: _fakeScannerDetecting('https://example.com'),
      );
      await tester.tap(find.byKey(_fakeScannerKey));
      await tester.pumpAndSettle();

      expect(find.byKey(qrScannerOpenKey), findsOneWidget);

      await tester.tap(find.byKey(qrScannerOpenKey));
      await tester.pumpAndSettle();

      expect(link.opened, <String>['https://example.com']);
    });

    testWidgets('OPEN failing says so', (WidgetTester tester) async {
      await _open(
        tester,
        camera: FakeCameraService(),
        link: FakeLinkService(result: const LinkFailed('nope')),
        scanner: _fakeScannerDetecting('https://example.com'),
      );
      await tester.tap(find.byKey(_fakeScannerKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(qrScannerOpenKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.qrScannerOpenFailed), findsOneWidget);
    });

    testWidgets('COPY writes it to the clipboard and says so', (
      WidgetTester tester,
    ) async {
      final clipboard = FakeClipboardService();
      await _open(
        tester,
        camera: FakeCameraService(),
        clipboard: clipboard,
        scanner: _fakeScannerDetecting('some text'),
      );
      await tester.tap(find.byKey(_fakeScannerKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(qrScannerCopyKey));
      await tester.pumpAndSettle();

      expect(clipboard.text, 'some text');
      expect(find.text(Messages.qrScannerCopied), findsOneWidget);
    });

    testWidgets('SCAN AGAIN returns to the viewfinder', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        camera: FakeCameraService(),
        scanner: _fakeScannerDetecting('some text'),
      );
      await tester.tap(find.byKey(_fakeScannerKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(qrScannerScanAgainKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_fakeScannerKey), findsOneWidget);
      expect(find.byKey(qrScannerCopyKey), findsNothing);
      expect(find.text(Messages.qrScannerAim), findsOneWidget);
    });

    testWidgets(
      'the footer keys share one height, even though SCAN AGAIN is longest',
      (WidgetTester tester) async {
        await _open(
          tester,
          camera: FakeCameraService(),
          scanner: _fakeScannerDetecting('https://example.com'),
        );
        await tester.tap(find.byKey(_fakeScannerKey));
        await tester.pumpAndSettle();

        final double openHeight = tester
            .getSize(find.byKey(qrScannerOpenKey))
            .height;
        final double copyHeight = tester
            .getSize(find.byKey(qrScannerCopyKey))
            .height;
        final double scanAgainHeight = tester
            .getSize(find.byKey(qrScannerScanAgainKey))
            .height;
        expect(copyHeight, openHeight);
        expect(scanAgainHeight, openHeight);
      },
    );
  });

  group('the reticle', () {
    testWidgets('shows while aiming, hidden once a code is read', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        camera: FakeCameraService(),
        scanner: _fakeScannerDetecting('hello'),
      );
      expect(find.byKey(qrScannerReticleKey), findsOneWidget);

      await tester.tap(find.byKey(_fakeScannerKey));
      await tester.pumpAndSettle();

      expect(find.byKey(qrScannerReticleKey), findsNothing);
    });

    testWidgets('an unreadable code flashes it without changing the view', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        camera: FakeCameraService(),
        scanner: _fakeScannerDetecting('hello'),
      );

      await tester.tap(find.byKey(_fakeUnreadableKey));
      await tester.pumpAndSettle();

      // Still aiming: no result, the fake scanner (and its DETECT button)
      // stays up, nothing was reported as read.
      expect(find.byKey(qrScannerReticleKey), findsOneWidget);
      expect(find.byKey(_fakeScannerKey), findsOneWidget);
      expect(find.text(Messages.qrScannerAim), findsOneWidget);
    });

    testWidgets('reappears, reset, after SCAN AGAIN', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        camera: FakeCameraService(),
        scanner: _fakeScannerDetecting('hello'),
      );
      await tester.tap(find.byKey(_fakeUnreadableKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_fakeScannerKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(qrScannerScanAgainKey));
      await tester.pumpAndSettle();

      expect(find.byKey(qrScannerReticleKey), findsOneWidget);
    });
  });
}
