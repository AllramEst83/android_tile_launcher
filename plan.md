# Tile Launcher — Plan

Goal: an Android home-screen launcher made of live tiles, so the user rarely has to leave it. The structure is a four-column mosaic of 1×1, 2×2, 4×2 and 4×4 tiles (see `design/mockups/`); the look is Commodore-era (see `design/reference/`): light blue on C64 blue, the sixteen VIC-II colours, hard edges, bevels instead of shadows.

Guidance for agents: [AGENTS.md](AGENTS.md) and [.agents/](.agents/README.md). Each step ends with `dart format`, `flutter analyze`, `flutter test` clean, `flutter build apk --debug` after touching `android/`, and — where it touches the phone — a device check. Small steps: finish and verify one before starting the next.

Phases 0–24 (foundation through the app itself being feature-complete: apps, mosaic, drawer, persistence, grid editor, clock, device tile, weather, agenda, people, mail, Text TV, calc/convert, alarms, settings, wallpaper, and several rounds of visual/UI polish) are done and archived in [.agents/archive/plan-phases-0-24.md](.agents/archive/plan-phases-0-24.md), along with their full changelog. This file now starts a fresh round of phases from the user's latest notes.

The sibling repo `../android_terminal_launcher` already solves some of these problems (weather, mail, calendar, contacts, Text TV) in pure-Dart services worth reading before inventing a solution here, but its presentation never transfers — there is no command line here.

## Next, in order

Each phase gets designed in detail only when it's reached; this is an outline so the order is agreed up front. Small, independent phases can be reordered without much cost — ask if a different order would be more useful before starting.

25. **Grid editor: easier drag placement.** The drop-target detection area is too small and requires dragging too far over a neighbour before the insertion marker appears; make it more forgiving and quicker to trigger. Add markers above and below existing tiles too, so tiles can be stacked vertically, not just placed side by side.
26. **Grid editor: more tile size options.** More time/size dimensions beyond the current 1×1 / 2×2 / 4×2 / 4×4 — e.g. 3×2 and others — in the inspector's resize control and the packer.
27. **Font scaling.** A global font-scale setting (slider and/or the app's existing selection-box style) in Settings, with a live preview, sensible min/max limits, and every text style in the app routed through it so the whole UI adapts consistently.
28. **Alarm tile fix.** Stop showing a static "00:00". Decide and build the right always-current state to show — plain "ALARM" label, or the next upcoming alarm's time, or a summary of all set alarms — which may need reading alarms via `AlarmManager`/`AlarmClockInfo` rather than only writing them.
29. **Pane/sheet button spacing.** Add a small top margin above the button row in panes and sheets across the app so buttons aren't flush against the top edge.
30. **Agenda: remember Day/Week and add week navigation.** Persist the user's last-chosen Day/Week tab in the agenda sheet. Add forward/back chevrons for navigating weeks (and decide whether day view gets them too).
31. **Device tile: icons and more metrics.** Battery-cell icon reflecting charge level, a disk icon for free space, and either more device metrics surfaced or a selector so the user picks which ones show.
32. **Explore other Google-service tiles.** Survey what's reachable through the Flutter/Android SDKs beyond what's built (calendar, contacts, mail already exist) and report options before building anything.
33. **File/disk explorer.** A new pane/sheet for browsing storage, seeing what's taking up space, and deleting files directly — a lightweight disk-usage utility.
34. **Settings page visual grouping.** Rework section spacing/dividers/headers on the settings page to make each group easier to tell apart at a glance.

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
