# Architecture

Goal: a tile-based Android launcher. A tile is **data** (what it is, how big, what colour, what it opens); a source fills it with current content; the grid draws it. Adding a tile kind must be additive — a new kind and its view, nothing else.

Only the files marked *planned* below are still to be written; the rest exist. Keep this list in step with `lib/` as phases land.

## Layers (dependency direction: UI → model → services → platform)

```
lib/
  main.dart                  # runApp only + DI wiring
  app.dart                   # MaterialApp, theme
  messages.dart              # user-facing strings
  model/                     # pure Dart: no Flutter, no platform      (planned)
    tile.dart                # Tile: id, kind, size, colour, target
    tile_size.dart           # small 1x1, medium 2x2, wide 4x2, large 4x4
    tile_layout.dart         # ordered tiles -> packed rows of the 4-column grid
    tile_content.dart        # what a tile shows now (sealed: text, metric, agenda, ...)
    app_matcher.dart         # search and grouping for the drawer
  services/                  # abstractions over the platform          (planned)
    app_info.dart            # AppInfo(label, packageName)
    app_repository.dart      # abstract: list launchable apps, launch(packageName)
    android_app_repository.dart  # MethodChannel implementation; caches, sorts, excludes self
    local_store.dart         # abstract: read/write JSON values by key
    tile_source.dart         # abstract: a stream of TileContent for one tile kind
  ui/
    theme.dart               # VIC-II palette, ThemeData, grid metrics
    home_shell.dart          # the launcher shell: PopScope, boot screen, later the grid
    tile_grid.dart           # the mosaic                              (planned)
    tile_view.dart           # one tile, dispatched by kind            (planned)
    app_drawer.dart          # the alphabet list                       (planned)
test/  # mirrors lib/; fakes/ holds FakeAppRepository
```

## Rules
1. **`model/` imports no Flutter and no platform code.** It depends on `services/` only through abstract interfaces passed in (constructor injection). This is what makes it fully unit-testable.
2. **A tile is data plus a view.** `Tile` says what it is, how big, what colour and what it opens. It never holds a widget, a `BuildContext` or a live subscription.
3. **Content is a value, not a side effect.** A `TileSource` yields `TileContent`; the grid renders whatever the latest value is. Sources never touch the UI and never launch anything.
4. **Packing is pure.** Turning an ordered list of tiles into rows of the 4-column grid happens in `model/tile_layout.dart` and is unit-tested. Widgets lay out what they are given.
5. **Platform access goes through `AppRepository`.** Fake it in tests. Swapping the underlying package/channel must touch exactly one file.
6. **Dependency injection by constructor**; wire everything in `main.dart`. No service locators or singletons/globals.
7. **Widgets only render state and forward taps.** No matching, packing or app-launching in widgets.
8. Cache the installed-app list in the repository (with an explicit refresh); don't re-query the OS on every keystroke.
9. **Colour comes from `ui/theme.dart` only.** Sixteen VIC-II colours, nothing mixed, nothing interpolated.

## Adding a tile kind
1. A value in the tile-kind enum and, if it has its own shape of content, a case in `TileContent`.
2. A `TileSource` for it in `services/`, behind an abstract interface, with a fake in `test/fakes/`.
3. A view in `ui/`, dispatched from `tile_view.dart`.
4. Unit tests for the source and the content shape; a widget test for the view at each size it supports.
No changes to the grid, the packer or the shell should be needed. If they are, the abstraction is leaking; fix that first.

## The look
The reference is `design/commodore64/`: the C64 screen (light blue on blue), beige-and-brown hardware, the rainbow stripe, chunky bevels, pixel type.
- Hard edges. `TileMetrics.radius` is 0 and stays 0 unless the user asks otherwise.
- Depth is a 2px bevel (light top-left, dark bottom-right), never a shadow, gradient or blur.
- `design/google.stich/` is **structure only** — which screens exist and what is on them. Its acrylic frost, 12px radii, Inter type and Fluent palette are explicitly not the target; `metro_flow/DESIGN.md` is read for layout and component inventory, not for styling.

## Decisions log
Record decisions that future agents can't derive from code (append, newest last):
- State management: plain `ChangeNotifier`; no package. (Revisit only if multiple screens/shared async state appear.)
- App access will be hidden behind `AppRepository` because `device_apps` is discontinued; a small `MethodChannel` in `MainActivity.kt` is preferred over a package.
- Palette is limited to the sixteen VIC-II colours (Pepto calibration) in `ui/theme.dart`. The limit is the design: a tile picks a colour from the sixteen or it does not get one.
- The launch window colour (`android/app/src/main/res/values/colors.xml`, `launch_canvas`) duplicates `TileColors.canvas` so the launcher never flashes a different colour on start. Change both together.
- Launch theme is `Theme.Black.NoTitleBar` in both `values/` and `values-night/`: the launcher's look does not follow the OS dark-mode setting.
- No pixel font is bundled yet, so the theme uses the platform monospace face. Choosing one is a licence decision for the user (see plan.md, Phase 1.1); it must be bundled as an asset, never fetched at runtime.
