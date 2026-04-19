sealed class XpubEvent {
  const XpubEvent();
}

final class XpubLoadRequested extends XpubEvent {
  final String walletId;

  const XpubLoadRequested({required this.walletId});
}
