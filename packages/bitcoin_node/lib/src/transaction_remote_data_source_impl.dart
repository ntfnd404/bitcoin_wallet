import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

/// [TransactionRemoteDataSource] backed by [BitcoinRpcClient].
///
/// Calls Bitcoin Core RPC methods and maps responses to domain entities.
/// No DTOs — JSON maps are parsed directly to entities here.
final class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final BitcoinRpcClient _rpcClient;

  // Bitcoin Core `listtransactions` category values
  static const _categoryReceive = 'receive';
  static const _categoryGenerate = 'generate';
  static const _categoryImmature = 'immature';

  // Bitcoin Core `listunspent` scriptPubKey type values
  static const _typeP2pkh = 'pubkeyhash';
  static const _typeP2sh = 'scripthash';
  static const _typeP2wpkh = 'witness_v0_keyhash';
  static const _typeP2wsh = 'witness_v0_scripthash';
  static const _typeP2tr = 'witness_v1_taproot';

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
  Future<List<Utxo>> getUtxos(String walletName) async {
    // minconf=0 to include mempool UTXOs
    final result = await _rpcClient.call(
      'listunspent',
      [0],
      walletName,
    );

    final list = result as List<Object?>;

    return list.cast<Map<String, Object?>>().map(_mapUtxo).toList();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Transaction _mapTransaction(Map<String, Object?> raw) {
    // Bitcoin Core returns amount in BTC (float) — convert to satoshis
    final btcAmount = (raw['amount'] as num).toDouble();
    final btcFee = raw['fee'] != null ? (raw['fee'] as num).toDouble() : null;

    final category = raw['category'] as String;
    final direction = _mapDirection(category);

    // confirmations may be absent for mempool txs — default to 0
    final confirmations = (raw['confirmations'] as num?)?.toInt() ?? 0;

    // Bitcoin Core returns Unix timestamp as int
    final unixTime = (raw['time'] as num?)?.toInt() ??
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

  Utxo _mapUtxo(Map<String, Object?> raw) {
    final btcAmount = (raw['amount'] as num).toDouble();
    final scriptPubKeyHex = raw['scriptPubKey'] as String? ?? '';
    final scriptType = raw['desc'] != null
        ? _mapScriptTypeFromDesc(raw['desc'] as String)
        : _mapScriptTypeFromKey(raw['scriptPubKey'] as String? ?? '');

    return Utxo(
      txid: raw['txid'] as String,
      vout: (raw['vout'] as num).toInt(),
      amountSat: _btcToSat(btcAmount),
      confirmations: (raw['confirmations'] as num?)?.toInt() ?? 0,
      address: raw['address'] as String? ?? '',
      scriptPubKey: scriptPubKeyHex,
      type: scriptType,
      spendable: raw['spendable'] as bool? ?? false,
    );
  }

  /// Converts BTC amount (float) to satoshis (int).
  ///
  /// Uses rounding to avoid floating-point precision errors.
  /// e.g. 0.001 BTC → 100000 satoshis
  static int _btcToSat(double btc) => (btc * 100000000).round();

  TransactionDirection _mapDirection(String category) => switch (category) {
    _categoryReceive || _categoryGenerate || _categoryImmature => TransactionDirection.incoming,
    _ => TransactionDirection.outgoing,
  };

  /// Maps Bitcoin Core scriptPubKey type string to [AddressType].
  ///
  /// Bitcoin Core type values:
  /// - "pubkeyhash"            → P2PKH (legacy)
  /// - "scripthash"            → P2SH (wrapped SegWit)
  /// - "witness_v0_keyhash"    → P2WPKH (native SegWit)
  /// - "witness_v0_scripthash" → P2WSH
  /// - "witness_v1_taproot"    → P2TR (Taproot)
  AddressType _mapScriptTypeFromKey(String scriptType) => switch (scriptType) {
    _typeP2pkh => AddressType.legacy,
    _typeP2sh => AddressType.wrappedSegwit,
    _typeP2wpkh => AddressType.nativeSegwit,
    _typeP2wsh => AddressType.nativeSegwit, // P2WSH treated as nativeSegwit for display
    _typeP2tr => AddressType.taproot,
    _ => AddressType.legacy, // fallback
  };

  /// Infers address type from the descriptor string (e.g. "wpkh(...)").
  AddressType _mapScriptTypeFromDesc(String desc) {
    if (desc.startsWith('tr(')) return AddressType.taproot;
    if (desc.startsWith('wpkh(')) return AddressType.nativeSegwit;
    if (desc.startsWith('sh(wpkh(')) return AddressType.wrappedSegwit;
    if (desc.startsWith('pkh(')) return AddressType.legacy;

    return AddressType.legacy; // fallback
  }
}
