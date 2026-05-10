import 'package:transaction/src/domain/entity/transaction.dart';
import 'package:transaction/src/domain/entity/transaction_detail.dart';

/// Outbound port for fetching transaction history from a Bitcoin node.
abstract interface class TransactionHistoryGateway {
  /// Fetches wallet transactions via `listtransactions`.
  Future<List<Transaction>> getTransactions(String walletName);

  /// Fetches full transaction detail via `gettransaction <txid> true`.
  Future<TransactionDetail> getTransactionDetail(String txid, String walletName);
}
