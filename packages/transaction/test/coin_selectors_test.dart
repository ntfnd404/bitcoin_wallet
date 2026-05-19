import 'dart:math';

import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
//
// fee(n, m) = (10 + 68*n + 31*m) at feeRate=1 (P2WPKH, sat/vbyte)
//   fee(1,1) = 109   fee(1,2) = 140   fee(2,2) = 208
// dustThreshold = 294

const _estimator = P2wpkhFeeEstimator();
const _feeRate = 1;
const _dust = 294;

CoinCandidate _c({
  required String id,
  required int sat,
  int age = 1,
  int vout = 0,
}) =>
    CoinCandidate(
      txid: id,
      vout: vout,
      amountSat: Satoshi(sat),
      age: age,
    );

CoinSelectionRequest _req({
  required List<CoinCandidate> candidates,
  required int target,
  int? maxIterations,
  Random? random,
}) =>
    CoinSelectionRequest(
      candidates: candidates,
      targetSat: Satoshi(target),
      feeRateSatPerVbyte: _feeRate,
      feeEstimator: _estimator,
      dustThreshold: _dust,
      maxIterations: maxIterations,
      random: random,
    );

Satoshi _fee(List<CoinCandidate> inputs, int outputs) =>
    _estimator.estimateForCandidates(
      inputs: inputs,
      outputs: outputs,
      feeRateSatPerVbyte: _feeRate,
    );

// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  group('FifoCoinSelector', () {
    const fifo = FifoCoinSelector();

    // F1 — FIFO orders by age descending (higher age = older).
    // old(age=10, sat=500), new(age=1, sat=500), target=200.
    // fee(1,2)=140, need 340. Both qualify alone; FIFO picks old first.
    test('F1: selects older UTXO first', () {
      final old = _c(id: 'old', sat: 500, age: 10);
      final recent = _c(id: 'new', sat: 500);
      final result = fifo.select(_req(candidates: [recent, old], target: 200));

      expect(result.inputs, hasLength(1));
      expect(result.inputs.first.txid, equals('old'));
    });

    // F2 — total(100) < target(500) + fee(1,2)(140) → throws.
    test('F2: throws InsufficientFundsException when total is insufficient', () {
      final c = _c(id: 'a', sat: 100);
      expect(
        () => fifo.select(_req(candidates: [c], target: 500)),
        throwsA(isA<InsufficientFundsException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('LifoCoinSelector', () {
    const lifo = LifoCoinSelector();

    // L1 — LIFO orders by age ascending (lower age = newer).
    // old(age=10, sat=500), new(age=1, sat=500), target=200.
    // LIFO picks new first.
    test('L1: selects newer UTXO first', () {
      final old = _c(id: 'old', sat: 500, age: 10);
      final recent = _c(id: 'new', sat: 500);
      final result = lifo.select(_req(candidates: [old, recent], target: 200));

      expect(result.inputs, hasLength(1));
      expect(result.inputs.first.txid, equals('new'));
    });

    // L2 — insufficient funds.
    test('L2: throws InsufficientFundsException when total is insufficient', () {
      final c = _c(id: 'a', sat: 100);
      expect(
        () => lifo.select(_req(candidates: [c], target: 500)),
        throwsA(isA<InsufficientFundsException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('MinimizeInputsCoinSelector', () {
    const minInputs = MinimizeInputsCoinSelector();

    // MI1 — largest-first: large=800 covers target=500 alone.
    // fee(1,2)=140, need 640. 800 >= 640 → 1 input.
    test('MI1: single large UTXO covers target alone', () {
      final small = _c(id: 'small', sat: 200);
      final large = _c(id: 'large', sat: 800);
      final result = minInputs.select(_req(candidates: [small, large], target: 500));

      expect(result.inputs, hasLength(1));
      expect(result.inputs.first.txid, equals('large'));
    });

    // MI2 — neither a(400) nor b(400) alone covers 500+140=640; together
    // total=800 >= 500+208=708 → 2 inputs.
    test('MI2: falls back to two UTXOs when needed', () {
      final a = _c(id: 'a', sat: 400);
      final b = _c(id: 'b', sat: 400);
      final result = minInputs.select(_req(candidates: [a, b], target: 500));

      expect(result.inputs, hasLength(2));
    });

    // MI3 — insufficient funds.
    test('MI3: throws InsufficientFundsException when total is insufficient', () {
      final c = _c(id: 'a', sat: 100);
      expect(
        () => minInputs.select(_req(candidates: [c], target: 500)),
        throwsA(isA<InsufficientFundsException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('SmallestSingleCoinSelector', () {
    const ss = SmallestSingleCoinSelector();

    // SS1 — small(400) and large(800) both qualify for target=200.
    // fee(1,2)=140, need 340. Smallest (400) is picked.
    test('SS1: selects smallest qualifying single UTXO', () {
      final small = _c(id: 'small', sat: 400);
      final large = _c(id: 'large', sat: 800);
      final result = ss.select(_req(candidates: [large, small], target: 200));

      expect(result.inputs, hasLength(1));
      expect(result.inputs.first.txid, equals('small'));
    });

    // SS2 — sat=440, target=200, fee(1,2)=140.
    // rawChange = 440 - 200 - 140 = 100 < 294 → dust-fold.
    // feeSat = 440 - 200 = 240, changeSat = 0.
    test('SS2: folds dust change into fee', () {
      final c = _c(id: 'a', sat: 440);
      final result = ss.select(_req(candidates: [c], target: 200));

      expect(result.changeSat, equals(Satoshi.zero));
      expect(result.feeSat, equals(const Satoshi(240)));
    });

    // SS3 — a=200, b=200; neither alone covers target=500+fee(1,2)=640.
    test('SS3: throws InsufficientFundsException when no single UTXO qualifies', () {
      final a = _c(id: 'a', sat: 200);
      final b = _c(id: 'b', sat: 200);
      expect(
        () => ss.select(_req(candidates: [a, b], target: 500)),
        throwsA(isA<InsufficientFundsException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('SingleRandomDrawCoinSelector', () {
    // SRD1 — seeded Random, total=1300 >> target=500+maxFee=208.
    // All shuffles will succeed; result must cover target with valid fee.
    test('SRD1: returns valid result with seeded Random', () {
      final srd = SingleRandomDrawCoinSelector();
      final a = _c(id: 'a', sat: 800);
      final b = _c(id: 'b', sat: 500);
      final result = srd.select(
        _req(candidates: [a, b], target: 500, random: Random(42)),
      );

      expect(result.inputs, isNotEmpty);
      final outputs = result.changeSat == Satoshi.zero ? 1 : 2;
      final minFee = _fee(result.inputs, outputs);
      expect(result.feeSat.value, greaterThanOrEqualTo(minFee.value));
    });

    // SRD2 — total(100) < target(500) + maxFee → throws before retries.
    test('SRD2: throws InsufficientFundsException when total is insufficient', () {
      final srd = SingleRandomDrawCoinSelector();
      final c = _c(id: 'a', sat: 100);
      expect(
        () => srd.select(_req(candidates: [c], target: 500)),
        throwsA(isA<InsufficientFundsException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('KnapsackCoinSelector', () {
    // K1 — total(100) < target(500) + worstFee → throws immediately.
    test('K1: throws InsufficientFundsException when total is insufficient', () {
      final knapsack = KnapsackCoinSelector();
      final c = _c(id: 'a', sat: 100);
      expect(
        () => knapsack.select(_req(candidates: [c], target: 500)),
        throwsA(isA<InsufficientFundsException>()),
      );
    });

    // K2 (B-3 regression) — maxIterations=0 skips trial loop entirely.
    // Greedy largest-first: a=1000 covers 400+140=540 → 1 input.
    test('K2: maxIterations=0 skips trial loop and uses greedy fallback', () {
      final knapsack = KnapsackCoinSelector();
      final a = _c(id: 'a', sat: 1000);
      final b = _c(id: 'b', sat: 500);
      final result = knapsack.select(
        _req(candidates: [a, b], target: 400, maxIterations: 0),
      );

      expect(result.inputs, hasLength(1));
      expect(result.inputs.first.txid, equals('a'));
    });

    // K3 — with sufficient funds and seeded Random, a valid result is returned.
    test('K3: returns valid result with sufficient funds', () {
      final knapsack = KnapsackCoinSelector();
      final a = _c(id: 'a', sat: 800);
      final b = _c(id: 'b', sat: 600);
      final result = knapsack.select(
        _req(candidates: [a, b], target: 500, random: Random(0)),
      );

      expect(result.inputs, isNotEmpty);
      final outputs = result.changeSat == Satoshi.zero ? 1 : 2;
      final minFee = _fee(result.inputs, outputs);
      expect(result.feeSat.value, greaterThanOrEqualTo(minFee.value));
    });
  });

  // -------------------------------------------------------------------------
  group('MinimizeChangeCoinSelector', () {
    const minChange = MinimizeChangeCoinSelector();

    // MC1 — a=1000 produces rawChange=460 >= 294 (real change); b=700 produces
    // rawChange=160 < 294 (dust-fold, changeSat=0). Selector picks b.
    // fee(1,2)=140, target=400.
    test('MC1: selects subset with smallest change', () {
      final a = _c(id: 'a', sat: 1000);
      final b = _c(id: 'b', sat: 700);
      final result = minChange.select(_req(candidates: [a, b], target: 400));

      expect(result.inputs, hasLength(1));
      expect(result.inputs.first.txid, equals('b'));
      expect(result.changeSat, equals(Satoshi.zero));
    });

    // MC2 (B-2 regression) — both UTXOs produce dust-folded zero-change, but
    // a(740) yields feeSat=340 and b(690) yields feeSat=290. With the early
    // break removed and tiebreaker applied, b wins (lower feeSat).
    //
    // Pool order: [a, b]. mask=1→{a}: rawChange=200<294, feeSat=340, changeSat=0.
    // mask=2→{b}: rawChange=150<294, feeSat=290, changeSat=0. b is better.
    test('MC2 (B-2 regression): returns lowest-fee zero-change candidate, not first mask', () {
      final a = _c(id: 'a', sat: 740);
      final b = _c(id: 'b', sat: 690);
      final result = minChange.select(_req(candidates: [a, b], target: 400));

      expect(result.inputs.first.txid, equals('b'));
      expect(result.feeSat, equals(const Satoshi(290)));
      expect(result.changeSat, equals(Satoshi.zero));
    });

    // MC3 — total(300) < target(1000) → throws.
    test('MC3: throws InsufficientFundsException when total is insufficient', () {
      final c = _c(id: 'a', sat: 300);
      expect(
        () => minChange.select(_req(candidates: [c], target: 1000)),
        throwsA(isA<InsufficientFundsException>()),
      );
    });
  });
}
