import 'package:android_tile_launcher/ui/file_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget icon) => tester.pumpWidget(
  MaterialApp(
    home: Center(child: SizedBox(width: 20, height: 20, child: icon)),
  ),
);

void main() {
  testWidgets('FolderIcon draws with no exception', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const FolderIcon(size: 20, color: Colors.white));

    expect(find.byType(FolderIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DocumentIcon draws with no exception', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const DocumentIcon(size: 20, color: Colors.white));

    expect(find.byType(DocumentIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TrashIcon draws with no exception', (WidgetTester tester) async {
    await _pump(tester, const TrashIcon(size: 20, color: Colors.white));

    expect(find.byType(TrashIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
