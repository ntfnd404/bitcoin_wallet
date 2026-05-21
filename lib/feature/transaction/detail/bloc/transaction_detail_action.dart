import 'package:transaction/transaction.dart';

sealed class TransactionDetailAction {}

/// Transaction detail fetch failed with a known domain exception.
final class TransactionDetailErrorOccurredAction extends TransactionDetailAction {
  final TransactionException exception;

  TransactionDetailErrorOccurredAction({required this.exception});
}

/// Transaction detail fetch failed with an unexpected (non-domain) error.
final class TransactionDetailUnexpectedFailedAction extends TransactionDetailAction {
  TransactionDetailUnexpectedFailedAction();
}
