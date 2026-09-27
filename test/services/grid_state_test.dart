import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with nothing pinned', () {
    expect(GridState().pinned, isEmpty);
  });

  test('pin adds a package, in pin order', () {
    final state = GridState();

    state.pin('pkg.clock');
    state.pin('pkg.maps');

    expect(state.pinned, ['pkg.clock', 'pkg.maps']);
    expect(state.isPinned('pkg.clock'), isTrue);
    expect(state.isPinned('pkg.other'), isFalse);
  });

  test('pinning an already-pinned package is a no-op', () {
    final state = GridState();
    var notifications = 0;
    state.addListener(() => notifications++);

    state.pin('pkg.clock');
    state.pin('pkg.clock');

    expect(state.pinned, ['pkg.clock']);
    expect(notifications, 1);
  });

  test('unpin removes a package', () {
    final state = GridState()..pin('pkg.clock');

    state.unpin('pkg.clock');

    expect(state.pinned, isEmpty);
    expect(state.isPinned('pkg.clock'), isFalse);
  });

  test('unpinning something not pinned does not notify', () {
    final state = GridState();
    var notifications = 0;
    state.addListener(() => notifications++);

    state.unpin('pkg.clock');

    expect(notifications, 0);
  });

  test('toggle flips membership', () {
    final state = GridState();

    state.toggle('pkg.clock');
    expect(state.isPinned('pkg.clock'), isTrue);

    state.toggle('pkg.clock');
    expect(state.isPinned('pkg.clock'), isFalse);
  });

  test('pinned is unmodifiable', () {
    final state = GridState()..pin('pkg.clock');

    expect(() => state.pinned.add('pkg.maps'), throwsUnsupportedError);
  });
}
