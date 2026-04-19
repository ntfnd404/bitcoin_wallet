import 'package:transaction/src/domain/entity/transaction.dart';
import 'package:transaction/src/domain/entity/transaction_detail.dart';

/// Contract for fetching wallet transactions.
abstract interface class TransactionRepository {
  /// Returns all transactions for the wallet identified by [walletName].
  ///
  /// Includes both confirmed and mempool (unconfirmed) transactions.
  Future<List<Transaction>> getTransactions(String walletName);

  /// Returns full detail for a single transaction identified by [txid].
  Future<TransactionDetail> getTransactionDetail(String txid, String walletName);
}
