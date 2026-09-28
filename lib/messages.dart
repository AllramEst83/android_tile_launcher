/// Every user-facing string, in one place, so the product's voice stays
/// consistent and testable.
abstract final class Messages {
  static const String appTitle = 'Tile Launcher';

  static const String bootBanner = '**** TILE LAUNCHER V1 ****';
  static const String bootMemory = '64K RAM SYSTEM  38911 TILES FREE';
  static const String bootReady = 'READY.';

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

  static const String textTvTitle = 'TEXT TV';
  static const String textTvTapToOpen = 'TAP TO OPEN';
  static const String textTvNotBroadcast = 'NOT IN BROADCAST.';
  static const String textTvLoading = 'LOADING...';
  static const String textTvTryAgain = 'TRY AGAIN';
  static const String textTvRefresh = 'REFRESH';
  static const String textTvPart = 'PART';
  static String textTvPageNotBroadcast(int number) =>
      'PAGE $number IS NOT IN BROADCAST.';
}
