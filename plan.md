# Tile Launcher — Plan

Goal: an Android home-screen launcher made of live tiles, so the user rarely has to leave it. The structure is a four-column mosaic of 1×1, 2×2, 4×2 and 4×4 tiles (see `design/mockups/`); the look is Commodore-era (see `design/reference/`): light blue on C64 blue, the sixteen VIC-II colours, hard edges, bevels instead of shadows.

Guidance for agents: [AGENTS.md](AGENTS.md) and [.agents/](.agents/README.md). Each step ends with `dart format`, `flutter analyze`, `flutter test` clean, `flutter build apk --debug` after touching `android/`, and — where it touches the phone — a device check. Small steps: finish and verify one before starting the next.

Phases 0–24 (foundation through the app itself being feature-complete: apps, mosaic, drawer, persistence, grid editor, clock, device tile, weather, agenda, people, mail, Text TV, calc/convert, alarms, settings, wallpaper, and several rounds of visual/UI polish) are done and archived in [.agents/archive/plan-phases-0-24.md](.agents/archive/plan-phases-0-24.md), along with their full changelog. This file now starts a fresh round of phases from the user's latest notes.

The sibling repo `../android_terminal_launcher` already solves some of these problems (weather, mail, calendar, contacts, Text TV) in pure-Dart services worth reading before inventing a solution here, but its presentation never transfers — there is no command line here.

## Next, in order

Each phase gets designed in detail only when it's reached; this is an outline so the order is agreed up front. Small, independent phases can be reordered without much cost — ask if a different order would be more useful before starting.

