import 'package:android_tile_launcher/ui/clear_field_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('taps call onTap', (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ClearFieldButton(onTap: () => taps++)),
      ),
    );

    await tester.tap(find.byType(ClearFieldButton));

    expect(taps, 1);
  });
}
