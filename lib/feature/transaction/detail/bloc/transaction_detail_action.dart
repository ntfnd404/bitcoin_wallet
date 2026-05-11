import 'package:transaction/transaction.dart';

sealed class TransactionDetailAction {}

/// Transaction detail fetch failed.
final class TransactionDetailErrorOccurred extends TransactionDetailAction {
  final TransactionException exception;

  TransactionDetailErrorOccurred({required this.exception});
}
