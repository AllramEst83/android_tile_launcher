# Tile Launcher — Plan

Goal: an Android home-screen launcher made of live tiles, so the user rarely has to leave it. The structure is a four-column mosaic of 1×1, 2×2, 4×2 and 4×4 tiles (see `design/mockups/`); the look is Commodore-era (see `design/reference/`): light blue on C64 blue, the sixteen VIC-II colours, hard edges, bevels instead of shadows.

Guidance for agents: [AGENTS.md](AGENTS.md) and [.agents/](.agents/README.md). Each step ends with `dart format`, `flutter analyze`, `flutter test` clean, `flutter build apk --debug` after touching `android/`, and — where it touches the phone — a device check. Small steps: finish and verify one before starting the next.

Phases 0–24 (foundation through the app itself being feature-complete: apps, mosaic, drawer, persistence, grid editor, clock, device tile, weather, agenda, people, mail, Text TV, calc/convert, alarms, settings, wallpaper, and several rounds of visual/UI polish) are archived in [.agents/archive/plan-phases-0-24.md](.agents/archive/plan-phases-0-24.md). Phases 25–44 (grid-editor and tile-size overhauls, font scaling, several tile fixes found on the user's own phone, a device-tile icon set, a Google-services survey, the file/disk explorer and its all-files-access rebuild, settings visual grouping, a Bluetooth tile and its own later bugfix, the tile-size grid picker and its two follow-up fixes, bolder C64 styling, mail bulk delete, a help screen, and a search-field clear icon and its own follow-up fix) are archived in [.agents/archive/plan-phases-25-44.md](.agents/archive/plan-phases-25-44.md), along with their full changelog. Phases 45–48 (calendar add/edit/delete and its phone-testing follow-up fixes, mail compose/reply, the contacts/app-drawer scrubber alignment fix, and a rotation-lock tile) are archived in [.agents/archive/plan-phases-45-48.md](.agents/archive/plan-phases-45-48.md). Phases 49, 50, 52, 53 and 54 (mail's rich view/chip/reply/forward/prev-next/bulk read-unread, the calendar sheet reclaiming vertical space, the Bluetooth tile showing connected devices, the scrubber drift fix and its new persistent marker, and the add-tile sheet's camera-cutout fix) are archived in [.agents/archive/plan-phases-49-54.md](.agents/archive/plan-phases-49-54.md). Phase 51 (the calendar's "Week: Grid" view) is archived in [.agents/archive/plan-phases-51.md](.agents/archive/plan-phases-51.md), tested on the user's phone. Phase 56 (scrubber marker centering and drift) is archived in [.agents/archive/plan-phases-56.md](.agents/archive/plan-phases-56.md). Phase 58 (mail viewer NEXT button flush right) is archived in [.agents/archive/plan-phases-58.md](.agents/archive/plan-phases-58.md). Phase 57 (calendar TODAY button, Week:Grid pinch-to-zoom, remembered calendar) is archived in [.agents/archive/plan-phases-57.md](.agents/archive/plan-phases-57.md). Phase 59 (a Tetris game, built on Flutter Flame, and the `games/` module system for more games later) is archived in [.agents/archive/plan-phases-59.md](.agents/archive/plan-phases-59.md), not yet tested on the user's phone. `plan.md` is empty of phases below, awaiting the next batch.

The sibling repo `../android_terminal_launcher` already solves some of these problems (weather, mail, calendar, contacts, Text TV) in pure-Dart services worth reading before inventing a solution here, but its presentation never transfers — there is no command line here.

## Next, in order

Each phase gets designed in detail only when it's reached; this is an outline so the order is agreed up front. Small, independent phases can be reordered without much cost — ask if a different order would be more useful before starting.

Nothing is queued right now — awaiting the next batch of phases.

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

