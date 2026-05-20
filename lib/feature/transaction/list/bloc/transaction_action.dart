import 'package:transaction/transaction.dart';

sealed class TransactionAction {}

/// A transaction list or refresh fetch failed.
final class TransactionErrorOccurredAction extends TransactionAction {
  final TransactionException exception;

  TransactionErrorOccurredAction({required this.exception});
}
