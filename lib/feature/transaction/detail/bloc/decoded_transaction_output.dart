import 'package:transaction/transaction.dart';

/// Pairs a [TransactionOutput] with its pre-decoded script data.
///
/// Computed once in [TransactionDetailBloc] when the detail is loaded.
final class DecodedTransactionOutput {
  final TransactionOutput output;

  /// Script type label, e.g. "P2WPKH".
  final String scriptTypeLabel;

  /// Human-readable asm string of the locking script.
  final String asm;

  const DecodedTransactionOutput({
    required this.output,
    required this.scriptTypeLabel,
    required this.asm,
  });
}
