import 'package:android_tile_launcher/ui/overscroll_gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int down = 0;
  int up = 0;

  Future<void> pumpList(WidgetTester tester, {int items = 3}) {
    down = 0;
    up = 0;
    return tester.pumpWidget(
      MaterialApp(
        home: OverscrollGestures(
          onPullDown: () => down++,
          onPushUp: () => up++,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              for (int i = 0; i < items; i++)
                SizedBox(height: 100, child: Text('row $i')),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('a long pull down from the top fires once', (
    WidgetTester tester,
  ) async {
    await pumpList(tester);

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(down, 1);
    expect(up, 0);
  });

  testWidgets('a long push up at the bottom fires once', (
    WidgetTester tester,
  ) async {
    await pumpList(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(up, 1);
    expect(down, 0);
  });

  testWidgets('a short pull is not enough', (WidgetTester tester) async {
    await pumpList(tester);

    await tester.drag(find.byType(ListView), const Offset(0, 40));
    await tester.pumpAndSettle();

    expect(down, 0);
  });

  testWidgets('scrolling within the content never fires', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, items: 40);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pumpAndSettle();

    expect(down + up, 0);
  });

  testWidgets('a fling that hits the top is not a pull', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, items: 40);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, 2000), 4000);
    await tester.pumpAndSettle();

    expect(down, 0);
  });

  testWidgets('each drag counts on its own', (WidgetTester tester) async {
    await pumpList(tester);

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(down, 2);
  });

  testWidgets('a direction with no action is left alone', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OverscrollGestures(
          onPullDown: () => down++,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[SizedBox(height: 100)],
          ),
        ),
      ),
    );
    down = 0;

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(down, 0);
  });
}
