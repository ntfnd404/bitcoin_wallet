import 'package:transaction/src/domain/entity/transaction.dart';
import 'package:transaction/src/domain/entity/transaction_detail.dart';

/// ISP interface for fetching transaction history from a Bitcoin node.
///
/// Owned by the transaction module (consumer) — the adapter in bitcoin_node
/// implements this contract, not the other way around.
abstract interface class TransactionRemoteDataSource {
  /// Fetches wallet transactions via `listtransactions`.
  ///
  /// [walletName] is the Bitcoin Core wallet name.
  /// Returns transactions ordered by most recent first.
  Future<List<Transaction>> getTransactions(String walletName);

  /// Fetches full transaction detail via `gettransaction <txid> true`.
  ///
  /// Returns decoded inputs, outputs, size, weight, and raw hex.
  Future<TransactionDetail> getTransactionDetail(String txid, String walletName);
}
