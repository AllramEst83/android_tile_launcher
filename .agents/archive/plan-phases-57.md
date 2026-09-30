# Archived plan — Phase 57

Full history of `plan.md` from 2026-09-30, moved here once this phase was implemented and verified, to keep the live `plan.md` short. See `plan.md` for the current phase list; see `.agents/archive/plan-phases-58.md` for the phase before this one.

## Done

| Phase | What it delivered |
|---|---|
| 57 | **Calendar: a TODAY button, pinch-to-zoom on the grid, and a remembered calendar.** A TODAY button sits beside `+ ADD EVENT` in Day, Week and Week:Grid alike (they all share the same PREV/NEXT/offset navigation), greyed out once already on today and jumping straight back to it otherwise. The Week:Grid view now zooms: a two-finger pinch anywhere on it shrinks or grows how tall an hour is drawn, tracked with raw pointer events rather than a `GestureDetector`'s scale recognizer, which would have contended with the grid's own one-finger vertical scroll on every drag, pinch or not. `+ ADD EVENT`'s calendar field now defaults to whichever calendar an event was last actually saved to (a new `lastUsedCalendarId` setting), falling back to the account's primary the way it always did once that calendar is no longer on offer or none has been used yet. |

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

## Changelog (2026-09-30, Phase 57)

- 2026-09-30: Phase 57 (calendar TODAY button, Week:Grid pinch-to-zoom, remembered calendar) implemented and pushed. 1537 tests total, format/analyze clean, debug APK builds.
- 2026-09-30: plan.md compacted. This phase and its changelog moved here; phase numbering otherwise unchanged. Phase 59 (a Tetris game) stays on hold, pending a design discussion — it is the only phase left in `plan.md`.
