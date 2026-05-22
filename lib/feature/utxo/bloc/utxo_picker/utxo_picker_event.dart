sealed class UtxoPickerEvent {
  const UtxoPickerEvent();
}

/// Triggers the initial UTXO list load for [walletName].
final class UtxoPickerLoaded extends UtxoPickerEvent {
  final String walletName;

  const UtxoPickerLoaded({required this.walletName});
}

/// Toggles selection of the UTXO identified by [txid] and [vout].
final class UtxoPickerSelectionToggled extends UtxoPickerEvent {
  final String txid;
  final int vout;

  const UtxoPickerSelectionToggled({required this.txid, required this.vout});
}

/// Updates the fee rate used for the running total estimate.
final class UtxoPickerFeeRateChanged extends UtxoPickerEvent {
  final int feeRateSatPerVbyte;

  const UtxoPickerFeeRateChanged({required this.feeRateSatPerVbyte});
}
