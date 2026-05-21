sealed class OpReturnAction {}

/// Broadcast succeeded — carries the txid.
final class OpReturnBroadcastedAction extends OpReturnAction {
  final String txid;

  OpReturnBroadcastedAction(this.txid);
}

/// Broadcast failed with a known error.
final class OpReturnBroadcastFailedAction extends OpReturnAction {
  final String message;

  OpReturnBroadcastFailedAction(this.message);
}

/// Broadcast failed with an unexpected (non-domain) error.
final class OpReturnUnexpectedFailedAction extends OpReturnAction {}
