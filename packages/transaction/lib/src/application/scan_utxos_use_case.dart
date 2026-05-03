import 'package:transaction/src/domain/data_sources/utxo_scan_data_source.dart';
import 'package:transaction/src/domain/entity/scanned_utxo.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';

/// Scans the UTXO set for outputs at a list of HD wallet addresses.
///
/// Uses `scantxoutset` — does not require a Bitcoin Core wallet.
final class ScanUtxosUseCase {
  final UtxoScanDataSource _dataSource;

  const ScanUtxosUseCase({required UtxoScanDataSource dataSource}) : _dataSource = dataSource;

  Future<List<ScannedUtxo>> call(List<String> addresses) async {
    try {
      return await _dataSource.scanForAddresses(addresses);
    } catch (e, stack) {
      Error.throwWithStackTrace(const TransactionUtxoScanException(), stack);
    }
  }
}
