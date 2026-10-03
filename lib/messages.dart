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
  static const String moveMany = 'MOVE MANY';
  static const String moveManyDone = 'DONE';
  static const String moveManyHint =
      'TAP TILES TO PICK THEM, THEN HOLD ONE AND DRAG.';
  static String tilesPicked(int n) => n == 1 ? '1 TILE' : '$n TILES';
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

  static const String agendaTitle = 'CALENDAR';
  static const String agendaTapToAllow = 'TAP TO ALLOW CALENDAR';
  static const String agendaAllowInSettings =
      'ALLOW CALENDAR IN ANDROID SETTINGS';
  static const String agendaTapToRetry = 'TAP TO RETRY';
  static const String agendaNothingPlanned = 'NOTHING PLANNED.';
  static const String agendaNothingToday = 'NOTHING TODAY.';
  static const String agendaDay = 'DAY';
  static const String agendaWeek = 'AGENDA';
  static const String agendaWeekGrid = 'GRID';
  static const String agendaToday = 'TODAY';
  static const String agendaUntitled = '(NO TITLE)';
  static const String agendaEventTitle = 'EVENT';
  static const String agendaEventWhen = 'WHEN';
  static const String agendaEventWhere = 'WHERE';
  static const String agendaEventAbout = 'ABOUT';
  static const String agendaEventNoDescription = 'NO DESCRIPTION.';
  static const String agendaAddEvent = '+ ADD EVENT';
  static const String agendaEventEdit = 'EDIT';
  static const String agendaEventDelete = 'DELETE';
  static const String agendaEventDeleteAsk = 'DELETE THIS EVENT?';
  static const String agendaEventSave = 'SAVE';
  static const String agendaEventTitleLabel = 'TITLE';
  static const String agendaEventCalendarLabel = 'CALENDAR';
  static const String agendaEventLoadingCalendars = 'LOADING CALENDARS...';
  static const String agendaEventStartDateLabel = 'START DATE';
  static const String agendaEventStartTimeLabel = 'START TIME';
  static const String agendaEventEndDateLabel = 'END DATE';
  static const String agendaEventEndTimeLabel = 'END TIME';
  static const String agendaEventSameDay = 'SAME DAY';
  static const String agendaEventClear = 'CLEAR';
  static const String agendaEventTapToSet = 'TAP TO SET';
  static const String agendaEventTitleNeeded = 'GIVE IT A TITLE.';
  static const String agendaEventStartTimeNeeded = 'GIVE IT A START TIME.';
  static const String agendaEventEndTimeNeeded = 'GIVE IT AN END TIME.';
  static const String agendaEventEndNotAfterStart = 'END MUST BE AFTER START.';
  static const String agendaEventNoCalendar = 'NO CALENDAR CAN BE WRITTEN TO.';
  static const String agendaEventSaving = 'SAVING...';
  static const String agendaEventDeleting = 'DELETING...';
  static const String agendaEventGone = 'ALREADY GONE.';
  static const String agendaWriteNotAllowed = 'CALENDAR WRITE NOT ALLOWED.';
  static const String agendaWriteAllowInSettings =
      'ALLOW CALENDAR WRITE IN ANDROID SETTINGS';
  static const String agendaEventDeleteOccurrenceAsk =
      'DELETE THIS OCCURRENCE?';
  static const String agendaEventRepeats =
      'REPEATING EVENT: CHANGES APPLY TO THIS OCCURRENCE ONLY.';
  static const String agendaFilter = 'FILTER';
  static const String agendaCalendarsTitle = 'SHOW CALENDARS';
  static const String agendaCalendarsNone = 'NO CALENDARS ON THIS PHONE.';
  static const String agendaCalendarsReadOnly = 'READ ONLY';
  static const String agendaCalendarsAllHidden =
      'EVERY CALENDAR IS HIDDEN. TAP FILTER.';

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
  static const String mailBack = '< BACK';
  static const String mailPrev = '< PREV';
  static const String mailNext = 'NEXT >';
  static const String mailReply = 'REPLY';
  static const String mailReplyAll = 'REPLY ALL';
  static const String mailForward = 'FORWARD';
  static const String mailMarkRead = 'MARK AS READ';
  static const String mailMarkUnread = 'MARK AS UNREAD';
  static const String mailOpening = 'OPENING...';
  static const String mailMarkedRead = 'MARKED AS READ.';
  static const String mailMarkedUnread = 'MARKED AS UNREAD.';
  static const String mailNotMarked = 'OPENED, BUT COULD NOT MARK IT READ.';
  static const String mailFrom = 'FROM';
  static const String mailTo = 'TO';
  static const String mailCc = 'CC';
  static const String mailDate = 'DATE';
  static const String mailNoText = '(NOTHING TO SHOW: NO TEXT IN THIS MESSAGE)';
  static const String mailCutOff =
      '... CUT SHORT. OPEN IT IN YOUR MAIL APP FOR THE REST.';
  static String mailAttachments(int n) =>
      '$n ${n == 1 ? 'ATTACHMENT' : 'ATTACHMENTS'}';
  static const String mailDownload = 'DOWNLOAD';
  static const String mailDownloading = 'SAVING...';
  static const String mailDownloaded = 'SAVED TO DOWNLOADS.';
  static const String mailDownloadFailed = 'COULD NOT SAVE IT.';
  static const String mailShowImages = 'SHOW IMAGES';
  static const String mailTrashAsk = 'MOVE TO TRASH?';
  static const String mailYes = 'YES';
  static const String mailNo = 'NO';
  static const String mailMoved = 'MOVED TO TRASH.';
  static const String mailGone = 'ALREADY GONE.';
  static const String mailForget = 'FORGET ACCOUNT';
  static const String mailForgetAsk = 'FORGET THIS ACCOUNT AND ITS PASSWORD?';
  static const String mailRefresh = 'REFRESH';
  static const String mailSelect = 'SELECT';
  static const String mailSelectAll = 'SELECT ALL';
  static const String mailCancelSelect = 'CANCEL';
  static String mailSelectedCount(int n) => '$n SELECTED';
  static String mailDeleteSelected(int n) => 'DELETE ($n)';
  static String mailReadSelected(int n) => 'READ ($n)';
  static String mailUnreadSelected(int n) => 'UNREAD ($n)';
  static String mailBulkTrashAsk(int n) =>
      'MOVE $n ${n == 1 ? 'EMAIL' : 'EMAILS'} TO TRASH? THIS CAN\'T BE UNDONE.';
  static String mailBulkDeleting(int done, int total) =>
      'DELETING $done OF $total...';
  static String mailBulkMoved(int n) =>
      '$n ${n == 1 ? 'EMAIL' : 'EMAILS'} MOVED TO TRASH.';
  static String mailBulkMarkedRead(int n) =>
      '$n ${n == 1 ? 'EMAIL' : 'EMAILS'} MARKED AS READ.';
  static String mailBulkMarkedUnread(int n) =>
      '$n ${n == 1 ? 'EMAIL' : 'EMAILS'} MARKED AS UNREAD.';
  static const String mailUpdating = 'UPDATING...';
  static const String mailSavedListing =
      'OFFLINE: SHOWING THE LAST SAVED LIST.';
  static const String mailAlertChannel = 'New mail';
  static const String mailAlertChannelNote =
      'A notification for each new unread email.';
  static String mailAlertMoreTitle(int n) => '$n MORE NEW EMAILS';
  static const String mailAlertMoreBody = 'Open the launcher to read them.';
  static const String mailAlertServiceChannel = 'Watching for mail';
  static const String mailAlertServiceChannelNote =
      'Shown while the launcher keeps a connection to your mail server open for instant new-mail alerts.';
  static const String mailAlertServiceTitle = 'Watching for new mail';
  static const String mailAlertServiceText =
      'The launcher keeps a connection to your mail server open.';
  static const String settingsMailAlerts = 'NEW MAIL ALERTS';
  static const String settingsMailAlertsInstantNote =
      'INSTANT KEEPS A CONNECTION TO THE MAIL SERVER OPEN, SO NEW MAIL IS '
      'ANNOUNCED AT ONCE. ANDROID SHOWS A PERMANENT NOTIFICATION FOR IT, AND '
      'MAY STOP IT UNLESS BATTERY SAVING IS TURNED OFF FOR THE LAUNCHER.';
  static const String settingsMailAlertsBattery =
      'BATTERY SAVING MAY STOP INSTANT ALERTS. TURN IT OFF FOR THE LAUNCHER IN '
      'ANDROID\'S SETTINGS IF THEY STOP.';
  static const String settingsMailAlertsNote =
      'A NOTIFICATION FOR NEW UNREAD EMAIL. EVERY 15 MIN IS A CHECK IN THE '
      'BACKGROUND (THE SHORTEST ANDROID ALLOWS). TAP A NOTIFICATION TO OPEN THAT '
      'EMAIL.';
  static const String settingsMailAlertsDenied =
      'ALLOW NOTIFICATIONS FOR THE LAUNCHER IN ANDROID\'S SETTINGS FIRST.';
  static const String mailLoadingMore = 'LOADING MORE...';
  static const String mailToPrefix = 'TO:';
  static const String mailFolders = 'FOLDERS';
  static const String mailFolderNew = 'NEW';
  static const String mailFolderManage = 'MANAGE';
  static const String mailFolderDone = 'DONE';
  static const String mailFolderName = 'FOLDER NAME';
  static const String mailFolderCreate = 'CREATE';
  static const String mailFolderSave = 'SAVE';
  static const String mailFolderRename = 'RENAME';
  static const String mailFolderDelete = 'DELETE';
  static const String mailFolderWorking = 'WORKING...';
  static String mailFolderDeleteAsk(String label) =>
      'DELETE FOLDER $label? ITS MAIL IS DELETED WITH IT ON MOST SERVERS '
      '(GMAIL JUST REMOVES THE LABEL).';
  static const String mailNoFolders = 'NO FOLDERS FOUND.';
  static const String mailStar = 'STAR';
  static const String mailUnstar = 'UNSTAR';
  static const String mailStarred = 'STARRED.';
  static const String mailUnstarred = 'UNSTARRED.';
  static const String mailStarredSection = 'STARRED';
  static const String mailInboxSection = 'EVERYTHING ELSE';
  static String mailStarSelected(int n) => 'STAR ($n)';
  static String mailUnstarSelected(int n) => 'UNSTAR ($n)';
  static String mailBulkStarred(int n) =>
      '$n ${n == 1 ? 'EMAIL' : 'EMAILS'} STARRED.';
  static String mailBulkUnstarred(int n) =>
      '$n ${n == 1 ? 'EMAIL' : 'EMAILS'} UNSTARRED.';
  static const String mailCompose = 'COMPOSE';
  static const String mailComposeTitle = 'NEW MESSAGE';
  static const String mailSubject = 'SUBJECT';
  static const String mailBody = 'MESSAGE';
  static const String mailSend = 'SEND';
  static const String mailSending = 'SENDING...';
  static const String mailSent = 'SENT.';
  static const String mailSendNeedsTo = 'GIVE IT A RECIPIENT.';
  static const String mailSendNeedsText = 'GIVE IT SOMETHING TO SAY.';

  static const String mailFilter = 'FILTER';
  static const String mailFilterTitle = 'FILTER MAIL';
  static const String mailFilterText = 'TEXT (SUBJECT OR BODY)';
  static const String mailFilterFrom = 'FROM ADDRESS';
  static const String mailFilterTo = 'TO ADDRESS';
  static const String mailFilterOlderThan = 'OLDER THAN';
  static const String mailFilterNewerThan = 'NEWER THAN';
  static const String mailFilterApply = 'APPLY';
  static const String mailFilterClear = 'CLEAR ALL';
  static String mailFilterTextChip(String text) =>
      'TEXT: ${text.toUpperCase()}';
  static String mailFilterFromChip(String from) =>
      'FROM: ${from.toUpperCase()}';
  static String mailFilterToChip(String to) => 'TO: ${to.toUpperCase()}';
  static String mailFilterAgeChip(bool older, int amount, String unit) =>
      '${older ? mailFilterOlderThan : mailFilterNewerThan} $amount $unit';
  static const String mailNoMatches = 'NOTHING MATCHES THESE FILTERS.';

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

  static const String readyTileHint = 'TAP TO RUN TODAY';
  static const String readyLoad = 'LOAD "TODAY",8';
  static const String readySearching = 'SEARCHING FOR TODAY';
  static const String readyEvents = 'NEXT UP';
  static const String readyNoCalendar = 'NO CALENDAR ACCESS.';
  static const String readyNothingPlanned = 'NOTHING PLANNED.';
  static const String readyNothingToDo = 'NOTHING TO DO.';
  static const String readyAllDone = 'ALL DONE.';
  static String readyMore(int n) => '+$n MORE';
  static String readyTodos(int open) => 'TO-DO: $open OPEN';
  static String readyUnread(int n) => 'UNREAD MAIL: $n';
  static const String todoTitle = 'TO-DO';
  static const String todoEmpty = 'NOTHING TO DO.';
  static const String todoAddHint = 'ADD A TO-DO';
  static const String todoAdd = 'ADD';
  static const String todoSelect = 'SELECT';
  static const String todoMove = 'MOVE';
  static const String todoDone = 'DONE';
  static const String todoSelectAll = 'SELECT ALL';
  static const String todoSave = 'SAVE';
  static const String todoCancel = 'CANCEL';
  static const String todoYes = 'YES';
  static const String todoNo = 'NO';
  static const String todoMoveHint = 'DRAG THE HANDLES TO REORDER.';
  static String todoSelectedCount(int n) => '$n SELECTED';
  static String todoDeleteSelected(int n) => 'DELETE ($n)';
  static String todoDeleteAsk(int n) =>
      'DELETE $n ${n == 1 ? 'TO-DO' : 'TO-DOS'}? THIS CAN\'T BE UNDONE.';
  static String todoMore(int n) => '+$n';
  static const String alarmTitle = 'ALARM';
  static const String alarmTabTimer = 'TIMER';
  static const String alarmTabAlarm = 'ALARM';
  static const String alarmNone = '--:--';
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
  static const String settingsTextSize = 'TEXT SIZE';
  static const String settingsTextSizeNote =
      'ON TOP OF THE PHONE\'S OWN TEXT SIZE, NOT INSTEAD OF IT.';
  static const String settingsTextSizePreview = 'THE QUICK BROWN FOX';
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
  static const String settingsEffects = 'TILE EFFECTS';
  static const String settingsEffectsNote =
      'FAINT SCANLINES, A SHINE AND A DITHERED SHADE ON EVERY TILE.';
  static const String settingsAppIcons = 'APP ICONS';
  static const String settingsAppIconsNote =
      'EACH APP OWN PICTURE ON ITS TILE AND IN THE DRAWER, NOT A LETTER.';
  static const String settingsOn = 'ON';
  static const String settingsOff = 'OFF';
  static const String settingsWallpaper = 'WALLPAPER';
  static const String settingsPicture = 'PICTURE';
  static const String settingsPutOn = 'PUT IT ON';
  static const String settingsWallpaperHomeNote =
      'THIS LAUNCHER DRAWS ITS OWN SCREEN, SO A HOME PICTURE SHOWS BEHIND OTHER LAUNCHERS.';
  static const String settingsPictureMissing = 'NO PICTURE.';
  static const String settingsSetWallpaper = 'SET WALLPAPER';
  static const String settingsDefaultWallpaper = 'DEFAULT WALLPAPER';
  static const String settingsWallpaperSet = 'WALLPAPER SET.';
  static const String settingsWallpaperCleared = 'DEFAULT WALLPAPER BACK.';
  static const String settingsWallpaperRefused = 'THE PHONE DOES NOT ALLOW IT.';
  static const String settingsWallpaperFailed = 'COULD NOT DO IT.';
  static String settingsWallpaperAsk(String picture, String screen) =>
      'PUT THE $picture PICTURE ON $screen?';
  static String settingsWallpaperClearAsk(String screen) =>
      'PUT THE PHONE\'S OWN WALLPAPER BACK ON $screen?';
  static const String settingsSystem = 'SYSTEM';
  static const String settingsHomeApp = 'DEFAULT HOME APP';
  static const String settingsHomeActive = 'ACTIVE: THIS IS YOUR HOME APP.';
  static const String settingsHomeNotSet = 'NOT SET: ANOTHER APP IS HOME.';
  static const String settingsHomeUnknown = 'COULD NOT FIND OUT.';
  static const String settingsHomeChecking = 'CHECKING...';
  static const String settingsOpenHome = 'CHOOSE HOME APP';
  static const String settingsMail = 'MAIL';
  static const String settingsSignature = 'SIGNATURE';
  static const String settingsSignatureNote =
      'ADDED TO THE END OF NEW MESSAGES, REPLIES AND FORWARDS.';
  static const String settingsMailAccount = 'ACCOUNT';
  static const String settingsMailChecking = 'CHECKING...';
  static const String settingsMailNotSetUp = 'NOT SET UP.';
  static const String settingsMailForgotten = 'ACCOUNT FORGOTTEN.';
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

  static const String filesTitle = 'FILES';
  static const String filesSubtitle = 'BROWSE STORAGE';
  static const String filesRoot = 'STORAGE';
  static const String filesTapToAllow = 'TAP TO ALLOW FILE ACCESS';
  static const String filesLoading = 'LOADING...';
  static const String filesEmpty = 'NOTHING HERE.';
  static const String filesBack = '< BACK';
  static const String filesDelete = 'DELETE';
  static String filesDeleteAsk(String name) =>
      'DELETE "$name"? THIS CAN\'T BE UNDONE.';
  static const String filesDeleteFailed = 'COULD NOT DELETE THAT.';

  static const String filesColumnName = 'NAME';
  static const String filesColumnModified = 'MODIFIED';
  static const String filesColumnSize = 'SIZE';
  static String filesItemCount(int n) => '$n ITEMS';

  static const String filesSearch = 'SEARCH';

  static const String filesSelect = 'SELECT';
  static const String filesSelectAll = 'SELECT ALL';
  static const String filesCancelSelect = 'CANCEL';
  static String filesSelectedCount(int n) => '$n SELECTED';
  static String filesDeleteSelected(int n) => 'DELETE ($n)';
  static String filesBulkTrashAsk(int n) =>
      'DELETE $n ITEMS? THIS CAN\'T BE UNDONE.';
  static String filesBulkDeleting(int done, int total) =>
      'DELETING $done OF $total...';
  static String filesBulkDeleted(int n) => '$n DELETED';

  static const String filesFilter = 'FILTER';
  static const String filesFilterTitle = 'FILTER FILES';
  static const String filesFilterText = 'NAME CONTAINS';
  static const String filesFilterType = 'TYPE';
  static const String filesFilterOlderThan = 'OLDER THAN';
  static const String filesFilterNewerThan = 'NEWER THAN';
  static const String filesFilterApply = 'APPLY';
  static const String filesFilterClear = 'CLEAR ALL';
  static String filesFilterTextChip(String text) =>
      'NAME: ${text.toUpperCase()}';
  static String filesFilterTypeChip(String type) => 'TYPE: $type';
  static String filesFilterAgeChip(bool older, int amount, String unit) =>
      '${older ? 'OLDER' : 'NEWER'} THAN $amount $unit';
  static const String filesNoMatches = 'NOTHING MATCHES THESE FILTERS.';

  static const String qrScannerTitle = 'QR SCANNER';
  static const String qrScannerSubtitle = 'SCAN A CODE';
  static const String qrScannerTapToAllow = 'TAP TO ALLOW CAMERA ACCESS';
  static const String qrScannerAllowInSettings =
      'ALLOW CAMERA ACCESS IN ANDROID SETTINGS.';
  static const String qrScannerAim = 'AIM AT A QR CODE.';
  static const String qrScannerOpen = 'OPEN';
  static const String qrScannerCopy = 'COPY';
  static const String qrScannerCopied = 'COPIED.';
  static const String qrScannerScanAgain = 'SCAN AGAIN';
  static const String qrScannerOpenFailed = 'COULD NOT OPEN THAT LINK.';

  static const String sceneTitle = 'SCENE';

  static const String mediaTitle = 'NOW PLAYING';
  static const String mediaNothingPlaying = 'NOTHING IS PLAYING.';
  static const String mediaTapToAllow = 'TAP TO ALLOW NOTIFICATION ACCESS';
  static const String mediaTapToRetry = 'TAP TO RETRY';
  static const String mediaPlay = 'PLAY';
  static const String mediaPause = 'PAUSE';
  static const String mediaPrev = '< PREV';
  static const String mediaNext = 'NEXT >';

  static const String helpTitle = 'HELP';

  static const String helpGettingAroundTitle = 'GETTING AROUND';
  static const String helpGettingAroundBody =
      'HOME IS THE MOSAIC OF TILES. SWIPE LEFT TO SEE EVERY APP; SWIPE '
      'DOWN OR UP DOES WHATEVER SETTINGS HAS THEM SET TO (PULL DOWN THE '
      'SHADE OR QUICK SETTINGS, OR OPEN ALL APPS, BY DEFAULT).\n\n'
      'HOLD A TILE TO ENTER THE GRID EDITOR: DRAG IT SOMEWHERE ELSE, OR '
      'PICK IT TO CHANGE ITS SIZE OR COLOUR BELOW, THEN APPLY. + ADD '
      'TILE PINS A NEW APP OR LIVE TILE; ITS OWN X UNPINS ONE.\n\n'
      'MOVE MANY (TOP RIGHT IN THE EDITOR) LETS YOU TAP SEVERAL TILES, THEN '
      'HOLD ONE OF THEM AND DRAG: THEY ALL MOVE TOGETHER TO ONE DROP LINE.';

  static const String helpTilesTitle = 'LIVE TILES';
  static const String helpTilesBody =
      'AN APP TILE OPENS THAT APP. THE REST SHOW SOMETHING AND OFTEN '
      'OPEN A PANE FOR MORE:\n\n'
      'CLOCK — THE TIME AND DATE.\n'
      'DEVICE — BATTERY, FREE STORAGE, FREE MEMORY.\n'
      'WEATHER — THE FORECAST WHERE THE PHONE IS.\n'
      'AGENDA — COMING CALENDAR EVENTS.\n'
      'CONTACT — CALL, TEXT OR OPEN WHATSAPP FOR ONE PERSON.\n'
      'MAIL — THE INBOX AND THE ACCOUNT\'S OTHER FOLDERS (THE FOLDER '
      'BUTTON; MANAGE THERE TO CREATE, RENAME OR DELETE YOUR OWN); SCROLL FOR OLDER MAIL, TAP A MESSAGE TO READ IT, SELECT TO '
      'STAR, MARK OR DELETE. SETTINGS CAN ALERT YOU TO NEW MAIL (EVERY 15 MIN, '
      'OR INSTANT); TAP THE NOTIFICATION TO OPEN THAT EMAIL.\n'
      'TEXT TV — HEADLINE PAGES, THE OLD TELETEXT WAY.\n'
      'CALC — A CALCULATOR AND UNIT/CURRENCY CONVERTER.\n'
      'ALARM — THE NEXT ALARM DUE; SETS TIMERS AND ALARMS THROUGH THE '
      'CLOCK APP.\n'
      'SOUND — CYCLES THE RINGER BETWEEN NORMAL, VIBRATE AND SILENT.\n'
      'FLASHLIGHT — TOGGLES THE TORCH.\n'
      'FILES — BROWSES AND DELETES ANYWHERE ON THE PHONE\'S STORAGE.\n'
      'NOW PLAYING — WHAT IS PLAYING IN SPOTIFY OR ANY OTHER MUSIC APP; '
      'TAP FOR BIGGER ART AND FULL CONTROLS.\n'
      'READY. — TAP TO WATCH THE PHONE "LOAD" TODAY: THE DATE, THE NEXT '
      'EVENTS, OPEN TO-DOS AND UNREAD MAIL, THE C64 WAY.\n'
      'TO-DO — A SIMPLE LIST; TAP TO ADD, CHECK OFF, EDIT, REORDER OR '
      'DELETE.';

  static const String helpResizingTitle = 'RESIZING A TILE';
  static const String helpResizingBody =
      'IN THE GRID EDITOR, THE SIZE GRID PAINTS A TILE\'S SHAPE FROM '
      'ITS TOP-LEFT CORNER: TAP OR DRAG TOWARD A SQUARE TO PICK EVERY '
      'SIZE UP TO THAT ONE.';

  static const String helpSettingsTitle = 'SETTINGS';
  static const String helpSettingsBody =
      'THEME PICKS THE CANVAS; GRID SETS HOW MANY COLUMNS AND HOW MUCH '
      'AIR BETWEEN TILES; TEXT SIZE ADDS ON TOP OF THE PHONE\'S OWN '
      'ACCESSIBILITY SIZE, NEVER REPLACES IT. GESTURES, HAPTICS, TILE '
      'EFFECTS AND APP ICONS ARE ALL SWITCHES. WALLPAPER PUTS ONE OF '
      'THE THEME PICTURES ON THE LOCK OR HOME SCREEN. LAYOUT CAN '
      'EXPORT OR IMPORT THE WHOLE HOME SCREEN AS TEXT (HANDY BEFORE '
      'TRYING SOMETHING RISKY), OR CLEAR IT AND RESET SETTINGS '
      'OUTRIGHT.';

  static const String helpPrivacyTitle = 'YOUR DATA';
  static const String helpPrivacyBody =
      'NOTHING LEAVES THE PHONE EXCEPT WHAT EACH TILE NEEDS TO: '
      'WEATHER ASKS A FORECAST SERVICE FOR ROUGHLY WHERE THE PHONE IS, '
      'AND MAIL TALKS ONLY TO THE IMAP SERVER IT WAS SET UP WITH — ITS '
      'APP PASSWORD IS KEPT ENCRYPTED ON THIS PHONE ONLY, NEVER BACKED '
      'UP. CALENDAR, CONTACTS AND FILES ARE ALL READ DIRECTLY FROM '
      'ANDROID ON THIS PHONE, ASKED FOR ONLY WHEN THE '
      'TILE THAT NEEDS THEM IS FIRST ADDED OR OPENED. NOW PLAYING READS '
      'TITLES AND ART FROM WHATEVER MUSIC APP IS OPEN, WHICH NEEDS '
      'NOTIFICATION ACCESS — A SETTING YOU TURN ON YOURSELF, NOT ASKED '
      'FOR AUTOMATICALLY.';

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
