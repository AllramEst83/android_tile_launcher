sealed class WhatsAppResult {
  const WhatsAppResult();
}

/// WhatsApp (or a browser, if it is not installed) opened with the chat
/// ready; the user still has to type and send there.
class WhatsAppOpened extends WhatsAppResult {
  const WhatsAppOpened();
}

/// Nothing opened; [reason] is short and printable.
class WhatsAppFailed extends WhatsAppResult {
  const WhatsAppFailed(this.reason);

  final String reason;
}

/// Hands a chat off to WhatsApp via its public `wa.me` link. There is no API
/// to send silently, and none is wanted: the chat is only ever opened, never
/// sent to, so no permission is needed.
abstract interface class WhatsAppService {
  /// [number] is international, digits only (see `whatsAppNumber`). Never
  /// throws; every failure is a [WhatsAppFailed].
  Future<WhatsAppResult> openChat(String number);
}
