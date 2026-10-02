# Tile Launcher — Plan

Goal: an Android home-screen launcher made of live tiles, so the user rarely has to leave it. The structure is a four-column mosaic of 1×1, 2×2, 4×2 and 4×4 tiles (see `design/mockups/`); the look is Commodore-era (see `design/reference/`): light blue on C64 blue, the sixteen VIC-II colours, hard edges, bevels instead of shadows.

Guidance for agents: [AGENTS.md](AGENTS.md) and [.agents/](.agents/README.md). Each step ends with `dart format`, `flutter analyze`, `flutter test` clean, `flutter build apk --debug` after touching `android/`, and — where it touches the phone — a device check. Small steps: finish and verify one before starting the next.

Phases 0–24 (foundation through the app itself being feature-complete: apps, mosaic, drawer, persistence, grid editor, clock, device tile, weather, agenda, people, mail, Text TV, calc/convert, alarms, settings, wallpaper, and several rounds of visual/UI polish) are archived in [.agents/archive/plan-phases-0-24.md](.agents/archive/plan-phases-0-24.md). Phases 25–44 (grid-editor and tile-size overhauls, font scaling, several tile fixes found on the user's own phone, a device-tile icon set, a Google-services survey, the file/disk explorer and its all-files-access rebuild, settings visual grouping, a Bluetooth tile and its own later bugfix, the tile-size grid picker and its two follow-up fixes, bolder C64 styling, mail bulk delete, a help screen, and a search-field clear icon and its own follow-up fix) are archived in [.agents/archive/plan-phases-25-44.md](.agents/archive/plan-phases-25-44.md), along with their full changelog. Phases 45–48 (calendar add/edit/delete and its phone-testing follow-up fixes, mail compose/reply, the contacts/app-drawer scrubber alignment fix, and a rotation-lock tile) are archived in [.agents/archive/plan-phases-45-48.md](.agents/archive/plan-phases-45-48.md). Phases 49, 50, 52, 53 and 54 (mail's rich view/chip/reply/forward/prev-next/bulk read-unread, the calendar sheet reclaiming vertical space, the Bluetooth tile showing connected devices, the scrubber drift fix and its new persistent marker, and the add-tile sheet's camera-cutout fix) are archived in [.agents/archive/plan-phases-49-54.md](.agents/archive/plan-phases-49-54.md). Phase 51 (the calendar's "Week: Grid" view) is archived in [.agents/archive/plan-phases-51.md](.agents/archive/plan-phases-51.md), tested on the user's phone. Phase 56 (scrubber marker centering and drift) is archived in [.agents/archive/plan-phases-56.md](.agents/archive/plan-phases-56.md). Phase 58 (mail viewer NEXT button flush right) is archived in [.agents/archive/plan-phases-58.md](.agents/archive/plan-phases-58.md). Phase 57 (calendar TODAY button, Week:Grid pinch-to-zoom, remembered calendar) is archived in [.agents/archive/plan-phases-57.md](.agents/archive/plan-phases-57.md). Phase 59 (a Tetris game) was attempted on Flutter Flame and fully reverted after repeated, unresolved rendering failures on the user's real device — see the changelog below; if revisited, use plain Flutter (`CustomPainter`) instead of Flame. `plan.md` is empty of phases below, awaiting the next batch.

The sibling repo `../android_terminal_launcher` already solves some of these problems (weather, mail, calendar, contacts, Text TV) in pure-Dart services worth reading before inventing a solution here, but its presentation never transfers — there is no command line here.

## Next, in order

**Analyze and improve the calendar tile** — implemented 2026-10-02, awaiting the user's phone test (see the changelog entry of that date for the eight bugs found and fixed, and the new FILTER / SHOW CALENDARS picker). Things to check on the phone:
- Delete one occurrence of a repeating event: only that day's goes; the rest of the series stays (also check it in the phone's own calendar app).
- Edit one occurrence (move its time): only that day's moves.
- GRID: all-day events and the middle days of a multi-day event show in the all-day row under the day headers; tap one to open it.
- GRID at a pinched zoom: reopening still starts around 07:00.
- FILTER: hide a calendar, close — its events leave the list, grid and the tile; the button reads `FILTER n/m`.
- Move an event to another calendar via EDIT: it ends up there once, not twice and not lost.

## Deliberately different from the terminal launcher

- **No command line.** `help`, `ui rich|plain`, aliases, `&&` chaining and macros have no    counterpart here; a tile is either self-evident or badly designed.
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

Dont read if not neccessery. 
- (C:\Users\kaywi\dev\android_tile_launcher\.agents\change_log.md)