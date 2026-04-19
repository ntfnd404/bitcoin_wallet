import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/hd_send_preparation.dart';
import 'package:transaction/src/domain/data_sources/hd_address_data_source.dart';
import 'package:transaction/src/domain/data_sources/utxo_scan_data_source.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';
import 'package:transaction/src/domain/value_object/signing_input.dart';

/// Scans HD-wallet UTXOs, builds signing context, runs all coin-selection
/// strategies, and returns an [HdSendPreparation] for the UI comparison table.
///
/// Does not sign or broadcast — call [SendHdTransactionUseCase] after the user
/// confirms the send.
final class PrepareHdSendUseCase {
  final HdAddressDataSource _addressDataSource;
  final UtxoScanDataSource _utxoScanDataSource;
  final List<CoinSelector> _selectors;
  final FeeEstimator _feeEstimator;

  const PrepareHdSendUseCase({
    required HdAddressDataSource addressDataSource,
    required UtxoScanDataSource utxoScanDataSource,
    required List<CoinSelector> selectors,
    required FeeEstimator feeEstimator,
  })  : _addressDataSource = addressDataSource,
        _utxoScanDataSource = utxoScanDataSource,
        _selectors = selectors,
        _feeEstimator = feeEstimator;

  Future<HdSendPreparation> call({
    required String walletId,
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    // 1. Load all stored HD-wallet addresses with derivation metadata.
    final entries = await _addressDataSource.getAddressesForWallet(walletId);
    final nativeSegwit = entries
        .where((e) => e.type == AddressType.nativeSegwit)
        .toList();

    // 2. Scan the UTXO set for outputs at those addresses.
    final addressStrings = nativeSegwit.map((e) => e.address).toList();
    final scanned = await _utxoScanDataSource.scanForAddresses(addressStrings);

    // 3. Build address → entry lookup for O(1) resolution.
    final addressLookup = {for (final e in nativeSegwit) e.address: e};

    // 4. Map scanned UTXOs → CoinCandidate (age = rank, oldest = highest rank).
    //    Sort by block height ASC so the oldest UTXO gets rank = scanned.length.
    final sortedByHeight = [...scanned]
      ..sort((a, b) => a.height.compareTo(b.height));

    final candidates = <CoinCandidate>[];
    final signingInputs = <(String, int), SigningInput>{};

    for (var i = 0; i < sortedByHeight.length; i++) {
      final u = sortedByHeight[i];
      final age = sortedByHeight.length - i; // oldest → highest age

      candidates.add(CoinCandidate(
        txid: u.txid,
        vout: u.vout,
        amountSat: u.amountSat,
        age: age,
      ));

      final entry = u.address != null ? addressLookup[u.address] : null;
      if (entry != null) {
        signingInputs[(u.txid, u.vout)] = SigningInput(
          txid: u.txid,
          vout: u.vout,
          amountSat: u.amountSat,
          address: u.address!,
          derivationIndex: entry.index,
          addressType: entry.type,
        );
      }
    }

    // 5. Pick the highest-index nativeSegwit address as change address.
    final changeAddress = nativeSegwit.isEmpty
        ? ''
        : (nativeSegwit..sort((a, b) => b.index.compareTo(a.index))).first.address;

    // 6. Run all strategies; failures (insufficient funds) are omitted.
    final strategies = <String, CoinSelectionResult>{};
    for (final selector in _selectors) {
      try {
        strategies[selector.name] = selector.select(
          candidates: candidates,
          targetSat: targetSat,
          feeEstimator: _feeEstimator,
          feeRateSatPerVbyte: feeRateSatPerVbyte,
          dustThreshold: 546,
        );
      } on InsufficientFundsException {
        // Strategy could not cover the amount — omit from comparison table.
      }
    }

    return HdSendPreparation(
      candidates: candidates,
      strategies: Map.unmodifiable(strategies),
      signingInputs: Map.unmodifiable(signingInputs),
      changeAddress: changeAddress,
    );
  }
}
