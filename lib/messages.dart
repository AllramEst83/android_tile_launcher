/// Every user-facing string, in one place, so the product's voice stays
/// consistent and testable.
abstract final class Messages {
  static const String appTitle = 'Tile Launcher';

  static const String bootBanner = '**** TILE LAUNCHER V1 ****';
  static const String bootMemory = '64K RAM SYSTEM  38911 TILES FREE';
  static const String bootReady = 'READY.';
  static const String bootLoad = 'LOAD "HOME",8';
  static const String bootSearching = 'SEARCHING FOR HOME';
  static const String bootLoading = 'LOADING';
  static const String bootRun = 'RUN';

  static const String noAppsFound = 'NO APPS FOUND.';
  static const String appListError = 'APP LIST FAILED. PULL DOWN TO RETRY.';

  static const String swipeForAllApps = 'SWIPE LEFT FOR ALL APPS';
  static const String nothingPinned =
      'NOTHING PINNED YET. SWIPE LEFT, HOLD AN APP, PIN TO GRID.';
  static const String searchApps = 'SEARCH APPS...';
  static const String noSearchResults = 'NOTHING MATCHES.';
  static const String pinToGrid = 'PIN TO GRID';
  static const String unpinFromGrid = 'UNPIN FROM GRID';
  static const String appDetails = 'APP DETAILS';
  static const String uninstall = 'UNINSTALL';

  static const String cancel = 'CANCEL';
  static const String apply = 'APPLY';
  static const String tileSize = 'SIZE';
  static const String tileColour = 'COLOUR';

  static const String addTile = '+ ADD TILE';
  static const String noTilesToAdd = 'NOTHING LEFT TO ADD.';
  static const String addTileMostUsed = 'MOST USED';
  static const String addTileOther = 'OTHER TILES';

  static const String weatherTitle = 'WEATHER';
  static const String weatherTapToLocate = 'TAP TO USE MY LOCATION';
  static const String weatherTapToAllow = 'TAP TO ALLOW LOCATION';
  static const String weatherAllowInSettings =
      'ALLOW LOCATION IN ANDROID SETTINGS';
  static const String weatherTapToRetry = 'TAP TO RETRY';
  static const String weatherOffline = 'NO CONNECTION.';
  static const String weatherOld = 'OLD';

  static const String agendaTitle = 'AGENDA';
  static const String agendaTapToAllow = 'TAP TO ALLOW CALENDAR';
  static const String agendaAllowInSettings =
      'ALLOW CALENDAR IN ANDROID SETTINGS';
  static const String agendaTapToRetry = 'TAP TO RETRY';
  static const String agendaNothingPlanned = 'NOTHING PLANNED.';
  static const String agendaNothingToday = 'NOTHING TODAY.';
  static const String agendaDay = 'DAY';
  static const String agendaWeek = 'WEEK';
  static const String agendaUntitled = '(NO TITLE)';

  static const String contactSearch = 'SEARCH CONTACTS...';
  static const String contactsLoading = 'LOADING...';
  static const String contactsNone = 'NO CONTACTS WITH A NUMBER.';
  static const String contactsNoMatch = 'NOBODY MATCHES.';
  static const String contactsNotAllowed = 'CONTACTS NOT ALLOWED.';
  static const String contactsAllowInSettings =
      'ALLOW CONTACTS IN ANDROID SETTINGS';
  static const String contactGone = 'NOT IN THE PHONE BOOK ANY MORE.';
  static const String contactCall = 'CALL';
  static const String contactSms = 'SMS';
  static const String contactWhatsApp = 'WHATSAPP';
  static const String contactSend = 'SEND';
  static const String contactMessageHint = 'MESSAGE...';
  static const String contactSending = 'SENDING...';
  static const String contactSent = 'SENT.';
  static const String smsNotAllowed = 'SMS NOT ALLOWED.';
  static const String smsAllowInSettings = 'ALLOW SMS IN ANDROID SETTINGS';
  static const String failedPrefix = 'FAILED: ';

  static const String mailTitle = 'MAIL';
  static const String mailTapToSetUp = 'TAP TO SET UP';
  static const String mailTapToRetry = 'TAP TO RETRY';
  static const String mailUnread = 'UNREAD';
  static const String mailInboxEmpty = 'THE INBOX IS EMPTY.';
  static const String mailNoSubject = '(NO SUBJECT)';
  static const String mailSetUpTitle = 'SET UP MAIL';
  static const String mailAppPasswordNote =
      'USE AN APP PASSWORD, NOT YOUR NORMAL ONE. IT IS KEPT ENCRYPTED ON THIS PHONE ONLY.';
  static const String mailEmail = 'EMAIL ADDRESS';
  static const String mailServer = 'IMAP SERVER';
  static const String mailPassword = 'APP PASSWORD';
  static const String mailConnect = 'CONNECT';
  static const String mailChecking = 'CHECKING...';
  static const String mailTrash = 'TRASH';
  static const String mailTrashAsk = 'MOVE TO TRASH?';
  static const String mailYes = 'YES';
  static const String mailNo = 'NO';
  static const String mailMoved = 'MOVED TO TRASH.';
  static const String mailGone = 'ALREADY GONE.';
  static const String mailForget = 'FORGET ACCOUNT';
  static const String mailForgetAsk = 'FORGET THIS ACCOUNT AND ITS PASSWORD?';
  static const String mailRefresh = 'REFRESH';

