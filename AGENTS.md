# AGENTS.md

Tile-based Android launcher built with Flutter. The home screen is a scrolling mosaic of live tiles that show what they know (time, weather, next event, unread counts) and open the app behind them when tapped.
The look is Commodore-era: the VIC-II palette, hard edges, bevels instead of shadows.

## Layout
- Repo root (this dir) is the Flutter project: `lib/`, `test/`, `android/`, `pubspec.yaml`, plus `plan.md`, `AGENTS.md`, `CLAUDE.md`, `.agents/` — **run all `flutter`/`dart` commands here**
- Android app id: `com.codedbykay.android_tile_launcher`
- `design/` is reference material and the icon's sources, not code (see [design/README.md](design/README.md)): `reference/` is the look and feel, `mockups/` is structural inspiration only (its Fluent/acrylic styling is **not** the target look), `icon/` feeds `tool/make_app_icon.py`

## Read before working
Guidance lives in [`.agents/`](.agents/README.md). Start with the index, then:
- Any Dart/Flutter code → [.agents/flutter-best-practices.md](.agents/flutter-best-practices.md)
- New tile, screen or service → [.agents/architecture.md](.agents/architecture.md)
- Manifest, Kotlin, permissions, app listing → [.agents/android-launcher.md](.agents/android-launcher.md)
- Tests / finishing work → [.agents/testing-and-quality.md](.agents/testing-and-quality.md)
- What to build next → [plan.md](plan.md) (you may improve it; log changes in its changelog)

## Non-negotiables
1. `model/` logic is pure Dart and unit-tested; UI only renders state and forwards input.
2. Platform/app access only through `AppRepository`; never use the discontinued `device_apps`.
3. Must work offline: bundle fonts, no runtime downloads. A launcher draws itself at boot with no network.
4. Dispose every controller/focus node/timer; check `mounted` after awaits.
5. Colours come from the VIC-II palette in `lib/ui/theme.dart` and nowhere else. No gradients, drop shadows or blur: bevels, shine, scanlines and dither are flat, hard-edged shapes.
6. Before calling work done: `dart format`, `flutter analyze`, `flutter test` all clean.
7. Small steps: finish and verify one plan phase before starting the next.
