import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CoinSelectionStrategyResult _strategy(
  String name, {
  required int fee,
  required int inputsCount,
  required int change,
  bool isStochastic = false,
}) => CoinSelectionStrategyResult(
  name: name,
  isStochastic: isStochastic,
  result: CoinSelectionResult(
    inputs: List.generate(
      inputsCount,
      (i) => CoinCandidate(
        txid: 'tx$i',
        vout: 0,
        amountSat: const Satoshi(50000),
        age: i,
      ),
    ),
    totalInputSat: Satoshi(inputsCount * 50000),
    feeSat: Satoshi(fee),
    changeSat: Satoshi(change),
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const recommender = DefaultCoinSelectionRecommender();
  const feeRate = 10;

  group('DefaultCoinSelectionRecommender', () {
    // R1
    test('R1: returns null for empty list', () {
      expect(recommender.recommend([], feeRate), isNull);
    });

    // R2
    test('R2: returns the only strategy name for a single entry', () {
      final strategies = [_strategy('fifo', fee: 1000, inputsCount: 2, change: 5000)];
      expect(recommender.recommend(strategies, feeRate), equals('fifo'));
    });

    // R3: zero-change strategy wins over higher-fee strategy with change
    // score(BnB)  = 150 + 0        = 150
    // score(FIFO) = 300 + 68*10    = 980
    test('R3: zero-change strategy beats higher raw-fee strategy with change', () {
      final strategies = [
        _strategy('FIFO', fee: 300, inputsCount: 2, change: 5000),
        _strategy('BnB', fee: 150, inputsCount: 3, change: 0),
      ];
      expect(recommender.recommend(strategies, feeRate), equals('BnB'));
    });

    // R4: score tie → fewer inputs wins
    // FIFO: 1000 + 68*10 = 1680, inputs=3
    // LIFO: 1000 + 68*10 = 1680, inputs=1  ← wins
    test('R4: on equal score, prefers fewer inputs', () {
      final strategies = [
        _strategy('FIFO', fee: 1000, inputsCount: 3, change: 500),
        _strategy('LIFO', fee: 1000, inputsCount: 1, change: 500),
      ];
      expect(recommender.recommend(strategies, feeRate), equals('LIFO'));
    });

    // R5: score + inputs tie → less change wins
    // alpha: 1000 + 680 = 1680, inputs=2, change=5000
    // beta:  1000 + 680 = 1680, inputs=2, change=100  ← wins
    test('R5: on equal score and inputs, prefers smaller change', () {
      final strategies = [
        _strategy('alpha', fee: 1000, inputsCount: 2, change: 5000),
        _strategy('beta', fee: 1000, inputsCount: 2, change: 100),
      ];
      expect(recommender.recommend(strategies, feeRate), equals('beta'));
    });

    // R6: full tie → original list position wins (stable tie-breaker G8)
    test('R6: full tie falls back to original list order', () {
      final strategies = [
        _strategy('gamma', fee: 1000, inputsCount: 2, change: 500),
        _strategy('alpha', fee: 1000, inputsCount: 2, change: 500),
        _strategy('beta', fee: 1000, inputsCount: 2, change: 500),
      ];
      expect(recommender.recommend(strategies, feeRate), equals('gamma'));
    });

    // R7: higher feeRate amplifies the zero-change advantage
    // feeRate=50: BnB score = 400, FIFO score = 200 + 68*50 = 3600 → BnB wins
    test('R7: higher feeRate makes zero-change more attractive', () {
      final strategies = [
        _strategy('FIFO', fee: 200, inputsCount: 1, change: 5000),
        _strategy('BnB', fee: 400, inputsCount: 2, change: 0),
      ];
      expect(recommender.recommend(strategies, 50), equals('BnB'));
    });

    // R8: at feeRate=0 score == feeSat, so lower fee wins regardless of change
    test('R8: at feeRate=0, score reduces to feeSat (change-output cost is zero)', () {
      final strategies = [
        _strategy('BnB', fee: 400, inputsCount: 2, change: 0),
        _strategy('FIFO', fee: 200, inputsCount: 1, change: 5000),
      ];
      expect(recommender.recommend(strategies, 0), equals('FIFO'));
    });
  });
}
