import 'package:transaction/src/domain/entity/scanned_utxo.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/utxo_scan_gateway.dart';

/// Scans the UTXO set for outputs at a list of HD wallet addresses.
///
/// Uses `scantxoutset` — does not require a Bitcoin Core wallet.
final class ScanUtxosUseCase {
  final UtxoScanGateway _dataSource;

  const ScanUtxosUseCase({required UtxoScanGateway dataSource}) : _dataSource = dataSource;

  Future<List<ScannedUtxo>> call(List<String> addresses) async {
    try {
      return await _dataSource.scanForAddresses(addresses);
    } on TransactionException {
      rethrow;
    }
    // RpcException propagates intentionally — already typed at the gateway layer.
  }
}
