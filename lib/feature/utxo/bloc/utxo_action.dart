import 'package:transaction/transaction.dart';

sealed class UtxoAction {}

/// A UTXO list or refresh operation failed.
final class UtxoErrorOccurred extends UtxoAction {
  final TransactionException exception;

  UtxoErrorOccurred({required this.exception});
}
