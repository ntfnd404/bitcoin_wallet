/// A typed output entry for raw transaction construction.
sealed class TxOutput {
  const TxOutput();
}

/// Sends [amountBtc] to a Bitcoin address.
final class AddressOutput extends TxOutput {
  final String address;

  /// Amount in BTC (8 decimal places).
  final double amountBtc;

  const AddressOutput({required this.address, required this.amountBtc});
}

/// Embeds [dataHex] on-chain as an unspendable OP_RETURN output (0 sat).
///
/// [dataHex] is the raw data bytes in hex — Bitcoin Core prepends the
/// OP_RETURN opcode and push encoding when constructing the script.
final class OpReturnOutput extends TxOutput {
  final String dataHex;

  const OpReturnOutput(this.dataHex);
}
