import 'package:transaction/src/domain/entity/transaction.dart';

/// Contract for fetching wallet transactions.
abstract interface class TransactionRepository {
  /// Returns all transactions for the wallet identified by [walletName].
  ///
  /// Includes both confirmed and mempool (unconfirmed) transactions.
  Future<List<Transaction>> getTransactions(String walletName);
}
