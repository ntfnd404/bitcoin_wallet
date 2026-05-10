import 'package:transaction/src/domain/entity/scanned_utxo.dart';

/// Outbound port for scanning UTXOs at specific addresses via `scantxoutset`.
abstract interface class UtxoScanGateway {
  /// Scans the UTXO set for outputs belonging to any of [addresses].
  Future<List<ScannedUtxo>> scanForAddresses(List<String> addresses);
}
