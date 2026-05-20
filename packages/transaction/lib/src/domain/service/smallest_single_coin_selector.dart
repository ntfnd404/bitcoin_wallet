import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Smallest-single UTXO selector — Bitcoin Core step 3 (Jameson Lopp, 2015).
///
/// Finds the smallest single UTXO that is large enough to cover
/// `targetSat + fee(1 input, [_outputsWithChange] outputs)`. This minimises
/// transaction size (exactly one input) and avoids over-spending large UTXOs.
///
/// This selector assumes a standard two-output transaction (recipient + change).
/// [_outputsWithChange] = 2 captures this contract explicitly: the fee estimate
/// accounts for the change output. If the resulting change falls below
/// [CoinSelectionRequest.dustThreshold] it is folded into the fee (single output).
///
/// **Contrast with BnB**: BnB uses `outputs = 1` to search for zero-change
/// solutions. SmallestSingle uses `outputs = 2` because it expects change to exist
/// and prices it in. The dust-fold is a secondary optimisation, not the goal.
///
/// Throws [InsufficientFundsException] when no single UTXO covers the target.
/// In that case the caller should fall back to a multi-input strategy.
///
/// [isStochastic] is `false`.
final class SmallestSingleCoinSelector implements CoinSelector {
  /// Number of outputs assumed when estimating the selection fee.
  ///
  /// 2 = recipient output + change output. The fee covers both so that we
  /// correctly select a UTXO that can fund the full two-output transaction.
  /// If the change is below dust threshold it is later folded into the fee,
  /// but the search criterion must account for change to avoid underestimating.
  static const int _outputsWithChange = 2;

  @override
  String get name => 'SmallestSingle';

  @override
  bool get isStochastic => false;

  const SmallestSingleCoinSelector();

  @override
  CoinSelectionResult select(CoinSelectionRequest request) {
    final feeRate = request.feeRateSatPerVbyte;
    final estimator = request.feeEstimator;

    // Sort ascending by amountSat to find the smallest qualifying UTXO.
    final sorted = List<CoinCandidate>.from(request.candidates)
      ..sort((a, b) => a.amountSat.value.compareTo(b.amountSat.value));

    CoinCandidate? best;

    for (final candidate in sorted) {
      final fee = estimator.estimateForCandidates(
        inputs: [candidate],
        outputs: _outputsWithChange,
        feeRateSatPerVbyte: feeRate,
      );

      if (candidate.amountSat >= request.targetSat + fee) {
        best = candidate;
        break; // First qualifying (smallest) is the best.
      }
    }

    if (best == null) {
      final total = sorted.fold(Satoshi.zero, (s, c) => s + c.amountSat);
      throw InsufficientFundsException(
        available: total,
        required: request.targetSat,
      );
    }

    final feeSat = estimator.estimateForCandidates(
      inputs: [best],
      outputs: _outputsWithChange,
      feeRateSatPerVbyte: feeRate,
    );

    final rawChange = best.amountSat - request.targetSat - feeSat;

    if (rawChange.value < request.dustThreshold) {
      // Change below dust threshold: fold into fee (single-output transaction).
      return CoinSelectionResult(
        inputs: [best],
        totalInputSat: best.amountSat,
        feeSat: best.amountSat - request.targetSat,
        changeSat: Satoshi.zero,
      );
    }

    return CoinSelectionResult(
      inputs: [best],
      totalInputSat: best.amountSat,
      feeSat: feeSat,
      changeSat: rawChange,
    );
  }
}