- 2026-09-29: plan.md compacted. Phases 25–44 and their changelog moved to [.agents/archive/plan-phases-25-44.md](.agents/archive/plan-phases-25-44.md); phase numbering otherwise unchanged. Plan is now empty of phases, awaiting the user's next batch.
- 2026-09-29: plan.md compacted again. Phases 45–48 (calendar add/edit/delete, mail compose/reply, the scrubber alignment fix, a rotation-lock tile, and the phone-testing follow-up fixes to the first two) and their changelog moved to [.agents/archive/plan-phases-45-48.md](.agents/archive/plan-phases-45-48.md); phase numbering otherwise unchanged. Plan is now empty of phases, awaiting the user's next batch.
- 2026-09-30: plan.md compacted again. Phases 49, 50, 52, 53 and 54 (mail rich view/chip/reply/forward/prev-next/bulk read-unread, the calendar sheet reclaiming vertical space, the Bluetooth tile showing connected devices, the scrubber drift fix and its new persistent marker, and the add-tile sheet's camera-cutout fix) and their changelog moved to [.agents/archive/plan-phases-49-54.md](.agents/archive/plan-phases-49-54.md); phase numbering otherwise unchanged. Phase 51 stays, implemented but held uncommitted pending the user's phone test; Phase 55 stays, not yet started.
- 2026-09-30: Phase 51 (calendar "Week: Grid" view) tested on the user's phone, committed and pushed. plan.md compacted again: Phase 51 and its changelog moved to [.agents/archive/plan-phases-51.md](.agents/archive/plan-phases-51.md); phase numbering otherwise unchanged. Phase 55 stays, not yet started.
- 2026-09-30: The user added phases 56–58 (a scrubber marker fix, calendar tweaks, and a mail layout fix) and renumbered the Tetris game to 59, on hold. Phase 56 (scrubber marker centering and drift) implemented and pushed; plan.md compacted again: Phase 56 and its changelog moved to [.agents/archive/plan-phases-56.md](.agents/archive/plan-phases-56.md); phase numbering otherwise unchanged. Phases 57–58 stay, not yet started; Phase 59 stays on hold.
- 2026-09-30: Phase 58 (mail viewer NEXT button flush right) implemented and pushed, out of numeric order (independent of 57, and smaller). plan.md compacted again: Phase 58 and its changelog moved to [.agents/archive/plan-phases-58.md](.agents/archive/plan-phases-58.md); phase numbering otherwise unchanged. Phase 57 stays, not yet started; Phase 59 stays on hold.
- 2026-09-30: Phase 57 (calendar TODAY button, Week:Grid pinch-to-zoom, remembered calendar) implemented and pushed. plan.md compacted again: Phase 57 and its changelog moved to [.agents/archive/plan-phases-57.md](.agents/archive/plan-phases-57.md); phase numbering otherwise unchanged. Phase 59 (a Tetris game) is the only phase left, still on hold pending a design discussion.
- 2026-09-30: The user asked for two small calendar follow-ups (DAY/AGENDA/GRID spread evenly, week starting Monday) and a Bluetooth sheet cleanup (TURN ON/OFF and MANAGE DEVICES removed, the device list fills the pane); both implemented and pushed, recorded in `.agents/archive/plan-phases-57.md` and `.agents/archive/plan-phases-49-54.md` respectively rather than as new numbered phases, per the user's own instruction.
- 2026-09-30: Phase 59 (Tetris, built on Flutter Flame, plus the `games/` module system for future games) implemented and pushed: 1582 tests total, format/analyze clean, debug APK builds. plan.md compacted again: Phase 59 and its changelog moved to [.agents/archive/plan-phases-59.md](.agents/archive/plan-phases-59.md); phase numbering otherwise unchanged. Not yet tested on the user's phone. `plan.md` is now empty of phases, awaiting the next batch.
- 2026-09-30: Tested on the user's phone: Tetris did not start (a redundant lifecycle observer in `TetrisScreen` was freezing the game on a transient `inactive` blip caused by switching to immersive mode), and the app drawer never noticed an app installed or uninstalled while backgrounded. Both fixed — recorded in `.agents/archive/plan-phases-59.md` rather than as a new numbered phase, since both are fixes to already-shipped work.
