import 'package:transaction/transaction.dart';

/// Pairs a [TransactionInput] with its pre-decoded script data.
///
/// Computed once in [TransactionDetailBloc] when the detail is loaded.
final class DecodedTransactionInput {
  final TransactionInput input;

  /// Human-readable asm of the unlocking script or witness stack.
  /// Empty for coinbase inputs.
  final String asm;

  const DecodedTransactionInput({
    required this.input,
    required this.asm,
  });
}
