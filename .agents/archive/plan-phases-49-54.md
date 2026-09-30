# Archived plan — Phases 49, 50, 52, 53, 54

Full history of `plan.md` from 2026-09-30, moved here once those phases were implemented and verified, to keep the live `plan.md` short. See `plan.md` for the current phase list (Phase 51 is still open there, pending the user's own phone test before it is committed; Phase 55 has not been started); see `.agents/archive/plan-phases-45-48.md` for the phases before these.

## Done

| Phase | What it delivered |
|---|---|
| 49 | **Mail pane: rich view, chip, reply/forward, prev/next, bulk read/unread.** `MailBody` gained an `html` field (images stripped) so a message's real markup renders through `flutter_widget_from_html_core` instead of a flattened plain-text copy or, for a sloppy sender whose "plain" part is itself markup, raw tags; the sender's address became a bordered chip that opens a blank COMPOSE addressed to them (REPLY moved to its own button, alongside a new FORWARD that leaves TO blank); PREV/NEXT chevrons below BACK step through the open list without returning to it; the list's SELECT mode gained READ/UNREAD bulk actions beside DELETE. |
| 50 | **Calendar sheet reclaims vertical space.** The day/week sheet was capped at a flat 0.75 of screen height regardless of how much room was actually available; raised the cap to the same formula the mail sheet already uses (screen height minus the status bar/camera cutout and a small margin). |
| 52 | **Bluetooth tile shows connected devices.** The tile face used to show only a one-line `[ON]`/`[OFF]` state; it now lists currently connected devices' names, as many as fit the tile's own size (down to just a count on the smallest, narrowest tiles) — no action ever lives on the tile's own face, only in the sheet a tap opens, which already showed the full paired list (connected and disconnected). Caught a real regression along the way: the app-wide "every kind fits every size" smoke test only ever exercised the tile's bare ON/OFF state (the fake Bluetooth service defaulted to no connected devices); extending it to exercise a handful of connected devices immediately found the new list overflowing the smallest tile size at EXTRA LARGE font scale, fixed with the same outer-`FittedBox` safety net the device/mail/agenda tiles already use. |
| 53 | **Scrubber drift fixed; a second, persistent marker added.** The jump index scrubbed to `jumpFraction(groups, index) * maxScrollExtent`, but `jumpFraction` weighs a fraction of the list's *whole content height*, not of `maxScrollExtent` (shorter by a viewport's worth) — every jump undershot by an amount that grew with how far down the list the target letter was, reading as the marker drifting out of sync the further into the alphabet a scrub went. Fixed by scaling against the real total content height instead, clamped to the valid scroll range. Added `groupIndexForFraction` (the inverse of `jumpFraction`) driven by a scroll listener, powering a new persistent bordered-box marker on `JumpIndex` (`activeIndex`) that tracks whichever letter is actually at the top of the list from an ordinary scroll, distinct from the existing drag-touch underline. |
| 54 | **"+ ADD TILE" sheet keeps clear of the status bar/camera cutout.** It never set `useSafeArea`, so its own surface (not just its content, which the inner `SafeArea` already kept clear) could extend up under the status bar and a camera cutout once the tile list was long enough to reach that high — the same fix the mail and Bluetooth sheets already use. |

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

## Changelog (2026-09-30, Phases 49, 50, 52–54)

- 2026-09-30: Phase 49 (mail rich view, chip, reply/forward, prev/next, bulk read/unread) implemented and pushed.
- 2026-09-30: Phase 50 (calendar sheet reclaims vertical space) implemented and pushed.
- 2026-09-30: Phase 52 (Bluetooth tile shows connected devices) implemented and pushed, including the smoke-test extension that caught its own overflow regression.
- 2026-09-30: Phase 53 (scrubber drift fix and persistent marker) implemented and pushed.
- 2026-09-30: Phase 54 ("+ ADD TILE" sheet camera-cutout fix) implemented and pushed. 1525 tests total, format/analyze clean, debug APK builds.
- 2026-09-30: plan.md compacted. These five phases and their changelog moved here; phase numbering otherwise unchanged. Phase 51 (the "Week: Grid" calendar view) stays in `plan.md`, implemented but held uncommitted pending the user's own phone test; Phase 55 (a Tetris game) stays in `plan.md`, not yet started, paused for an architecture discussion.
