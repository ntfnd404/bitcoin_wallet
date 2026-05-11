import 'package:transaction/transaction.dart';

sealed class SendAction {}

/// Coin selection found no strategy that covers the requested amount.
final class SendInsufficientFunds extends SendAction {}

/// Transaction preparation or broadcast failed.
final class SendFailed extends SendAction {
  final TransactionException exception;

  SendFailed({required this.exception});
}

/// Block mining failed (regtest dev helper).
final class SendMiningFailed extends SendAction {
  final TransactionException exception;

  SendMiningFailed({required this.exception});
}
