sealed class SigningEvent {
  const SigningEvent();
}

/// Scan UTXO set for stored native SegWit addresses of [walletId].
final class UtxoScanRequested extends SigningEvent {
  final String walletId;

  const UtxoScanRequested({required this.walletId});
}

/// Sign all scanned UTXOs as inputs and broadcast the transaction.
final class SignAndBroadcastRequested extends SigningEvent {
  final String walletId;
  final String recipientAddress;
  final int amountSat;
  final String bech32Hrp;

  const SignAndBroadcastRequested({
    required this.walletId,
    required this.recipientAddress,
    required this.amountSat,
    required this.bech32Hrp,
  });
}
