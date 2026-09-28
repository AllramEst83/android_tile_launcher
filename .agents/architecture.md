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
    tile.dart                # Tile: id, kind, size, colour; TileKind (app, clock, soundMode, flashlight); launchTargetOf, displayNameOf, tileKindNamed
    tile_size.dart           # small 1x1, medium 2x2, wide 4x2, large 4x4
    tile_layout.dart         # packTiles: ordered tiles -> PlacedTile (column, row); skyline algorithm
    pinned_tile.dart         # PinnedTile: id + kind + size + colour, JSON (de)serialisable; PinnedTile.app/.system factories; pinnableColours, the fill cycle
    list_reorder.dart        # moveItem<T>: pure ReorderableListView-style index move, for drag-to-reorder
    sound_mode.dart          # SoundMode (normal/vibrate/silent): the ringer, with its tap cycle and label
    tile_content.dart        # what a live tile shows now (sealed: ClockContent, SoundContent, ToggleContent)
    clock_format.dart        # formatClockTime/formatClockDate: DateTime -> the tile's display strings
    alpha_grouping.dart      # groupByInitial<T>: any labelled list -> initial-letter buckets (Swedish order); shared by the app drawer and the contacts tile (Phase 11)
    app_matcher.dart         # rankApps: best-match-first search ranking, for the drawer's search field
  services/                  # abstractions over the platform
    app_info.dart            # AppInfo(label, packageName)
    app_repository.dart      # abstract: list/launch/uninstall/openAppDetails
    app_repository_exception.dart
    android_app_repository.dart  # MethodChannel implementation; caches, sorts, excludes self
    grid_state.dart          # ChangeNotifier: pinned PinnedTiles, in pin order; pin/pinSystemTile/unpin/toggle/replaceAll, persisted via LocalStore
    local_store.dart         # abstract: read/write JSON values by key
    local_store_exception.dart
    shared_preferences_local_store.dart  # LocalStore on shared_preferences, one JSON string per key
    tile_source.dart         # abstract: Future<TileContent> read(), for one tile kind
    clock_tile_source.dart   # ClockTileSource: pure, DateTime.now() by default, injectable for tests
    system_control_service.dart      # abstract: soundMode/setSoundMode (ringer), isOn/setOn(TileKind) (torch)
    android_system_control_service.dart  # MethodChannel implementation
    toggle_tile_source.dart  # ToggleTileSource: one TileSource for the two-state kind (flashlight)
    sound_mode_tile_source.dart  # SoundModeTileSource: the ringer's current mode
  ui/
    theme.dart               # VIC-II palette, ThemeData, grid metrics, C64Colour -> (fill, ink)
    home_shell.dart          # the launcher shell: PopScope, boot/loading/error state, the PageView (home, drawer), "+ ADD TILE"
    app_tile_grid.dart       # tiles -> packed layout; caller-supplied empty state; pull-to-refresh; long-press to edit
    tile_grid.dart           # layoutTiles/gridHeight (shared pixel math) + renders a packed layout; never packs itself
    tile_view.dart           # chrome shell (fill, bevel/selection, delete badge) + tileContent(tile) dispatcher + AppTileContent
    tile_poller.dart         # TilePoller: rebuilds from a TileSource on an interval, paused while backgrounded; builder gets a refreshNow to re-read early
    clock_tile_view.dart     # ClockTileContentView: the clock's content -- time large, date small
    state_tile_view.dart     # StateTileContentView: label + a state string ([ON], [VIBRATE]...), nullable onTap
    editable_tile_grid.dart  # the grid editor's canvas: Draggable/DragTarget per tile, tap to select, delete badge
    tile_inspector.dart      # the editor's panel: label + Apply always, size/colour pickers while a tile is selected
    add_tile_sheet.dart      # "+ ADD TILE": every system kind not already pinned, one instance each
    app_drawer.dart          # All Apps: alphabetical + jump index, or a ranked flat list while searching
    quick_actions_sheet.dart # long-press sheet: pin/unpin, app details, uninstall