25. ~~**Grid editor: easier drag placement.**~~ **Done.** A held tile's target is split by its own diagonals into four triangles (left/right/top/bottom), so hovering near any edge of a tile shows an insertion marker on that side — a horizontal line above/below stacks the tile into another row, not just beside its target. Each tile's drop area now also reaches half a gutter's width past its own edges, meeting its neighbours halfway across the gutter, so the marker appears while crossing the gutter rather than only once fully over the next tile. `moveBeside`'s before/after model is unchanged; only which edge maps to which (and the marker's orientation) is new. 1247 tests total (+9), format/analyze clean; not yet checked on a phone.
26. ~~**Grid editor: more tile size options.**~~ **Done.** Four new sizes alongside the original small (1×1), medium (2×2), wide (4×2) and large (4×4): flat (2×1), tall (1×2), broad (3×2) and tower (2×4). `TileSize` gained a `fullWidth` flag (only `wide`/`large` set it) so `spanIn` scales a size to the full mosaic width or clamps it to its own column count, generically rather than by a per-case switch. The packer (`packTiles`) already worked for any span/row combination, so no changes there; the inspector's resize row became a `Wrap` so eight buttons don't overflow a phone-width panel. Serialisation (`PinnedTile.toJson`/`fromJson`, layout export/import) is already name-keyed off `TileSize.values`, so the new sizes needed no format change. 1251 tests total (+13), format/analyze clean; not yet checked on a phone.
27. ~~**Font scaling.**~~ **Done.** A FONT SIZE section in Settings (SMALL/NORMAL/LARGE/EXTRA LARGE, the same selection-box style as GAP BETWEEN TILES) with a live preview line. Applied as one `MediaQuery.textScaler` override in `app.dart`'s `MaterialApp.builder`, *composed* with whatever ambient scaler is already there rather than replacing it, so the setting only ever adds to — never removes — the phone's own OS-level accessibility text size. This reaches every ordinary `Text` widget for free, plus the couple of manual `TextPainter`s (`TvRow`, a Text TV page's own fixed 40-column grid; `text_tv_tile_view.dart`) that were already written to read the ambient scaler, without a single call site touched. Found in the process, out of scope here and tracked as #35: several tile content views (the clock among them) already overflow a one-row-tall tile (`TileSize.small`/`flat`) at a realistic phone width, independently of font scale — it reproduces at NORMAL too, so it predates both this phase and Phase 26. 1261 tests total (+10), format/analyze clean; not yet checked on a phone.
28. **Alarm tile fix.** Stop showing a static "00:00". Decide and build the right always-current state to show — plain "ALARM" label, or the next upcoming alarm's time, or a summary of all set alarms — which may need reading alarms via `AlarmManager`/`AlarmClockInfo` rather than only writing them.
29. **Pane/sheet button spacing.** Add a small top margin above the button row in panes and sheets across the app so buttons aren't flush against the top edge.
30. **Agenda: remember Day/Week and add week navigation.** Persist the user's last-chosen Day/Week tab in the agenda sheet. Add forward/back chevrons for navigating weeks (and decide whether day view gets them too).
31. **Device tile: icons and more metrics.** Battery-cell icon reflecting charge level, a disk icon for free space, and either more device metrics surfaced or a selector so the user picks which ones show.
32. **Explore other Google-service tiles.** Survey what's reachable through the Flutter/Android SDKs beyond what's built (calendar, contacts, mail already exist) and report options before building anything.
33. **File/disk explorer.** A new pane/sheet for browsing storage, seeing what's taking up space, and deleting files directly — a lightweight disk-usage utility.
34. **Settings page visual grouping.** Rework section spacing/dividers/headers on the settings page to make each group easier to tell apart at a glance.
35. **Short-tile content overflow.** Several tile content views (the clock confirmed, others likely: `test/app_test.dart`'s `_oneOfEachSize` currently skips `TileSize.small` and `TileSize.flat` with a comment pointing here) overflow a one-row-tall tile at a realistic phone width. Predates Phase 26's new sizes (`small` alone already triggers it) and is unrelated to Phase 27's font scaling (reproduces at the normal, unscaled size too) — nobody had combined a phone-realistic test width with every tile kind at its smallest footprint before. Needs each content view to degrade gracefully at minimum height (a `FittedBox` around the whole stack, not just the headline, or a size-aware layout that drops the secondary line).

## Deliberately different from the terminal launcher

- **No command line.** `help`, `ui rich|plain`, aliases, `&&` chaining and macros have no counterpart here; a tile is either self-evident or badly designed.
- **`list`, `open`, `refresh`, `uninstall`** stop being commands and become the drawer, a tap, a pull-to-refresh and a long-press action.
- **A small set of canvases**, not six themes. The sixteen VIC-II colours are the palette in all of them; the canvas changes, not the tile colours.
- **Rich vs. plain** does not exist. Every tile is a card by definition.

## Not implemented (on purpose or not yet)

- **Widgets**: hosting real Android `AppWidget`s is a much larger job (`AppWidgetHost`, permissions, remote views) and is not planned. Tiles are ours.
- **Notification badges** need notification-listener access, which is a heavy permission; only the counts we can get another way (mail, calendar) are planned.
- **Wallpaper pass-through, acrylic blur, 3D tile tilt, rounded corners**: all in the Stitch mockups, none in this design. Flat, opaque, square.
- **Landscape and tablets**: portrait phone only until the phone version is good.

## Open questions for the user

1. Is the C64 blue canvas the default, with pitch-black OLED as an option, or the other way round?

## Changelog

- 2026-09-28: plan.md compacted. Phases 0–24 and their changelog moved to [.agents/archive/plan-phases-0-24.md](.agents/archive/plan-phases-0-24.md); the paused notes/todos phase (12) dropped as superseded. Plan restarted with a fresh outline (Phases 25–34) from the user's latest feature notes: grid-editor drag detection and vertical stacking, more tile size options, font scaling, the alarm tile's stuck "00:00", pane/sheet button margins, agenda Day/Week persistence and week navigation, device tile icons/metrics, a Google-services survey, a file/disk explorer, and settings visual grouping.
- 2026-09-28: Phase 25 done — the grid editor's insertion marker now appears on any of a tile's four edges (a diagonal quadrant split), not just left/right, and each tile's `DragTarget` reaches half a gutter past its own bounds so the marker triggers while crossing the gutter instead of only once fully over the next tile.
- 2026-09-28: Phase 26 done — four new `TileSize`s (flat 2×1, tall 1×2, broad 3×2, tower 2×4) alongside small/medium/wide/large, picked with the user from a shortlist of options; `spanIn` generalised behind a `fullWidth` flag instead of a per-case switch, and the inspector's resize row became a `Wrap` so eight size buttons fit a phone-width panel.
- 2026-09-28: Phase 27 done — a FONT SIZE setting (SMALL/NORMAL/LARGE/EXTRA LARGE) applied as one composed `MediaQuery.textScaler` override, reaching every text style without touching individual call sites. An app-level smoke test at a realistic phone width, added to verify it, surfaced a pre-existing overflow in several tile content views at one-row-tall sizes, unrelated to font scaling (reproduces at NORMAL) and predating Phase 26 (`small` alone triggers it); tracked as Phase 35 rather than fixed here.
