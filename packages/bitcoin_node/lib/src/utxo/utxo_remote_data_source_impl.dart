import 'package:bitcoin_node/src/utxo/address_type_rpc_mapper.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

/// Fetches unspent transaction outputs (UTXOs) from Bitcoin Core.
///
/// Calls `listunspent` and maps responses to [Utxo] entities.
final class UtxoRemoteDataSourceImpl implements UtxoRemoteDataSource {
  final BitcoinRpcClient _rpcClient;

  const UtxoRemoteDataSourceImpl({required BitcoinRpcClient rpcClient}) : _rpcClient = rpcClient;

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

  Utxo _mapUtxo(Map<String, Object?> raw) {
    final btcAmount = raw['amount'] as num;
    final scriptPubKeyHex = raw['scriptPubKey'] as String? ?? '';
    final desc = raw['desc'] as String?;

    // Try descriptor first (modern Bitcoin Core), fall back to type string (older nodes)
    final type = desc != null
        ? AddressTypeRpcMapper.fromDescriptor(desc)
        : AddressTypeRpcMapper.fromScriptType(raw['type'] as String? ?? 'unknown');

    return Utxo(
      txid: raw['txid'] as String,
      vout: (raw['vout'] as num).toInt(),
      amountSat: _btcToSat(btcAmount),
      confirmations: (raw['confirmations'] as num?)?.toInt() ?? 0,
      address: raw['address'] as String?,
      scriptPubKey: scriptPubKeyHex,
      type: type,
      spendable: raw['spendable'] as bool? ?? false,
      derivationPath: _parseDerivationPath(desc),
    );
  }

  /// Extracts the BIP derivation path from a Bitcoin Core descriptor.
  ///
  /// Descriptor format: `type([fingerprint/path]pubkey)#checksum`
  /// Returns `m/path` with `h` normalized to `'`, or null if not parseable.
  static String? _parseDerivationPath(String? desc) {
    if (desc == null) return null;

    final start = desc.indexOf('[');
    final end = desc.indexOf(']');
    if (start == -1 || end <= start) return null;

    // inner: e.g. "abc12345/84h/1h/0h/0/5"
    final inner = desc.substring(start + 1, end);
    final slashIdx = inner.indexOf('/');
    if (slashIdx == -1) return null;

    // Normalize 'h' → "'" for standard BIP notation
    final path = inner.substring(slashIdx + 1).replaceAll('h', "'");

    return 'm/$path';
  }

  /// Converts BTC amount (num) to satoshis as [Satoshi] value object.
  ///
  /// Uses rounding to avoid floating-point precision errors.
  /// e.g. 0.001 BTC → Satoshi(100000)
  static Satoshi _btcToSat(num btc) => Satoshi((btc * 100000000).round());
}
