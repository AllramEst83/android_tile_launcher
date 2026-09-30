# Archived plan — Phase 58

Full history of `plan.md` from 2026-09-30, moved here once this phase was implemented and verified, to keep the live `plan.md` short. See `plan.md` for the current phase list; see `.agents/archive/plan-phases-56.md` for the phase before this one.

## Done

| Phase | What it delivered |
|---|---|
| 58 | **Mail viewer's NEXT button pushed flush right.** PREV and NEXT sat together on the left of their own row, a fixed gap apart, rather than each keeping the same margin to the sheet's edge every other row (BACK, SELECT, REFRESH, COMPOSE) already does. A `Spacer` between them now pushes NEXT to the far right while PREV stays flush left, matching the sheet's own margins on both sides. |

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

## Changelog (2026-09-30, Phase 58)

- 2026-09-30: Phase 58 (mail viewer NEXT button flush right) implemented and pushed. 1528 tests total, format/analyze clean, debug APK builds.
- 2026-09-30: plan.md compacted. This phase and its changelog moved here; phase numbering otherwise unchanged. Phase 57 (calendar tweaks) stays in `plan.md`, not yet started; Phase 59 (a Tetris game) stays on hold.
