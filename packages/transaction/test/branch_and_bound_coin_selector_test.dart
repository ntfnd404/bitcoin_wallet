import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/domain/exception/coin_selection_no_solution_exception.dart';
import 'package:transaction/transaction.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// A simple fee estimator with fixed weights for predictable test math.
/// P2WPKH defaults: input=68 vbytes, output=31 vbytes, overhead=10 vbytes.
const _estimator = P2wpkhFeeEstimator();
const _feeRate = 1; // 1 sat/vbyte — keeps arithmetic simple

/// fee(0 inputs, 1 output) = (10 + 31) × 1 = 41 sat
const _oneOutputFee = 41;

/// costOfChange = (fee(0,2) - fee(0,1)) + 68 × 1 = 31 + 68 = 99 sat
const _costOfChange = 99;

CoinCandidate _candidate({
  required int amountSat,
  AddressType scriptType = AddressType.nativeSegwit,
  String txid = 'tx',
  int vout = 0,
}) => CoinCandidate(
  txid: txid,
  vout: vout,
  amountSat: Satoshi(amountSat),
  age: 1,
  scriptType: scriptType,
);

CoinSelectionRequest _request({
  required List<CoinCandidate> candidates,
  required int targetSat,
}) => CoinSelectionRequest(
  candidates: candidates,
  targetSat: Satoshi(targetSat),
  feeRateSatPerVbyte: _feeRate,
  feeEstimator: _estimator,
  dustThreshold: 294,
);

