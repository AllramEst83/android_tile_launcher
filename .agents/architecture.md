# Architecture

Goal: a tile-based Android launcher. A tile is **data** (what it is, how big, what colour, what it opens); a source fills it with current content; the grid draws it. Adding a tile kind must be additive — a new kind and its view, nothing else.

Only the files marked *planned* below are still to be written; the rest exist. Keep this list in step with `lib/` as phases land.

## Layers (dependency direction: UI → model → services → platform)

```
lib/
  main.dart                  # runApp only + DI wiring
  app.dart                   # MaterialApp, theme
  messages.dart              # user-facing strings
  model/                     # pure Dart: no Flutter, no platform
    c64_colour.dart          # C64Colour: selects a VIC-II colour without importing Flutter
    tile.dart                # Tile: id, kind, size, colour, appPackage; TileKind (one value so far: app)
    tile_size.dart           # small 1x1, medium 2x2, wide 4x2, large 4x4
    tile_layout.dart         # packTiles: ordered tiles -> PlacedTile (column, row); skyline algorithm
    default_tiles.dart       # tilesForApps: the starting layout before Phase 5 (persistence) exists
    tile_content.dart        # what a live tile shows now (sealed: text, metric, agenda, ...)  (planned, Phase 7)
    alpha_grouping.dart      # groupByInitial<T>: any labelled list -> initial-letter buckets, shared by the app drawer (Phase 4) and the contacts tile (Phase 10)  (planned, Phase 4)
    app_matcher.dart         # app-specific search (label/package matching) for the drawer  (planned, Phase 4)
  services/                  # abstractions over the platform
    app_info.dart            # AppInfo(label, packageName)
    app_repository.dart      # abstract: list launchable apps, launch(packageName)
    app_repository_exception.dart
    android_app_repository.dart  # MethodChannel implementation; caches, sorts, excludes self
    local_store.dart         # abstract: read/write JSON values by key      (planned)
    tile_source.dart         # abstract: a stream of TileContent for one tile kind  (planned)
  ui/
    theme.dart               # VIC-II palette, ThemeData, grid metrics, C64Colour -> (fill, ink)
    home_shell.dart          # the launcher shell: PopScope, boot/loading/error state
    app_tile_grid.dart       # apps -> default tiles -> packed layout; empty state; pull-to-refresh
    tile_grid.dart           # renders a packed layout Positioned by cell size; never packs itself
    tile_view.dart           # one tile: VIC-II fill, 2px bevel, glyph, bottom-left label
    app_drawer.dart          # the alphabet list                       (planned, Phase 4)
android/app/src/main/kotlin/com/codedbykay/android_tile_launcher/
  MainActivity.kt            # wires channel handlers into the Flutter engine
  AppsChannelHandler.kt      # list launchable apps, launch one; runs off the main thread
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
- Pixel font: **Press Start 2P** (OFL 1.1), bundled at `fonts/PressStart2P-Regular.ttf` with `fonts/OFL.txt`, named by the single constant `kPixelFontFamily` in `ui/theme.dart`. A C64 face (`C64 Pro Mono`) was rejected: it is free for non-commercial use, but its licence separately forbids "provid[ing] the font for direct download from any web site," which a public GitHub repo does via raw file URLs regardless of the app's own licence. Revisit only if the repo becomes private.
- `AndroidAppRepository`'s `MethodChannel` is a named constructor parameter (`channel`), not `this._channel`: an initializing formal would make the parameter name the private `_channel`, which a test file (a different library) cannot pass by name. The `prefer_initializing_formals` lint is silenced at that line for this reason.
- `AppRepository` has no `uninstall` method yet. It is added when the drawer's quick actions land (Phase 4) — permissions and interface methods are added when the feature that needs them lands, not ahead of time.
- The boot screen (`_BootScreen` in `home_shell.dart`) doubles as the app list's loading and error state, rather than being a separate splash step. It is genuinely how the launcher starts every time: apps load, then the list (later the grid) replaces it.
- Alphabetical grouping (A–Z, then Å Ä Ö) is a generic `groupByInitial<T>` in `model/alpha_grouping.dart`, keyed by a label extractor, not an app-specific function — the drawer (Phase 4) and the contacts tile (Phase 10) call the same code. Built when Phase 4 needs it, not before; the Swedish-collation-or-plain-A–Z choice is still an open question in plan.md.
- `packTiles` uses a skyline (per-column heightmap) algorithm, not one full-width row per tile: it tracks the next free row of each column and places each tile in the leftmost gap that lets it sit highest, so a short tile doesn't leave a hole under a taller neighbour. Chosen over simpler row-based packing because Phase 6's grid editor will mix tile sizes freely, and a real mosaic look needs tiles to interlock rather than stack one-per-row.
- `Tile` keeps a `TileKind` field with a single value (`app`) rather than dropping the discriminator until a second kind exists: the approved plan already commits to clock/weather (Phase 7), an agenda (Phase 9), contacts (Phase 10) and more, so the one-line cost now avoids a breaking change to every existing `Tile` call site later.
- The Phase 3 default layout (`default_tiles.dart`) gives every app a uniform `TileSize.small` — dense and uniform, not varied sizes — because there is no drawer yet (Phase 4): this grid is the only way to reach any app, so showing as many as possible densely matters more than mosaic variety. Phase 6's editor is what introduces different sizes, chosen by the user.
- A tile's bevel is two `BorderSide`s lightened/darkened from its own fill by `Color.lerp` (not a fixed light/dark grey), so every VIC-II colour gets a bevel that still reads as "the same colour, raised" rather than a generic frame.
