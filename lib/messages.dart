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
}
