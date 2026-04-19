import 'package:transaction/src/domain/entity/scanned_utxo.dart';

/// ISP interface for scanning UTXOs at specific addresses via `scantxoutset`.
///
/// Does not require a Bitcoin Core wallet — works at the node level.
abstract interface class UtxoScanDataSource {
  /// Scans the UTXO set for outputs belonging to any of [addresses].
  Future<List<ScannedUtxo>> scanForAddresses(List<String> addresses);
}
