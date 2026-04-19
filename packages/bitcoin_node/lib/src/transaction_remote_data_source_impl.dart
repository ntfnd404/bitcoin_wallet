import 'package:bitcoin_node/src/transaction_direction_rpc_mapper.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

/// Fetches wallet transaction history from Bitcoin Core.
///
/// Calls `listtransactions` for list and `gettransaction` for detail.
final class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final BitcoinRpcClient _rpcClient;

  const TransactionRemoteDataSourceImpl({required BitcoinRpcClient rpcClient})
      : _rpcClient = rpcClient;

  @override
  Future<List<Transaction>> getTransactions(String walletName) async {
    // count=1000 — sufficient for regtest; skip=0
    final result = await _rpcClient.call(
      'listtransactions',
      ['*', 1000, 0, true],
      walletName,
    );

    final list = result as List<Object?>;

    return list
        .cast<Map<String, Object?>>()
        .map(_mapTransaction)
        .toList()
        .reversed
        .toList(); // most recent first
  }

  @override
  Future<TransactionDetail> getTransactionDetail(
    String txid,
    String walletName,
  ) async {
    // verbose=true returns the decoded transaction in the "decoded" field
    final result = await _rpcClient.call(
      'gettransaction',
      [txid, true],
      walletName,
    );

    final raw = result as Map<String, Object?>;

    // Amount and direction from wallet perspective
    final btcAmount = raw['amount'] as num;
    final btcFee = raw['fee'] as num?;
    final direction = btcAmount >= 0
        ? TransactionDirection.incoming
        : TransactionDirection.outgoing;

    final confirmations = (raw['confirmations'] as num?)?.toInt() ?? 0;
    final unixTime =
        (raw['time'] as num?)?.toInt() ??
        (raw['timereceived'] as num?)?.toInt() ??
        0;

    final transaction = Transaction(
      txid: txid,
      direction: direction,
      amountSat: _btcToSat(btcAmount),
      feeSat: btcFee != null ? _btcToSat(btcFee) : null,
      confirmations: confirmations,
      timestamp: DateTime.fromMillisecondsSinceEpoch(unixTime * 1000),
    );

    final decoded = raw['decoded'] as Map<String, Object?>? ?? {};
    final size = (decoded['size'] as num?)?.toInt() ?? 0;
    final weight = (decoded['weight'] as num?)?.toInt() ?? 0;
    final hex = raw['hex'] as String? ?? '';

    final vinList =
        (decoded['vin'] as List<Object?>?)?.cast<Map<String, Object?>>() ?? [];
    final voutList =
        (decoded['vout'] as List<Object?>?)?.cast<Map<String, Object?>>() ?? [];

    return TransactionDetail(
      transaction: transaction,
      inputs: vinList.map(_mapInput).toList(),
      outputs: voutList.map(_mapOutput).toList(),
      size: size,
      weight: weight,
      hex: hex,
    );
  }

  Transaction _mapTransaction(Map<String, Object?> raw) {
    final btcAmount = raw['amount'] as num;
    final btcFee = raw['fee'] as num?;

    final category = raw['category'] as String;
    final direction = TransactionDirectionRpcMapper.fromRpcCategory(category);

    final confirmations = (raw['confirmations'] as num?)?.toInt() ?? 0;

    final unixTime =
        (raw['time'] as num?)?.toInt() ??
        (raw['timereceived'] as num?)?.toInt() ??
        0;

    return Transaction(
      txid: raw['txid'] as String,
      direction: direction,
      amountSat: _btcToSat(btcAmount),
      feeSat: btcFee != null ? _btcToSat(btcFee) : null,
      confirmations: confirmations,
      timestamp: DateTime.fromMillisecondsSinceEpoch(unixTime * 1000),
    );
  }

  TransactionInput _mapInput(Map<String, Object?> raw) {
    final isCoinbase = raw.containsKey('coinbase');
    final scriptSig = raw['scriptSig'] as Map<String, Object?>?;
    final witnessList =
        (raw['txinwitness'] as List<Object?>?)?.cast<String>() ?? [];

    return TransactionInput(
      prevTxid: isCoinbase ? null : raw['txid'] as String?,
      prevVout: isCoinbase ? null : (raw['vout'] as num?)?.toInt(),
      scriptSigHex: scriptSig?['hex'] as String? ?? '',
      witness: witnessList,
      sequence: (raw['sequence'] as num?)?.toInt() ?? 0,
    );
  }

  TransactionOutput _mapOutput(Map<String, Object?> raw) {
    final scriptPubKey = raw['scriptPubKey'] as Map<String, Object?>? ?? {};
    final btcValue = raw['value'] as num? ?? 0;

    return TransactionOutput(
      n: (raw['n'] as num?)?.toInt() ?? 0,
      amountSat: _btcToSat(btcValue),
      address: scriptPubKey['address'] as String?,
      scriptPubKeyHex: scriptPubKey['hex'] as String? ?? '',
    );
  }

  /// Converts BTC amount (num) to satoshis as [Satoshi] value object.
  ///
  /// Uses rounding to avoid floating-point precision errors.
  /// e.g. 0.001 BTC → Satoshi(100000)
  static Satoshi _btcToSat(num btc) => Satoshi((btc * 100000000).round());
}
