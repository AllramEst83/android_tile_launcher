sealed class LinkResult {
  const LinkResult();
}

/// A browser (or whatever app handles the link) opened with it.
class LinkOpened extends LinkResult {
  const LinkOpened();
}

/// Nothing opened; [reason] is short and printable.
class LinkFailed extends LinkResult {
  const LinkFailed(this.reason);

  final String reason;
}

/// Opens a `http`/`https` link in whatever app handles it — the QR scanner's
/// own OPEN action on a decoded URL. `ACTION_VIEW` needs no permission.
abstract interface class LinkService {
  /// Never throws; every failure is a [LinkFailed].
  Future<LinkResult> open(String url);
}
