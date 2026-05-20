import 'package:transaction/transaction.dart';

sealed class UtxoAction {}

/// A UTXO list or refresh operation failed.
final class UtxoErrorOccurredAction extends UtxoAction {
  final TransactionException exception;

  UtxoErrorOccurredAction({required this.exception});
}