const _bnb = BranchAndBoundCoinSelector();

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BranchAndBoundCoinSelector', () {
    // T1 — Exact match: single UTXO whose effective value == targetEffective.
    // targetEffective = 1000 + 41 = 1041
    // candidate amountSat = 1041 + 68 (inputFee) = 1109 → effectiveValue = 1041
    test('T1: exact-match UTXO returns zero change', () {
      final candidates = [
        _candidate(amountSat: 1109, txid: 'exact'), // effectiveValue = 1041
      ];
      final result = _bnb.select(_request(candidates: candidates, targetSat: 1000));

      expect(result.changeSat, equals(Satoshi.zero));
      expect(result.inputs, hasLength(1));
      expect(result.inputs.first.txid, equals('exact'));
      // feeSat = totalRawInput - targetSat = 1109 - 1000 = 109
      expect(result.feeSat, equals(const Satoshi(109)));
      // Fee invariant: feeSat >= fee(selectedInputs, 1 output)
      final minFee = _estimator.estimateForCandidates(
        inputs: result.inputs,
        outputs: 1,
        feeRateSatPerVbyte: _feeRate,
      );
      expect(result.feeSat.value, greaterThanOrEqualTo(minFee.value));
    });

    // T2 — Near-zero excess: effectiveValue = targetEffective + costOfChange - 1 (within range).
    // targetEffective = 500 + 41 = 541
    // costOfChange = 99
    // candidate effectiveValue should be in [541, 640]
    // amountSat = effectiveValue + inputFee = 620 + 68 = 688
    test('T2: near-zero excess below costOfChange is accepted as zero change', () {
      const excess = _costOfChange - 1; // 98, within range
      const ev = _oneOutputFee + 500 + excess; // 541 + 98 = 639
      const amountSat = ev + 68; // effectiveValue + inputFee = 707

      final candidates = [_candidate(amountSat: amountSat, txid: 'near')];
      final result = _bnb.select(_request(candidates: candidates, targetSat: 500));

      expect(result.changeSat, equals(Satoshi.zero));
      expect(result.inputs, hasLength(1));
      // Fee invariant
      final minFee = _estimator.estimateForCandidates(
        inputs: result.inputs,
        outputs: 1,
        feeRateSatPerVbyte: _feeRate,
      );
      expect(result.feeSat.value, greaterThanOrEqualTo(minFee.value));
    });

    // T3 — Overshoot: effective value > targetEffective + costOfChange.
    // Not accepted as success → CoinSelectionNoSolutionException (no economic match).
    // targetEffective = 100 + 41 = 141, costOfChange = 99 → upper bound = 240
    // candidate effectiveValue = 241 → amountSat = 241 + 68 = 309
    test('T3: overshoot above targetEffective + costOfChange is not accepted', () {
      const ev = _oneOutputFee + 100 + _costOfChange + 1; // 141 + 100 = 241
      const amountSat = ev + 68;

      final candidates = [_candidate(amountSat: amountSat, txid: 'over')];
      expect(
        () => _bnb.select(_request(candidates: candidates, targetSat: 100)),
        throwsA(isA<CoinSelectionNoSolutionException>()),
      );
    });

    // T4 — All candidates non-positive effective value → InsufficientFundsException.
    // A dust UTXO whose value exactly equals its input fee: effectiveValue = 0.
    test('T4: all candidates non-positive effective throw InsufficientFundsException', () {
      // effectiveValue = amountSat - 68 × feeRate = 68 - 68 = 0
      final candidates = [_candidate(amountSat: 68, txid: 'dust')];
      expect(
        () => _bnb.select(_request(candidates: candidates, targetSat: 1000)),
        throwsA(isA<InsufficientFundsException>()),
      );
    });

    // T5 — Sufficient raw funds but no changeless economic set.
    // Two UTXOs, each effectiveValue slightly above targetEffective/2.
    // Combined effective = targetEffective + costOfChange + 1 (overshot)
    // Single candidates don't reach targetEffective either → no solution.
    test('T5: sufficient raw funds but no changeless set throws CoinSelectionNoSolutionException', () {
      // targetEffective = 1000 + 41 = 1041, costOfChange = 99
      // Each candidate effectiveValue = 521, combined = 1042 (in range!)
      // Hmm, that would be found. Need combined to exceed upper bound.
      // Let's use two candidates where each alone is below targetEffective
      // and together overshoot targetEffective + costOfChange.
      // targetEffective = 100 + 41 = 141, upper = 240
      // each ev = 121 (below 141), combined = 242 (above 240) → no solution
      const evPerCandidate = 121;
      const amountPerCandidate = evPerCandidate + 68; // = 189

      final candidates = [
        _candidate(amountSat: amountPerCandidate, txid: 'a'),
        _candidate(amountSat: amountPerCandidate, txid: 'b'),
      ];
      expect(
        () => _bnb.select(_request(candidates: candidates, targetSat: 100)),
        throwsA(isA<CoinSelectionNoSolutionException>()),
      );
    });

    // T6 — Mixed script types regression: effective values (not raw amounts) drive selection.
    // P2PKH input: 148 vbytes vs P2WPKH: 68 vbytes.
    // Two candidates with same amountSat but different scriptType → different effectiveValues.
    // BnB should prefer the P2WPKH candidate (higher effectiveValue = better).
    test('T6: effective values drive selection over raw amounts for mixed script types', () {
      const targetSat = 500;

      // P2WPKH: effectiveValue = 650 - 68 = 582
      final wpkh = _candidate(
        amountSat: 650,
        txid: 'wpkh',
      );

      // P2PKH: effectiveValue = 650 - 148 = 502
      final pkh = _candidate(
        amountSat: 650,
        scriptType: AddressType.legacy,
        txid: 'pkh',
      );

      // targetEffective = 500 + 41 = 541
      // wpkh effectiveValue = 582, which is in [541, 640] → found
      // pkh effectiveValue = 502 < 541 → not enough alone
      final result = _bnb.select(
        _request(
          candidates: [pkh, wpkh],
          targetSat: targetSat,
        ),
      );

      expect(result.changeSat, equals(Satoshi.zero));
      expect(result.inputs, hasLength(1));
      expect(result.inputs.first.txid, equals('wpkh'));
    });

    // T7 — Fee invariant: feeSat >= fee(selectedInputs, 1 output).
    test('T7: fee invariant holds for BnB result', () {
      final candidates = [
        _candidate(amountSat: 1200, txid: 'a'),
        _candidate(amountSat: 800, txid: 'b'),
      ];
      final result = _bnb.select(_request(candidates: candidates, targetSat: 600));

      final minFee = _estimator.estimateForCandidates(
        inputs: result.inputs,
        outputs: 1,
        feeRateSatPerVbyte: _feeRate,
      );
      expect(result.feeSat.value, greaterThanOrEqualTo(minFee.value));
      expect(result.changeSat, equals(Satoshi.zero));
    });
  });
}
