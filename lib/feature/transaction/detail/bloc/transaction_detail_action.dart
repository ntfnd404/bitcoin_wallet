import 'package:transaction/transaction.dart';

sealed class TransactionDetailAction {}

/// Transaction detail fetch failed.
final class TransactionDetailErrorOccurredAction extends TransactionDetailAction {
  final TransactionException exception;

  TransactionDetailErrorOccurredAction({required this.exception});
}
