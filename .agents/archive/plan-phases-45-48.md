# Archived plan — Phases 45–48

Full history of `plan.md` from 2026-09-29, moved here once those phases were implemented and verified, to keep the live `plan.md` short. See `plan.md` for the current phase list; see `.agents/archive/plan-phases-25-44.md` for the phases before these.

## Done

| Phase | What it delivered |
|---|---|
| 45 | **Calendar: add, edit form and delete events.** `CalendarService` gained `writableCalendars`/`createEvent`/`updateEvent`/`deleteEvent` behind a new `calendarWrite` permission (Kotlin `CalendarChannelHandler` insert/update/delete via `ContentResolver`); `event_detail_sheet.dart` became a combined view/edit/add/delete sheet (EDIT switches the read fields into a form, SAVE writes back, DELETE asks first); `agenda_sheet.dart` gained a `+ ADD EVENT` button and reloads after any change. Reworked after the user tested it on their own phone: the sheet no longer sits under the keyboard; its date/time fields became real `showDatePicker`/`showTimePicker` pickers (24-hour dials) instead of typed `YYYY-MM-DD`/`HH:MM` text; an end date is optional and only shown once set (a multi-day event); and a CALENDAR dropdown (`writableCalendars`) lets the user choose — and so move — which calendar an event is filed under, defaulting to the event's own (`CalendarEvent.calendarId`, newly read from `CALENDAR_ID`) or the account's primary when adding. `tileLauncherTheme()` gained a flat `datePickerTheme`/`timePickerTheme` to match the app's own hard-edged look. |
| 46 | **Email: compose and reply.** `MailService` gained `send` over SMTP (`enough_mail`'s `SmtpClient`, a new `guessSmtpHost`, a fake local SMTP server for tests); a new `compose_sheet.dart` (to/subject/message, SEND) wired to a COMPOSE button on the mail sheet's list and a tappable sender address in the reader pane (opens a reply, addressed and `RE:`-subjected). Reworked after phone testing: a reply now quotes the original message under a blank line, cursor starting above it so typing lands the reply first, not inside the quote. |
| 47 | **Contacts/app-drawer scrubber alignment fix.** `GroupedList`'s jump-to-letter scroll math treated every letter group as equal-sized (`index / (groupCount - 1)`), so scrubbing past a heavy letter (many names) landed the list on the wrong spot for every letter after it. Fixed with a new pure `jumpFraction` (`model/alpha_grouping.dart`) that weighs each group by its own row count instead, unit-tested directly rather than through a rendered scroll extent. |
| 48 | **ROTATION tile: lock the screen orientation.** A new `TileKind.orientationLock` reusing the existing two-state toggle machinery (`ToggleTileSource`, `StateTileContentView`) flashlight already uses — `[LOCKED]`/`[AUTO]` rather than `[ON]`/`[OFF]`. Reads and writes Android's own `Settings.System.ACCELEROMETER_ROTATION`, the same switch the quick-settings auto-rotate tile flips, so locking it here holds across every app. Writing needs `WRITE_SETTINGS`, a special permission with no runtime dialog; `SystemControlChannelHandler` opens `ACTION_MANAGE_WRITE_SETTINGS` the first time, the same shape notification-policy access already takes for silent mode. No Dart-side permission plumbing needed — `SystemControlService.isOn`/`setOn` were already generic over `TileKind`. |

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

## Changelog (2026-09-29, Phases 45–48)

- 2026-09-29: Phase 45 (calendar add/edit/delete), 46 (mail compose + reply), 47 (contacts/app-drawer jump-index alignment fix) implemented and pushed. 1483 tests total, format/analyze clean, debug APK builds.
- 2026-09-29: Phase 45/46 follow-up from the user's own phone testing: reply quoting, the event sheet's keyboard overlap, real date/time pickers with an optional end date, and the CALENDAR dropdown (all summarised in Phase 45/46's own entries above, not repeated here). 1482 tests total, format/analyze clean, debug APK builds.
- 2026-09-29: Phase 48 (ROTATION tile) implemented and pushed. 1482 tests total, format/analyze clean, debug APK builds.
- 2026-09-29: plan.md compacted again. Phases 45–48 and their changelog moved here; phase numbering otherwise unchanged. Plan is now empty of phases, awaiting the user's next batch.
