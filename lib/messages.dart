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
}
