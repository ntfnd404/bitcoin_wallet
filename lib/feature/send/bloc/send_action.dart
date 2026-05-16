import 'package:transaction/transaction.dart';

sealed class SendAction {}

/// Coin selection found no strategy that covers the requested amount.
final class SendInsufficientFundsAction extends SendAction {}

/// Transaction preparation or broadcast failed.
final class SendFailedAction extends SendAction {
  final TransactionException exception;

  SendFailedAction({required this.exception});
}