  static const String calcTitle = 'CALC';
  static const String calcTabCalc = 'CALC';
  static const String calcTabConvert = 'CONVERT';
  static const String calcFrom = 'FROM';
  static const String calcTo = 'TO';
  static const String calcSwap = 'SWAP';
  static const String calcClear = 'C';
  static const String calcDelete = 'DEL';
  static const String calcEquals = '=';
  static const String calcRatesLoading = 'LOADING RATES...';
  static const String calcTryAgain = 'TRY AGAIN';
  static String calcRateNote(String day, {required bool stale}) =>
      stale ? 'SAVED RATES FROM $day (OFFLINE)' : 'RATES FROM $day (ECB)';
  static const String calcMoney = 'MONEY';

  static const String alarmTitle = 'ALARM';
  static const String alarmTabTimer = 'TIMER';
  static const String alarmTabAlarm = 'ALARM';
  static const String alarmStart = 'START';
  static const String alarmSet = 'SET ALARM';
  static const String alarmSeeTimers = 'SEE TIMERS';
  static const String alarmSeeAlarms = 'SEE ALARMS';
  static const String alarmDays = 'REPEAT';
  static const String alarmOnce = 'ONCE';
  static const String alarmWeekdays = 'MON-FRI';
  static const String alarmWeekend = 'SAT SUN';
  static const String alarmDaily = 'DAILY';
  static const String alarmTooLong = 'A TIMER IS 24 HOURS AT MOST.';
  static const String alarmHandedOver = 'SET IN THE CLOCK APP.';
  static String alarmTimerSet(String length) => 'TIMER STARTED: $length';
  static String alarmAlarmSet(String when) => 'ALARM SET: $when';
  static String alarmNext(String when) => 'NEXT: $when';

  static const String settingsButton = 'SETTINGS';
  static const String settingsTitle = 'SETTINGS';
  static const String settingsTheme = 'THEME';
  static const String settingsGrid = 'GRID';
  static const String settingsColumns = 'COLUMNS';
  static const String settingsGap = 'GAP BETWEEN TILES';
  static const String settingsGestures = 'GESTURES';
  static const String settingsSwipeLeft = 'SWIPE LEFT ON HOME OPENS ALL APPS.';
  static const String settingsSwipeDown = 'SWIPE DOWN';
  static const String settingsSwipeDownNote =
      'PULL DOWN WHEN HOME IS AT THE TOP.';
  static const String settingsSwipeUp = 'SWIPE UP';
  static const String settingsSwipeUpNote =
      'PUSH UP WHEN HOME IS AT THE BOTTOM.';
  static const String settingsFeel = 'FEEL';
  static const String settingsHaptics = 'HAPTICS';
  static const String settingsHapticsNote =
      'A SHORT BUZZ WHEN YOU PRESS A TILE OR A KEY.';
  static const String settingsOn = 'ON';
  static const String settingsOff = 'OFF';
  static const String settingsSystem = 'SYSTEM';
  static const String settingsHomeApp = 'DEFAULT HOME APP';
  static const String settingsHomeActive = 'ACTIVE: THIS IS YOUR HOME APP.';
  static const String settingsHomeNotSet = 'NOT SET: ANOTHER APP IS HOME.';
  static const String settingsHomeUnknown = 'COULD NOT FIND OUT.';
  static const String settingsHomeChecking = 'CHECKING...';
  static const String settingsOpenHome = 'CHOOSE HOME APP';
  static const String settingsLayout = 'LAYOUT';
  static const String settingsExport = 'EXPORT';
  static const String settingsImport = 'IMPORT';
  static const String settingsExportNote =
      'EXPORT COPIES YOUR TILES AND SETTINGS AS TEXT. IMPORT READS THEM BACK FROM THE CLIPBOARD.';
  static const String settingsClearLayout = 'CLEAR LAYOUT';
  static const String settingsResetSettings = 'RESET SETTINGS';
  static const String settingsClipboardRefused = 'THE CLIPBOARD REFUSED IT.';
  static const String settingsResetAsk =
      'PUT EVERY SETTING BACK TO ITS DEFAULT?';
  static String settingsExported(int tiles) =>
      'COPIED $tiles ${tiles == 1 ? 'TILE' : 'TILES'} AND THE SETTINGS.';
  static String settingsImported(int tiles) =>
      'IMPORTED $tiles ${tiles == 1 ? 'TILE' : 'TILES'} AND THE SETTINGS.';
  static String settingsImportAsk(int tiles, int skipped) =>
      'REPLACE YOUR LAYOUT AND SETTINGS WITH $tiles ${tiles == 1 ? 'TILE' : 'TILES'} FROM THE CLIPBOARD?${skipped > 0 ? ' ($skipped COULD NOT BE READ.)' : ''}';
  static String settingsClearAsk(int tiles) =>
      'REMOVE ${tiles == 1 ? 'THE 1 TILE' : 'ALL $tiles TILES'} FROM HOME?';

  static const String textTvTitle = 'TEXT TV';
  static const String textTvTapToOpen = 'TAP TO OPEN';
  static const String textTvNotBroadcast = 'NOT IN BROADCAST.';
  static const String textTvLoading = 'LOADING...';
  static const String textTvTryAgain = 'TRY AGAIN';
  static const String textTvRefresh = 'REFRESH';
  static const String textTvPart = 'PART';
  static String textTvPageNotBroadcast(int number) =>
      'PAGE $number IS NOT IN BROADCAST.';

  // Why an expression could not be worked out: lower case, as they are said;
  // the pad shows them in capitals.
  static String exprUnexpected(String found) => "unexpected '$found'";
  static const String exprUnexpectedEnd = 'expression ended unexpectedly';
  static const String exprMissingParen = "missing ')'";
  static const String exprDivideByZero = 'division by zero';
  static const String exprNotReal = 'result is not a real number';
  static const String exprTooLarge = 'result is too large';
  static const String exprTooDeep = 'expression is nested too deeply';
  static String exprBadNumber(String text) => "bad number '$text'";
  static String exprUnknownName(String name) =>
      "unknown function or constant '$name'";
}
