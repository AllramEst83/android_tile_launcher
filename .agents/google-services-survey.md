# Google-service tiles — survey (Phase 32)

What Phase 32 asked for: a look at what else is reachable through the
Flutter/Android SDKs "beyond what's built (calendar, contacts, mail already
exist)", findings and a conclusion recorded before building anything. This is
that record. Nothing here has been built; Phase 32 itself is this document.

## The trap in the phase's own premise

Calendar, contacts and mail are not really "Google" tiles — they read Android's
own `CalendarContract`/`ContactsContract` providers and speak generic IMAP.
**If the phone's Google account is already syncing calendar and contacts (the
default for almost every Android phone), the agenda and people tiles already
show that data.** There is nothing to add there; a "Google Calendar tile" or
"Google Contacts tile" alongside the existing ones would be a second, worse
path to data already on screen. Same story for mail: IMAP already reads a
Gmail account (with an app password or OAuth token typed into the existing
account setup) without a Gmail-specific integration.

So the real question this phase raises is narrower than it sounds: is there
a *Google-specific* capability, not already reachable through a generic
Android API, worth a tile of its own?

## Two very different kinds of "Google API"

**A. On-device Android APIs that happen to be Google's** — no sign-in, no
cloud project, no OAuth consent screen. The same shape every existing service
in this app already has: a permission (sometimes none), a platform channel,
done.

**B. Google's own cloud APIs** (Gmail API, Google Tasks API, Drive API,
Photos Library API, YouTube Data API, Google Fit's *cloud* history API, …) —
every one of these needs the user to sign in with a Google account through
this app specifically, a Google Cloud project registered and (for anything
touching real user data) an OAuth consent screen that Google reviews before
"sensitive"/"restricted" scopes go live, plus this app now holding and
refreshing OAuth tokens rather than the one IMAP app password `MailAccountStore`
already handles. That is a different category of engineering from every
other tile in this launcher, and it cuts against what this app has quietly
committed to everywhere else: no accounts screen beyond "type your IMAP
details", nothing that only works if Google approves a review, nothing that
breaks if a token silently expires with no UI built yet to refresh it.

**Recommendation: skip category B entirely**, not because any one of these
integrations is technically hard, but because building *any of them* commits
this app to an OAuth/token-lifecycle story it has no other reason to need,
for user value already covered another way in every case below:

| API | What it would show | Already covered? |
|---|---|---|
| Gmail API | Unread count, richer message data | Yes — IMAP mail tile, any provider |
| Google Tasks API | A task list tile | Not covered, but see "not implemented" below |
| Drive API | Storage quota, recent files | Marginal value; a phone-storage tile (Phase 31) says more |
| Photos Library API | "Memory" of the day | Nice-to-have, heavy for the value |
| YouTube Data API | Subscription feed / next video | Out of scope for a launcher tile |

## Category A: on-device, no account tie-in

- **Health Connect** (Android's unified health/fitness data store, the
  successor to the old Google Fit SDK — `androidx.health.connect`, or
  Flutter's `health` package on top of it). Steps, active minutes, sleep.
  Permission-gated like calendar/contacts, no sign-in, no cloud project. This
  is the one candidate that actually matches this app's architecture: a
  platform read behind a repository interface, exactly like every tile
  already here. **The strongest candidate if the user wants one more tile
  from this phase.**
- **"Now playing" (current media session)** — reading whatever any app is
  playing needs `NotificationListenerService` access, the same heavy,
  all-notifications permission already turned down for badges in
  `plan.md`'s "Not implemented" section. Skip, same reasoning as before.
- **Screen time / Digital Wellbeing** (`UsageStatsManager`) — needs
  `PACKAGE_USAGE_STATS`, a special "app ops" permission the user grants
  through a *separate* Settings screen this app would have to deep-link to
  (`ACTION_USAGE_ACCESS_SETTINGS`), not a runtime dialog. Workable, but a
  heavier ask than anything else in this app for a metric of debatable daily
  value on a *launcher's* home screen specifically. Skip for now.
- **Find My Device / Nearby Share** — no public API for a third-party app to
  read either from.

## Conclusion

Don't build a "Google tile" in the sense the phase's title suggests — the
Google-account data worth showing (calendar, contacts) is already on screen,
and the rest worth having needs either an OAuth commitment this app has
avoided everywhere else (skip) or a heavy, awkward permission for modest
value (skip, for now). The one genuine opening is **Health Connect**, which
fits this app's existing shape exactly. Recommendation: only build it if the
user actually wants a steps/activity tile — it is not implied by anything
already on the home screen the way calendar/contacts were, so it is a new
feature decision, not a "finish what's already implied" one. Left off
`plan.md`'s numbered list on purpose; add it as its own phase if wanted.
