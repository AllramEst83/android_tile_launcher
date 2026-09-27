import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  bool selected = false,
  VoidCallback? onDelete,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: SizedBox(
        width: 100,
        height: 100,
        child: TileView(
          colour: C64Colour.red,
          content: const Text('CONTENT'),
          onTap: onTap,
          onLongPress: onLongPress,
          selected: selected,
          onDelete: onDelete,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders whatever content it is given', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(find.text('CONTENT'), findsOneWidget);
  });

  testWidgets('tapping calls onTap', (WidgetTester tester) async {
    var tapped = false;
    await _pump(tester, onTap: () => tapped = true);

    await tester.tap(find.byType(TileView));

    expect(tapped, isTrue);
  });

  testWidgets('is not tappable when onTap is null', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    final InkWell inkWell = tester.widget(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });

  testWidgets('long-pressing calls onLongPress', (WidgetTester tester) async {
    var longPressed = false;
    await _pump(tester, onLongPress: () => longPressed = true);

    await tester.longPress(find.byType(TileView));

    expect(longPressed, isTrue);
  });

  testWidgets('shows no delete badge when onDelete is null', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(find.text('X'), findsNothing);
  });

  testWidgets('tapping the delete badge calls onDelete', (
    WidgetTester tester,
  ) async {
    var deleted = false;
    await _pump(tester, onDelete: () => deleted = true);

    await tester.tap(find.text('X'));

    expect(deleted, isTrue);
  });
}
