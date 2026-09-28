import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/styled_text.dart';
import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/model/tv_layout.dart';
import 'package:android_tile_launcher/ui/text_tv_screen.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tv_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

TextTvPage _page(
  int number, {
  List<List<String>>? parts,
  int? previous,
  int? next,
  List<List<List<StyledRun>>>? styled,
}) => TextTvPage(
  number: number,
  parts:
      parts ??
      <List<String>>[
        <String>['$number SVT Text', '', '  Rubrik $number'],
      ],
  styledParts: styled,
  previous: previous ?? number - 1,
  next: next ?? number + 1,
);

FakeTextTvRepository _repository([List<int> numbers = const <int>[]]) =>
    FakeTextTvRepository(<int, TextTvPage>{
      for (final int n in <int>[100, 101, 102, 104, 130, 300, 899, ...numbers])
        n: _page(n),
    });

Future<void> _open(
  WidgetTester tester,
  FakeTextTvRepository repository, {
  int start = 100,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () =>
              showTextTv(context, repository: repository, start: start),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder _number(String text) =>
    find.descendant(of: find.byKey(textTvNumberKey), matching: find.text(text));

void main() {
  group('opening', () {
    testWidgets('shows the start page, and its number', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository);

      expect(repository.requests, <(int, bool)>[(100, false)]);
      expect(_number('100'), findsOneWidget);
      // The plain text on the grid: one row for each line of the page.
      expect(find.byType(TvRow), findsNWidgets(3));
      expect(find.text(Messages.textTvTitle), findsOneWidget);
    });

    testWidgets('can start on any page', (WidgetTester tester) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository, start: 300);

      expect(repository.requests.first, (300, false));
      expect(_number('300'), findsOneWidget);
    });

    testWidgets('is over the whole screen, with a close button on top', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());

      final Rect screen = tester.getRect(find.byType(Scaffold).last);
      expect(screen, tester.getRect(find.byType(MaterialApp)));
      expect(
        tester.getTopLeft(find.byKey(textTvCloseKey)).dy,
        lessThan(screen.top + 100),
      );
    });

    testWidgets('the close button closes it', (WidgetTester tester) async {
      await _open(tester, _repository());

      await tester.tap(find.byKey(textTvCloseKey));
      await tester.pumpAndSettle();

      expect(find.byKey(textTvCloseKey), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('filling the screen', () {
    // A page of 24 plain rows, like a real one.
    FakeTextTvRepository fullPage() {
      final FakeTextTvRepository repository = _repository();
      repository.pages[100] = _page(
        100,
        parts: <List<String>>[
          <String>[
            '100 SVT Text',
            for (int i = 1; i < 24; i++) '  Rad $i i sidan',
          ],
        ],
      );
      return repository;
    }

    double pageHeight(WidgetTester tester) =>
        tester.widgetList<TvRow>(find.byType(TvRow)).length.toDouble() *
        tester.getSize(find.byType(TvRow).first).height;

    testWidgets('on a tall screen the rows grow to use the height', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _open(tester, fullPage());

      final double area = tester
          .getSize(find.byType(SingleChildScrollView).first)
          .height;
      final double cell = 400 * 0.995 / (40 + tvGutterCells);
      final double natural = cell * 1.6;

      expect(
        tester.getSize(find.byType(TvRow).first).height,
        greaterThan(natural * 1.2),
      );
      // Fills the room, or stops at its tallest row on a very tall screen.
      expect(pageHeight(tester), lessThanOrEqualTo(area + 0.5));
      expect(pageHeight(tester), greaterThan(area * 0.9));
    });

    testWidgets(
      'on a short screen the rows stay natural and the page scrolls',
      (WidgetTester tester) async {
        tester.view
          ..physicalSize = const Size(400, 420)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _open(tester, fullPage());

        final double cell = 400 * 0.995 / (40 + tvGutterCells);
        expect(
          tester.getSize(find.byType(TvRow).first).height,
          closeTo(cell * 1.6, 1),
        );
        final ScrollableState scroll = tester.state<ScrollableState>(
          find.descendant(
            of: find.byType(SingleChildScrollView).first,
            matching: find.byType(Scrollable),
          ),
        );
        expect(scroll.position.maxScrollExtent, greaterThan(0));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a headline row counts for two rows of height', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FakeTextTvRepository repository = _repository();
      repository.pages[100] = _page(
        100,
        parts: <List<String>>[
          <String>['100', 'HEAD', 'x'],
        ],
        styled: <List<List<StyledRun>>>[
          <List<StyledRun>>[
            <StyledRun>[StyledRun('title'.padRight(40))],
            <StyledRun>[StyledRun('headline'.padRight(40), tall: true)],
            <StyledRun>[StyledRun('  text row'.padRight(40))],
          ],
        ],
      );
      await _open(tester, repository);

      final double plain = tester.getSize(find.byType(TvRow).at(0)).height;
      final double tall = tester.getSize(find.byType(TvRow).at(1)).height;

      expect(tall, closeTo(plain * 2, 0.5));
    });
  });

  testWidgets('a colour bar is centred by its edges, the text by its words', (
    WidgetTester tester,
  ) async {
    final FakeTextTvRepository repository = _repository();
    // Text that leans right (blank cells left of it, none right of it), and a
    // bar across the whole width.
    final List<List<StyledRun>> rows = <List<StyledRun>>[
      <StyledRun>[StyledRun('100 SVT Text'.padRight(40))],
      <StyledRun>[StyledRun('  A headline that reaches the far edge!!')],
      <StyledRun>[
        StyledRun('    Inrikes 101 Utrikes 104 Innehåll 70', bg: TvColor.blue),
        const StyledRun('0', bg: TvColor.blue),
      ],
    ];
    repository.pages[100] = _page(
      100,
      parts: <List<String>>[
        <String>['100', 'x', 'y'],
      ],
      styled: <List<List<StyledRun>>>[rows],
    );
    await _open(tester, repository);

    final List<TvRow> drawn = tester
        .widgetList<TvRow>(find.byType(TvRow))
        .toList();

    // The text leans right, so it is drawn with less gutter on its left...
    expect(drawn[1].gutterLeft, 0);
    // ...and the bar with the same gutter on both sides.
    expect(drawn[2].gutterLeft, tvGutterCells ~/ 2);
  });

  group('going to another page', () {
    testWidgets('the arrows follow the pages the site names', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      repository.pages[100] = _page(100, previous: 100, next: 101);
      await _open(tester, repository);

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pumpAndSettle();
      expect(_number('101'), findsOneWidget);

      await tester.tap(find.byKey(textTvPrevKey));
      await tester.pumpAndSettle();
      expect(_number('100'), findsOneWidget);
    });

    testWidgets('there is no page after the last', (WidgetTester tester) async {
      final FakeTextTvRepository repository = _repository();
      repository.pages[899] = _page(899, next: 900);
      await _open(tester, repository, start: 899);
      final int before = repository.requests.length;

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pumpAndSettle();

      expect(repository.requests, hasLength(before));
      expect(_number('899'), findsOneWidget);
    });

    testWidgets('a shortcut opens its page', (WidgetTester tester) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository);

      await tester.tap(find.byKey(textTvChipKey(300)));
      await tester.pumpAndSettle();

      expect(_number('300'), findsOneWidget);
      expect(repository.requests.last, (300, false));
    });

    testWidgets('a tapped page number in the page opens that page', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      // A row of text with a link at cells 10 to 12, and a long row so the
      // page has something to lean on.
      final List<List<StyledRun>> rows = <List<StyledRun>>[
        <StyledRun>[StyledRun('100 SVT Text'.padRight(40))],
        <StyledRun>[
          StyledRun(' ' * 10),
          const StyledRun('130', underline: true, command: '130'),
          StyledRun(' ' * 27),
        ],
        <StyledRun>[
          StyledRun('  A long enough row of text to lean on'.padRight(40)),
        ],
      ];
      repository.pages[100] = _page(
        100,
        parts: <List<String>>[
          <String>['100', 'x', 'y'],
        ],
        styled: <List<List<StyledRun>>>[rows],
      );
      await _open(tester, repository);

      final ({int left, int right}) gutters = tvGutters(rows, columns: 40);
      final Rect row = tester.getRect(find.byType(TvRow).at(1));
      final double cell = row.width / (40 + tvGutterCells);
      await tester.tapAt(
        Offset(row.left + cell * (gutters.left + 11.5), row.center.dy),
      );
      await tester.pumpAndSettle();

      expect(_number('130'), findsOneWidget);
      expect(repository.requests.last, (130, false));
    });
  });

  group('the number pad', () {
    testWidgets('tapping the number shows a pad; three digits open a page', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository);
      expect(find.byKey(textTvDigitKey(5)), findsNothing);

      await tester.tap(find.byKey(textTvNumberKey));
      await tester.pump();
      expect(find.byKey(textTvDigitKey(5)), findsOneWidget);
      expect(_number('---'), findsOneWidget);

      await tester.tap(find.byKey(textTvDigitKey(1)));
      await tester.pump();
      expect(_number('1--'), findsOneWidget);
      await tester.tap(find.byKey(textTvDigitKey(0)));
      await tester.pump();
      expect(_number('10-'), findsOneWidget);
      await tester.tap(find.byKey(textTvDigitKey(4)));
      await tester.pumpAndSettle();

      expect(_number('104'), findsOneWidget);
      expect(repository.requests.last, (104, false));
      // The pad puts itself away once a page is chosen.
      expect(find.byKey(textTvDigitKey(5)), findsNothing);
    });

    testWidgets('a page number cannot start with 0 or 9', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());
      await tester.tap(find.byKey(textTvNumberKey));
      await tester.pump();

      await tester.tap(find.byKey(textTvDigitKey(0)));
      await tester.tap(find.byKey(textTvDigitKey(9)));
      await tester.pump();

      expect(_number('---'), findsOneWidget);
    });

    testWidgets('DEL takes back a digit', (WidgetTester tester) async {
      await _open(tester, _repository());
      await tester.tap(find.byKey(textTvNumberKey));
      await tester.pump();
      await tester.tap(find.byKey(textTvDigitKey(3)));
      await tester.tap(find.byKey(textTvDigitKey(0)));
      await tester.pump();

      await tester.tap(find.byKey(textTvDeleteKey));
      await tester.pump();

      expect(_number('3--'), findsOneWidget);
    });

    testWidgets('the X puts the pad away without going anywhere', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository);
      await tester.tap(find.byKey(textTvNumberKey));
      await tester.pump();

      await tester.tap(find.byKey(textTvKeypadCloseKey));
      await tester.pump();

      expect(find.byKey(textTvDigitKey(5)), findsNothing);
      expect(_number('100'), findsOneWidget);
      expect(repository.requests, hasLength(1));
    });

    testWidgets('a page number that is not in broadcast says so', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());
      await tester.tap(find.byKey(textTvNumberKey));
      await tester.pump();
      for (final int d in <int>[7, 7, 7]) {
        await tester.tap(find.byKey(textTvDigitKey(d)));
      }
      await tester.pumpAndSettle();

      expect(find.text(Messages.textTvPageNotBroadcast(777)), findsOneWidget);
    });
  });

  group('parts', () {
    FakeTextTvRepository withParts() {
      final FakeTextTvRepository repository = _repository();
      repository.pages[100] = _page(
        100,
        parts: <List<String>>[
          <String>['100 one', '', '  First'],
          <String>['100 two', '', '  Second', '  more'],
        ],
      );
      return repository;
    }

    testWidgets('a page with several parts says which one it is on', (
      WidgetTester tester,
    ) async {
      await _open(tester, withParts());

      expect(find.text('${Messages.textTvPart} 1/2'), findsOneWidget);
      expect(find.byType(TvRow), findsNWidgets(3));
    });

    testWidgets('the arrows step through them', (WidgetTester tester) async {
      await _open(tester, withParts());

      await tester.tap(find.byKey(textTvPartNextKey));
      await tester.pump();

      expect(find.text('${Messages.textTvPart} 2/2'), findsOneWidget);
      expect(find.byType(TvRow), findsNWidgets(4));

      await tester.tap(find.byKey(textTvPartPrevKey));
      await tester.pump();
      expect(find.text('${Messages.textTvPart} 1/2'), findsOneWidget);
    });

    testWidgets(
      'a swipe left reads on, and past the last part, to the next page',
      (WidgetTester tester) async {
        final FakeTextTvRepository repository = withParts();
        await _open(tester, repository);

        await tester.fling(
          find.byType(TvRow).first,
          const Offset(-300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.text('${Messages.textTvPart} 2/2'), findsOneWidget);

        await tester.fling(
          find.byType(TvRow).first,
          const Offset(-300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(_number('101'), findsOneWidget);
      },
    );

    testWidgets('a swipe right goes back a part, then to the previous page', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = withParts();
      await _open(tester, repository, start: 101);
      expect(_number('101'), findsOneWidget);

      await tester.fling(find.byType(TvRow).first, const Offset(300, 0), 1000);
      await tester.pumpAndSettle();

      expect(_number('100'), findsOneWidget);
    });

    testWidgets('a page of one part shows no part bar', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());

      expect(find.byKey(textTvPartNextKey), findsNothing);
    });
  });

  group('back', () {
    testWidgets('steps back through the pages read, then closes', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());
      await tester.tap(find.byKey(textTvChipKey(300)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(textTvChipKey(104)));
      await tester.pumpAndSettle();
      expect(_number('104'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_number('300'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_number('100'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(textTvCloseKey), findsNothing);
    });

    testWidgets('puts the number pad away first', (WidgetTester tester) async {
      await _open(tester, _repository());
      await tester.tap(find.byKey(textTvNumberKey));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(textTvDigitKey(5)), findsNothing);
      expect(find.byKey(textTvCloseKey), findsOneWidget);
    });
  });

  group('when a page cannot be shown', () {
    testWidgets('a failure says why, and TRY AGAIN reads it again', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository()
        ..failure = const TextTvFailed('no connection');
      await _open(tester, repository);
      expect(find.text('NO CONNECTION'), findsOneWidget);

      repository.failure = null;
      await tester.tap(find.byKey(textTvRetryKey));
      await tester.pumpAndSettle();

      expect(find.text('NO CONNECTION'), findsNothing);
      expect(find.byType(TvRow), findsNWidgets(3));
      // The second read insisted on the site.
      expect(repository.requests.last, (100, true));
    });

    testWidgets('REFRESH reads the page again from the site', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository);

      await tester.tap(find.byKey(textTvRefreshKey));
      await tester.pumpAndSettle();

      expect(repository.requests.last, (100, true));
    });

    testWidgets('a page not in broadcast says so, and the arrows still work', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository, start: 555);

      expect(find.text(Messages.textTvPageNotBroadcast(555)), findsOneWidget);

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pumpAndSettle();
      expect(repository.requests.last, (556, false));
    });
  });

  testWidgets('a page whose coloured version was sent is drawn from it', (
    WidgetTester tester,
  ) async {
    final FakeTextTvRepository repository = _repository();
    repository.pages[100] = _page(
      100,
      parts: <List<String>>[
        <String>['100', 'x'],
      ],
      styled: <List<List<StyledRun>>>[
        <List<StyledRun>>[
          <StyledRun>[StyledRun('title'.padRight(40))],
          <StyledRun>[
            StyledRun(
              'coloured'.padRight(40),
              fg: TvColor.yellow,
              bg: TvColor.blue,
            ),
          ],
        ],
      ],
    );
    await _open(tester, repository);

    expect(find.byType(TvRow), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
