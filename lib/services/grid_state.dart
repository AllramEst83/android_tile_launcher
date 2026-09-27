import 'package:flutter/foundation.dart';

/// Which apps are on the home mosaic, in pin order. In-memory only for now —
/// Phase 5 adds saving this to disk; Phase 6 lets the grid editor change a
/// tile's size and colour, not just whether it's on the grid at all.
class GridState extends ChangeNotifier {
  final List<String> _pinned = <String>[];

  /// Pinned package names, in the order they were pinned.
  List<String> get pinned => List.unmodifiable(_pinned);

  bool isPinned(String packageName) => _pinned.contains(packageName);

  void pin(String packageName) {
    if (_pinned.contains(packageName)) return;
    _pinned.add(packageName);
    notifyListeners();
  }

  void unpin(String packageName) {
    if (!_pinned.remove(packageName)) return;
    notifyListeners();
  }

  void toggle(String packageName) {
    if (isPinned(packageName)) {
      unpin(packageName);
    } else {
      pin(packageName);
    }
  }
}
