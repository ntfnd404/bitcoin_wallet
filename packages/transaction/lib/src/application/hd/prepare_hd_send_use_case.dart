import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/hd/hd_send_preparation.dart';
import 'package:transaction/src/domain/exception/coin_selection_no_solution_exception.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/utxo_scan_gateway.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/service/eligibility_policy.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/service/utxo_eligibility_filter.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';
import 'package:transaction/src/domain/value_object/signing_input.dart';
import 'package:wallet/wallet.dart';

/// Scans HD-wallet UTXOs, builds signing context, runs all coin-selection
/// strategies, and returns an [HdSendPreparation] for the UI comparison table.
///
/// Does not sign or broadcast — call [SendHdTransactionUseCase] after the user
/// confirms the send.
final class PrepareHdSendUseCase {
  final AddressRepository _addressRepository;
  final UtxoScanGateway _utxoScanDataSource;
  final List<CoinSelector> _selectors;
  final FeeEstimator _feeEstimator;
  final UtxoEligibilityFilter _eligibilityFilter;

  const PrepareHdSendUseCase({
    required AddressRepository addressRepository,
    required UtxoScanGateway utxoScanDataSource,
    required List<CoinSelector> selectors,
    required FeeEstimator feeEstimator,
    UtxoEligibilityFilter eligibilityFilter = const DefaultUtxoEligibilityFilter(),
  }) : _addressRepository = addressRepository,
       _utxoScanDataSource = utxoScanDataSource,
       _selectors = selectors,
       _feeEstimator = feeEstimator,
       _eligibilityFilter = eligibilityFilter;

  Future<HdSendPreparation> call({
    required String walletId,
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    try {
      // 1. Load all stored HD-wallet addresses with derivation metadata.
      final entries = await _addressRepository.getAddresses(walletId);
      final nativeSegwit = entries.where((e) => e.type == AddressType.nativeSegwit).toList();

      // 2. Scan the UTXO set for outputs at those addresses.
      final addressStrings = nativeSegwit.map((e) => e.value).toList();
      final scanned = await _utxoScanDataSource.scanForAddresses(addressStrings);

      // 3. Build address → entry lookup for O(1) resolution.
      final addressLookup = {for (final e in nativeSegwit) e.value: e};

      // 4. Map scanned UTXOs → CoinCandidate (age = rank, oldest = highest rank).
      //    Sort by block height ASC so the oldest UTXO gets rank = scanned.length.
      scanned.sort((a, b) => a.height.compareTo(b.height));
      final sortedByHeight = scanned;

      final candidates = <CoinCandidate>[];
      final signingInputs = <(String, int), SigningInput>{};

      for (var i = 0; i < sortedByHeight.length; i++) {
        final u = sortedByHeight[i];
        final age = sortedByHeight.length - i; // oldest → highest age

        final entry = u.address != null ? addressLookup[u.address] : null;
        candidates.add(
          CoinCandidate(
            txid: u.txid,
            vout: u.vout,
            amountSat: u.amountSat,
            age: age,
            scriptType: entry?.type ?? AddressType.nativeSegwit,
            scriptPubKeyHex: u.scriptPubKeyHex,
            // HD wallet: scantxoutset does not expose confirmations relative
            // to chain tip. Leave null (unknown) per G6 / EligibilityPolicy.
          ),
        );

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
          : (nativeSegwit..sort((a, b) => b.index.compareTo(a.index))).first.value;

      // 5b. Apply eligibility filter (dust/effective-value check).
      // HD wallet uses EligibilityPolicy.hd: unknown confirmations are allowed
      // because scantxoutset does not expose per-UTXO block height relative to tip.
      final eligibleCandidates = _eligibilityFilter.filter(
        candidates,
        EligibilityPolicy.hd,
        _feeEstimator,
        feeRateSatPerVbyte,
      );

      // 6. Run all strategies; failures (insufficient funds) are omitted.
      final strategies = <CoinSelectionStrategyResult>[];
      for (final selector in _selectors) {
        try {
          strategies.add(CoinSelectionStrategyResult(
            name: selector.name,
            isStochastic: selector.isStochastic,
            result: selector.select(
              CoinSelectionRequest(
                candidates: eligibleCandidates,
                targetSat: targetSat,
                feeEstimator: _feeEstimator,
                feeRateSatPerVbyte: feeRateSatPerVbyte,
                dustThreshold: _feeEstimator.dustThreshold(AddressType.nativeSegwit),
              ),
            ),
          ));
        } on InsufficientFundsException {
          // Strategy could not cover the amount — omit.
        } on CoinSelectionNoSolutionException {
          // Strategy could not cover the amount — omit from comparison table.
        }
      }

      return HdSendPreparation(
        candidates: candidates,
        strategies: List.unmodifiable(strategies),
        signingInputs: Map.unmodifiable(signingInputs),
        changeAddress: changeAddress,
      );
    } on InsufficientFundsException {
      rethrow;
    } on AddressException catch (_, stack) {
      Error.throwWithStackTrace(const TransactionPreparationException(), stack);
    } on TransactionException {
      rethrow;
    }
    // Programmer errors propagate to the zone handler.
  }
}
