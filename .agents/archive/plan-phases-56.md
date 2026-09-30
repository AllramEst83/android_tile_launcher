# Archived plan — Phase 56

Full history of `plan.md` from 2026-09-30, moved here once this phase was implemented and verified, to keep the live `plan.md` short. See `plan.md` for the current phase list; see `.agents/archive/plan-phases-51.md` for the phase before this one.

## Done

| Phase | What it delivered |
|---|---|
| 56 | **Scrubber: marker centering and drift, fixed.** Two separate bugs behind the same complaint (a photo of the app drawer showed the persistent "you are here" box sitting off to the side of its letter, worse further down the alphabet). First: the box was drawn even while a finger was down on the strip, but the touched letters themselves swing out and grow under the wave effect — a box left at their untransformed row no longer sat around them, so it is now hidden for as long as a finger is down (the existing touch underline already covers that case) and reappears once it lifts. Second, and the real cause of the growing drift: `jumpFraction`/`groupIndexForFraction` weighed every group as "one header row plus one row per item," but a `SectionHeader`'s big letter is measurably taller on screen than a 48px app or contact row — so the naive count-based fraction undercounted every header passed, worse the more of them a scrub had gone through. Both now take a `headerWeight`/`itemWeight`, and `GroupedList` measures the real rendered heights of its own header and row styles (via `TextPainter`, at whatever font-scale setting is in effect) instead of assuming they match. |

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

## Changelog (2026-09-30, Phase 56)

- 2026-09-30: Phase 56 (scrubber marker centering and drift) implemented and pushed. 1527 tests total, format/analyze clean, debug APK builds.
- 2026-09-30: plan.md compacted. This phase and its changelog moved here; phase numbering otherwise unchanged. Phases 57–58 (calendar and email tweaks) and Phase 59 (a Tetris game, on hold) stay in `plan.md`.
