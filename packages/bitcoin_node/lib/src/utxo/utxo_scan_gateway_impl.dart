import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

/// Scans the UTXO set for UTXOs belonging to a list of addresses.
///
/// Uses `scantxoutset "start" [...]` — no wallet required.
/// Wraps RPC / network / parse failures (and the "scan unsuccessful"
/// signal) as [TransactionUtxoScanException].
final class UtxoScanGatewayImpl implements UtxoScanGateway {
  final BitcoinRpcClient _rpcClient;

  const UtxoScanGatewayImpl({required this._rpcClient});

  @override
  Future<List<ScannedUtxo>> scanForAddresses(List<String> addresses) async {
    if (addresses.isEmpty) return [];

    try {
      final descriptors = addresses.map((addr) => {'desc': 'addr($addr)'}).toList();

      final result = await _rpcClient.call('scantxoutset', ['start', descriptors]);
      final map = result as Map<String, Object?>;

      if (map['success'] != true) {
        throw const TransactionUtxoScanException();
      }

      final unspents = (map['unspents'] as List<Object?>? ?? []).cast<Map<String, Object?>>();

      return unspents.map(_mapScannedUtxo).toList();
    } on TransactionUtxoScanException {
      // Local "success: false" throw — preserve type, do not re-wrap.
      rethrow;
    } catch (_, stack) {
      Error.throwWithStackTrace(const TransactionUtxoScanException(), stack);
    }
  }

  ScannedUtxo _mapScannedUtxo(Map<String, Object?> raw) {
    final btcAmount = raw['amount'] as num;

    return ScannedUtxo(
      txid: raw['txid'] as String,
      vout: (raw['vout'] as num).toInt(),
      amountSat: Satoshi.fromBtc(btcAmount),
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
