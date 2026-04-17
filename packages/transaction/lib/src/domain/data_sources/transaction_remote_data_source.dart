import 'package:transaction/src/domain/entity/transaction.dart';
import 'package:transaction/src/domain/entity/utxo.dart';

/// ISP interface for fetching on-chain data from a Bitcoin node.
///
/// Owned by the transaction module (consumer) — the adapter in bitcoin_node
/// implements this contract, not the other way around.
abstract interface class TransactionRemoteDataSource {
  /// Fetches wallet transactions via `listtransactions`.
  ///
  /// [walletName] is the Bitcoin Core wallet name.
  /// Returns transactions ordered by most recent first.
  Future<List<Transaction>> getTransactions(String walletName);

  /// Fetches unspent outputs via `listunspent`.
  ///
  /// [walletName] is the Bitcoin Core wallet name.
  Future<List<Utxo>> getUtxos(String walletName);
}
