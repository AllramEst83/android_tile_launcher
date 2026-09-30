# Archived plan — Phase 51

Full history of `plan.md` from 2026-09-30, moved here once this phase was implemented, pushed and tested on the user's own phone, to keep the live `plan.md` short. See `plan.md` for the current phase list; see `.agents/archive/plan-phases-49-54.md` for the phases before this one.

## Done

| Phase | What it delivered |
|---|---|
| 51 | **Calendar "Week: Grid" view.** A new agenda view alongside the existing week list: hours down the side, the seven days across the top, timed events as positioned/sized blocks. Built on the `calendar_view` package (MIT, Simform) for the scroll/layout engine only — every visible part (hour labels, day headers, event blocks, the "you are here" today badge) is drawn in this launcher's own flat, hard-edged look, not the package's Material one. Pinned to exactly the agenda sheet's own rolling week (its start day computed from today's weekday, held fixed across navigation) so the grid's own paging never disagrees with the sheet's PREV/NEXT chevrons, which remain the only way to navigate it — the grid's own internal week-page header is hidden rather than offering a second, redundant control. The chosen tab (DAY/WEEK/WEEK:GRID) is remembered via a new `agendaGridView` setting, alongside the existing `agendaWeekView` one. |

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

## Changelog (2026-09-30, Phase 51)

- 2026-09-30: Phase 51 (calendar "Week: Grid" view) implemented; held uncommitted pending the user's own phone test. 1525 tests total, format/analyze clean, debug APK builds.
- 2026-09-30: Tested on the user's phone; committed and pushed.
- 2026-09-30: plan.md compacted. This phase and its changelog moved here; phase numbering otherwise unchanged. Phase 55 (a Tetris game) stays in `plan.md`, not yet started, paused for an architecture discussion.
