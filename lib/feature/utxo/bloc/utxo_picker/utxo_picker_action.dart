import 'package:transaction/transaction.dart';

sealed class UtxoPickerAction {}

/// UTXO list load failed with a known domain exception.
final class UtxoPickerLoadFailedAction extends UtxoPickerAction {
  final TransactionException exception;

  UtxoPickerLoadFailedAction({required this.exception});
}

/// UTXO list load failed with an unexpected error.
final class UtxoPickerUnexpectedFailedAction extends UtxoPickerAction {}
