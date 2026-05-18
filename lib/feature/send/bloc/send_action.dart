import 'package:transaction/transaction.dart';

sealed class SendAction {}

/// Coin selection found no strategy that covers the requested amount.
final class SendInsufficientFundsAction extends SendAction {}

/// Transaction preparation or broadcast failed.
final class SendFailedAction extends SendAction {
  final TransactionException exception;

  SendFailedAction({required this.exception});
}

/// An unexpected programmer error occurred during preparation or broadcast.
///
/// Emitted alongside [Bloc.addError] so the zone handler gets the original
/// error while the UI still shows a generic failure message.
final class SendUnexpectedFailedAction extends SendAction {}

