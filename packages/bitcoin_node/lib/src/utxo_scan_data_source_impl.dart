import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

/// Scans the UTXO set for UTXOs belonging to a list of addresses.
///
/// Uses `scantxoutset "start" [...]` — no wallet required.
final class UtxoScanDataSourceImpl implements UtxoScanDataSource {
  final BitcoinRpcClient _rpcClient;

  const UtxoScanDataSourceImpl({required BitcoinRpcClient rpcClient})
      : _rpcClient = rpcClient;

  @override
  Future<List<ScannedUtxo>> scanForAddresses(List<String> addresses) async {
    if (addresses.isEmpty) return [];

    final descriptors = addresses
        .map((addr) => {'desc': 'addr($addr)'})
        .toList();

    final result = await _rpcClient.call('scantxoutset', ['start', descriptors]);
    final map = result as Map<String, Object?>;

    if (map['success'] != true) {
      throw StateError('scantxoutset failed');
    }

    final unspents = (map['unspents'] as List<Object?>? ?? [])
        .cast<Map<String, Object?>>();

    return unspents.map(_mapScannedUtxo).toList();
  }

  ScannedUtxo _mapScannedUtxo(Map<String, Object?> raw) {
    final btcAmount = raw['amount'] as num;

    return ScannedUtxo(
      txid: raw['txid'] as String,
      vout: (raw['vout'] as num).toInt(),
      amountSat: Satoshi((btcAmount * 100000000).round()),
      scriptPubKeyHex: raw['scriptPubKey'] as String? ?? '',
      height: (raw['height'] as num?)?.toInt() ?? 0,
      address: _parseAddress(raw['desc'] as String?),
    );
  }

  /// Extracts the address from a descriptor like `addr(bcrt1q...)#checksum`.
  static String? _parseAddress(String? desc) {
    if (desc == null) return null;
    final start = desc.indexOf('(');
    final end = desc.indexOf(')');
    if (start == -1 || end == -1 || end <= start) return null;

    return desc.substring(start + 1, end);
  }
}