android/app/src/main/kotlin/com/codedbykay/android_tile_launcher/
  MainActivity.kt            # wires channel handlers into the Flutter engine
  AppsChannelHandler.kt      # list/launch/uninstall/openAppDetails; listing runs off the main thread
  SystemControlChannelHandler.kt  # ringer mode, torch
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
1. A value in `TileKind`, and if it has a launch target update `launchTargetOf`; a case in `TileContent` if it has live content at all (a kind can have none — an app tile doesn't).
2. If it's a live tile, a `TileSource` for it (`services/`, behind the abstract interface, with a fake in `test/fakes/`); wrap it in a `TilePoller` at whatever interval suits it.
3. A content view in `ui/`, wired into the `tileContent(tile, {labelFor})` dispatcher in `tile_view.dart` — the one place that switches on kind.
4. If it can be pinned by the user (not every kind has to be — nothing stops a future kind that's always present), add a `PinnedTile` factory for it and a case in `GridState`/`add_tile_sheet.dart`.
5. Unit tests for the source and the content shape; a widget test for the view at each size it supports.
No changes to `TileGrid`, `EditableTileGrid`, `packTiles` or `HomeShell` should be needed — they all dispatch through `tileContent`/`launchTargetOf`/`PinnedTile`, never on `kind` directly. If a change there turns out to be needed, the abstraction is leaking; fix that first.

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
- `AndroidAppRepository`'s `MethodChannel` and `GridState`'s `LocalStore` are both named constructor parameters (`channel`, `store`), not `this._channel`/`this._store`: an initializing formal would make the parameter name the private field name, which a test file (a different library) cannot pass by name. The `prefer_initializing_formals` lint is silenced at each for this reason — the pattern repeats whenever a class takes a swappable collaborator by name.
- `uninstall`/`openAppDetails` were added to `AppRepository` only once the drawer's quick actions (Phase 4) needed them, not ahead of time — the pattern this repo follows for every permission and interface method.
- The boot screen (`_BootScreen` in `home_shell.dart`) doubles as the app list's loading and error state, rather than being a separate splash step. It is genuinely how the launcher starts every time: apps load, then the list (later the grid) replaces it.
- Alphabetical grouping (A–Z, then Å Ä Ö) is a generic `groupByInitial<T>` in `model/alpha_grouping.dart`, keyed by a label extractor, not an app-specific function — the drawer and the contacts tile (Phase 11) call the same code, ported from the sibling terminal launcher's `terminal/tools/alphabet.dart`. The user chose Swedish order over plain A–Z when Phase 4 needed the answer.
- `packTiles` uses a skyline (per-column heightmap) algorithm, not one full-width row per tile: it tracks the next free row of each column and places each tile in the leftmost gap that lets it sit highest, so a short tile doesn't leave a hole under a taller neighbour. Chosen over simpler row-based packing because Phase 6's grid editor will mix tile sizes freely, and a real mosaic look needs tiles to interlock rather than stack one-per-row.
- `Tile` keeps a `TileKind` field with a single value (`app`) rather than dropping the discriminator until a second kind exists: the approved plan already commits to a clock (Phase 7), a device tile (Phase 8), weather (Phase 9), an agenda (Phase 10), contacts (Phase 11) and more, so the one-line cost now avoids a breaking change to every existing `Tile` call site later.
- The Phase 3 default layout (`default_tiles.dart`) gives every app a uniform `TileSize.small` — dense and uniform, not varied sizes — because there is no drawer yet (Phase 4): this grid is the only way to reach any app, so showing as many as possible densely matters more than mosaic variety. Phase 6's editor is what introduces different sizes, chosen by the user.
- A tile's bevel is two `BorderSide`s lightened/darkened from its own fill by `Color.lerp` (not a fixed light/dark grey), so every VIC-II colour gets a bevel that still reads as "the same colour, raised" rather than a generic frame.
- The home page became a curated subset once the drawer existed to reach everything else: `GridState` (a `ChangeNotifier`) holds an ordered list of pinned package names; home starts empty and grows only by pinning from the drawer. Phase 5 persisted the same list to disk (`LocalStore`) without changing its shape.
- `GridState` lives in `services/`, not `model/`, even though it holds no platform code: it's a `ChangeNotifier` (from `package:flutter/foundation.dart`), and `model/` stays free of any Flutter import so it can be unit-tested with zero widget bindings. `services/` already sets the precedent (`android_app_repository.dart` wraps a channel; `grid_state.dart` wraps a `LocalStore`, but both are shared, injected, observable state).
- `GridState.pin`/`unpin`/`toggle` mutate in-memory state and `notifyListeners()` synchronously, *then* return the `Future<void>` from saving — mirroring the sibling repo's `ThemeController.select`. A save that fails still leaves the pin in effect for this run; only the returned future throws. Callers that don't need to react to a save failure use `unawaited(...)` with a one-line reason (see `quick_actions_sheet.dart`), which the `unawaited_futures` lint otherwise flags.
- `main()` is `async` and awaits `GridState.load()` before `runApp`, rather than loading inside a widget: the saved grid is small and local, so blocking the first frame on it avoids a "nothing pinned" flash before the real layout appears. Contrast with the app list, which loads after first frame (its own `_BootScreen`/`FutureBuilder`) because a platform channel query is slower and more failure-prone than reading one `SharedPreferences` key.
- `LocalStore`/`LocalStoreException`/`SharedPreferencesLocalStore` are ported verbatim from the sibling terminal launcher (down to `InMemoryLocalStore` and the shared `localStoreContract` test suite), since the storage problem — durable JSON under a string key, values never stale — is identical.
- The drawer's search field shows a flat list ranked best-match-first (`rankApps`), not the alphabetical grouping, while there is a query: ranking and alphabetising are different orders, and grouping search hits by initial would bury the best match wherever its letter happens to sort.
- The jump index scrolls proportionally (`index / (groupCount - 1)` of `ScrollPosition.maxScrollExtent`), not `Scrollable.ensureVisible` on a per-section `GlobalKey`: the `ListView`'s sliver only builds sections near the viewport, so a distant section's `GlobalKey.currentContext` is null until it's already scrolled close — `ensureVisible` silently no-ops for exactly the far-away letters a jump index exists to reach. The `_JumpIndex` widget itself now hands back the tapped/dragged row's index (not the letter), since the letter is no longer enough to compute a scroll target.
- `_JumpIndex` (right edge of the drawer) is a `StatefulWidget`: `onTapDown`/`onVerticalDragUpdate`/`onVerticalDragStart` all route through one `_handleAt(localY)`, so a drag scrubs through every row it passes over exactly like a tap on each in turn, with a 2px bar tracking `_active` so a fast scrub still shows where the finger is.
- Tapping "Uninstall" in the quick-actions sheet calls `AppRepository.uninstall` directly, with no extra in-app confirmation: `uninstall` only ever opens Android's own uninstall dialog (`ACTION_DELETE`), which is itself the confirmation.
- `default_tiles.dart`/`tilesForApps` (Phase 3's placeholder, cycling colour by index on every render) is retired. `GridState` now stores a `PinnedTile` — id, kind, size, colour — per pinned tile; `PinnedTile.app`/`.system` run the same cycling logic exactly once, at pin time, so a tile's size/colour is a real user-changeable fact instead of being re-derived from list position on every rebuild.
- The grid editor (long-press a home tile) stages every change — reorder, resize, recolour, delete — on a local scratch `List<PinnedTile>` inside `_HomePageState`, never touching `GridState` until "Apply" calls `GridState.replaceAll`. "Cancel" just discards the scratch copy. This is what makes Apply/Cancel possible without `GridState` needing any notion of a pending transaction.
- Reordering is drag-a-tile-onto-another, not a `ReorderableListView` (which only handles linear lists): each tile is both a `Draggable<String>` (its `id`) and a `DragTarget<String>`, and dropping one onto another calls the pure `moveItem` with their scratch-list indices. `Draggable.feedback` renders in the root `Overlay`, outside this tree's `Material` ancestor, so it's wrapped in its own `Material(type: MaterialType.transparency)` — otherwise `TileView`'s `InkWell` throws "No Material widget found" the moment a drag starts.
- Long-pressing empty canvas space does *not* enter the editor, only long-pressing an existing tile does (which also selects it, matching the Stitch mockup's flow) — simpler than wiring a second gesture target, and there is nothing to edit on a grid with zero tiles anyway. Likewise, back-press does not cancel an in-progress edit (only the explicit Cancel button does): wiring that through `PopScope`, which lives two widgets up in `HomeShell`, was judged not worth it for this phase.
- `_HomePageState`'s scratch copy does not defend against `GridState` changing underneath it while editing (e.g. pinning something from the drawer via the same `PageView`, mid-edit, by swiping without applying/cancelling first). Accepted as a rare-enough edge case rather than lifting edit state up to disable `PageView` swiping.
- `Positioned`'s `key: ValueKey(tile.id)` belongs on the `Positioned` itself (the direct child of `Stack`), not nested one level down on the `TileView` inside it — only a multi-child widget's *direct* children are matched by key across rebuilds. This only started to matter once tile order could change at runtime (drag-to-reorder); `tile_grid.dart` and `editable_tile_grid.dart` both key the `Positioned`.
- Apply lives in `TileInspector`'s label row (bottom of the screen, one-handed reach), not the top `_EditorBar` with Cancel: reaching the top of a phone screen mid-edit was the user's own complaint after trying Phase 6. `TileInspector` renders unconditionally now (label blank, size/colour pickers hidden) so deleting the selected tile — which clears the selection — can never strand Apply off-screen.
- `Tile.appPackage` is gone; `Tile`/`PinnedTile` now key everything off a kind-agnostic `id` (a package name for `TileKind.app`, a fixed name like `"clock"` for a system kind — there is at most one of each, so the kind's own `.name` is a perfectly good id). `launchTargetOf(tile)` is the pure derivation of "what to launch, if anything" from `id`/`kind`; `TileGrid` only wires `onTap` when it returns non-null, so a system tile simply isn't tappable outside the editor (its `onLongPress`/select/delete/drag paths are unaffected — those always use `id`, never `launchTargetOf`).
- Device (Phase 8), needing its own platform channel, was split out of what the plan originally called "Phase 7, clock and device" — see plan.md's changelog. This phase only ever had to solve the clock, which needs no platform code at all.
- There is no auto-seeded tile: the plan's first draft would have put a clock on the grid the first time this phase ran, but the user asked for a real "add tile" entry point instead, even though it's more scope now. `add_tile_sheet.dart` lists every `TileKind` but `app` that isn't already pinned; tapping one calls `GridState.pinSystemTile`. It is deliberately generic over `TileKind`, not hard-coded to clock, so Phase 8's device tile is one more sheet entry, not a second sheet.
- `TileView` stopped taking a `Tile` + `label` and taking a `colour` + `content: Widget` instead: the chrome (fill, bevel, selection outline, delete badge) is identical for every kind, but what goes *inside* it (a glyph and a label for an app; a big numeral and a small date for a clock) is not, and hard-coding "glyph from label's first letter" into the shared shell would have made every future kind fight that assumption. `tileContent(tile, {labelFor})` in `tile_view.dart` is the one dispatch point "Adding a tile kind" asks for; `TileGrid`/`EditableTileGrid` call it and never branch on `kind` themselves.
- A live tile's ticking timer and `AppLifecycleState` observer live in a single reusable `TilePoller` widget (`ui/tile_poller.dart`), not duplicated per kind or hoisted into a `ChangeNotifier` service: it's pure widget lifecycle (mount/unmount, resumed/paused), which is a natural fit for `State`, and keeping it in `ui/` means a kind's `TileSource` stays platform-and-widget-free. `ClockTileSource` polls every 30 seconds — a home-screen clock showing minutes doesn't need per-second updates, and per-second would poll it needlessly while the screen is simply sitting there.
- `ClockTileSource` takes an injectable `now` (`DateTime Function()`, defaulting to `DateTime.now`) precisely so its tests, and `TilePoller`'s, never touch the wall clock — the same pattern `date_command.dart`'s `context.now()` uses in the sibling repo.
- `TileContent` stayed a real `sealed class` (one case, `ClockContent`, so far) rather than being deferred until a second kind existed, unlike `TileKind` earlier: a test needing a second `TileContent` for `TilePoller`'s tests would have had to fake one anyway, and `ClockContent`'s two plain strings are also exactly what `test/services/clock_tile_source_test.dart` and `test/ui/tile_poller_test.dart` reuse to avoid inventing a throwaway type.
- Sound (ringer) and flashlight tiles. The two-state kind (flashlight) uses `ToggleTileSource`/`ToggleContent`; the ringer is three-way so it has its own `SoundModeTileSource`/`SoundContent`. Both render through one `StateTileContentView` (label + a state string). `SystemControlService` has `soundMode`/`setSoundMode` plus `isOn`/`setOn(TileKind, bool)`. (First attempt modelled silent and vibrate as two independent toggles; the user corrected that — the ringer is one state that can only be normal, vibrate or silent, so one tile cycles it.)
- `TileSource.read()` became `Future<TileContent> read()` (was synchronous) specifically because the toggle kinds' state lives on the platform side and must be queried through a channel; `ClockTileSource.read()` just wraps its already-synchronous body in `async` to satisfy the interface — it does no real awaiting. `TilePoller` grew a matching `TileContent?` (was non-nullable `late`) so it can render nothing for the one frame before the first read resolves, and its `initState` fires the first read with `unawaited(...)` instead of blocking.
- `TilePoller.builder` grew a third argument, `refreshNow` — a toggle tile's own tap flips the platform state then wants to show the new value immediately, not wait up to `interval` for the next tick. Adding this to the shared widget (available to every kind, even though only the toggle kinds use it yet) was simpler than giving toggle tiles a second, near-duplicate poller.
- There is no Do Not Disturb tile (tried, removed at the user's request). Android couples DND to the ringer: `AudioManager.setRingerMode(RINGER_MODE_SILENT)` from an app is treated as "turn DND on" (alarms-only) and leaves the internal ringer at vibrate — confirmed on the user's phone, where the tile said silent while the status bar showed DND and the volume panel showed the vibrate icon, never the crossed bell. So `setSoundMode(silent)` reaches silent the way the volume rocker does: go to vibrate, then `adjustStreamVolume(STREAM_RING, ADJUST_LOWER)`. Normal and vibrate use `setRingerMode`, which has no DND side effect. There is deliberately no fallback to `setRingerMode(SILENT)` — it would reintroduce the DND side effect. The tile cycles normal → vibrate → silent → normal and shows the reported ringer mode. Unverified beyond this phone: whether `adjustStreamVolume` reaches silent on every OEM/version.
- Entering or leaving silent needs Android's notification-policy access (`NotificationManager.isNotificationPolicyAccessGranted()`) — a special permission granted only through a Settings screen, never a runtime dialog, and not the same as declaring `ACCESS_NOTIFICATION_POLICY` in the manifest (which only lets the app ask). `SystemControlChannelHandler.withPolicyAccess` checks it (only for transitions that need it) and, if not granted, opens `ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS` instead of throwing — the same best-effort, no-error-surface contract every other platform action in this app follows. Previously pinned `silentMode`/`vibrationMode`/`doNotDisturb` tiles no longer parse (`PinnedTile.fromJson` drops unknown kinds) and vanish from the saved grid.
- The flashlight tile uses `CameraManager.setTorchMode`, not `Camera.open()`/a `CAMERA` permission: torch-only control was explicitly carved out to not need it, so the tile never triggers a runtime permission prompt. A registered `CameraManager.TorchCallback` keeps the Kotlin side's cached `torchOn` correct if the torch is toggled from outside the app (quick settings), since `setTorchMode` itself has no getter.
- `tileContent()` grew two new required-ish parameters — `systemControl: SystemControlService` and `interactive: bool = true` — the one deliberate exception to "no changes to `TileGrid`/`EditableTileGrid` needed" for a new kind: a toggle kind is the first kind whose view needs a genuinely new collaborator (not just `labelFor`), so threading it through `TileGrid`/`AppTileGrid`/`EditableTileGrid`'s constructors was unavoidable. `interactive: false` in `EditableTileGrid` stops a toggle tile's own tap zone from fighting the outer `TileView`'s tap-to-select — outside the editor (`TileGrid`, home), it defaults to `true` and the tile itself handles the tap since `launchTargetOf` is `null` for every system kind anyway.
