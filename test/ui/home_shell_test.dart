import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/home_shell.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpShell(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(theme: tileLauncherTheme(), home: const HomeShell()),
);

void main() {
  testWidgets('boot screen ends on the ready prompt', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    expect(find.text(Messages.bootBanner), findsOneWidget);
    expect(find.text(Messages.bootReady), findsOneWidget);
  });

  testWidgets('back never leaves the launcher', (WidgetTester tester) async {
    await pumpShell(tester);

    expect(
      find.byWidgetPredicate((Widget w) => w is PopScope && !w.canPop),
      findsOneWidget,
    );
  });
}
