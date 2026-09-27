# Testing & quality

Run all Flutter commands from the repo root.

## Definition of done
Before saying work is complete, run and report results of:
```
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
All must pass. If something can't be run (e.g. no device), say so explicitly; don't claim it works.
For UI/launcher behavior, also verify on a device or emulator with `flutter run` when possible.

## What to test
- **Unit tests (most tests live here)**: grid packing (every tile size, a row that doesn't fill, reordering), app matching and grouping for the drawer, each tile source's mapping from raw data to `TileContent`, layout persistence round-trips.
- **Widget tests**: the shell refuses to pop (back never exits), a tile renders at each size it supports, tapping a tile asks the repository to launch the right package, the drawer's alphabet index jumps to a letter.
- **No platform in tests**: use a `FakeAppRepository`. Do not call platform channels in unit/widget tests.
- Integration/on-device tests only for launcher-role behavior that can't be simulated; keep them few.

## Conventions
- Test file mirrors source path: `lib/model/tile_layout.dart` → `test/model/tile_layout_test.dart`.
- Arrange/act/assert; one behavior per test; names describe behavior (`'open prefers exact match over substring'`).
- Hand-written fakes over mocking libraries unless a mock clearly simplifies things.
- Write the failing test first for bugs; add a regression test with every fix.
- Tests must be deterministic: no wall-clock, network, or randomness without injection.
- Online features (once there are any) are tested with a fake fetcher and real responses saved in `test/fixtures/`. Never hit a live API from a committed test.
- `PageView`'s off-screen pages are still built (not lazily skipped), so a bare `find.text(...)` in `home_shell_test.dart` can match the same string in both the home grid and the drawer at once. Scope with `find.descendant(of: find.byType(AppTileGrid)/AppDrawer, matching: ...)` rather than asserting on the raw finder.

## Review checklist
- [ ] No logic in widgets; packing and matching live in `model/`
- [ ] Every controller/focus node/timer disposed
- [ ] `mounted` checked after awaits
- [ ] Works offline (no runtime font/asset downloads)
- [ ] Colours come from `ui/theme.dart`; no gradients, shadows or blur
- [ ] No new dependency without checking it's maintained
- [ ] Strings live in `messages.dart`
- [ ] Analyze clean, formatted, tests pass
