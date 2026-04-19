import 'package:shared_kernel/shared_kernel.dart';

/// A single output within a decoded transaction.
final class TransactionOutput {
  /// Output index within the transaction.
  final int n;

  /// Amount in satoshis.
  final Satoshi amountSat;

  /// Receiving address. Null for OP_RETURN and other unaddressable outputs.
  final String? address;

  /// Raw scriptPubKey in hex.
  final String scriptPubKeyHex;

  const TransactionOutput({
    required this.n,
    required this.amountSat,
    required this.address,
    required this.scriptPubKeyHex,
  });
}
