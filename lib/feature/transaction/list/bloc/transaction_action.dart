import 'package:transaction/transaction.dart';

sealed class TransactionAction {}

/// A transaction list or refresh fetch failed.
final class TransactionErrorOccurred extends TransactionAction {
  final TransactionException exception;

  TransactionErrorOccurred({required this.exception});
}
