import 'package:bitcoin_wallet/feature/send/application/recommend_strategy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CoinCandidate _coin(int amount) => CoinCandidate(
  txid: 'tx',
  vout: 0,
  amountSat: Satoshi(amount),
  age: 1,
);

CoinSelectionResult _result({
  required int fee,
  required int inputsCount,
  required int change,
}) => CoinSelectionResult(
  inputs: List.generate(inputsCount, (i) => _coin(10000)),
  totalInputSat: Satoshi(inputsCount * 10000),
  feeSat: Satoshi(fee),
  changeSat: Satoshi(change),
);

// ---------------------------------------------------------------------------
// Tests documenting recommendation behaviour when SmallestSingle is included.
//
// recommendStrategy() sorts by: feeSat ASC → inputs.length ASC → changeSat ASC.
// SmallestSingle always produces 1 input, so it wins on inputs.length when fee
// is equal. These tests pin the expected observable behaviour so any future
// change to recommendStrategy() that breaks these semantics is caught.
// ---------------------------------------------------------------------------

void main() {
  group('recommendStrategy — SmallestSingle participation', () {
    // RS-1: SmallestSingle wins when its fee is lower than multi-input strategies.
    test('RS-1: SmallestSingle recommended when it has the lowest fee', () {
      final strategies = {
        'FIFO': _result(fee: 500, inputsCount: 3, change: 2000),
        'SmallestSingle': _result(fee: 200, inputsCount: 1, change: 5000),
        'MinChange': _result(fee: 400, inputsCount: 2, change: 100),
      };
      expect(recommendStrategy(strategies), equals('SmallestSingle'));
    });

    // RS-2: SmallestSingle wins on inputs.length when fees are equal.
    // This is expected behaviour: 1 input = smaller tx = fewer future UTXOs.
    test('RS-2: SmallestSingle wins on inputs count when fee is equal', () {
      final strategies = {
        'FIFO': _result(fee: 300, inputsCount: 3, change: 1000),
        'SmallestSingle': _result(fee: 300, inputsCount: 1, change: 8000),
        'LIFO': _result(fee: 300, inputsCount: 2, change: 1500),
      };
      // Same fee → fewer inputs wins → SmallestSingle (1 input)
      expect(recommendStrategy(strategies), equals('SmallestSingle'));
    });

    // RS-3: BnB wins when it has lower fee (zero change means lower total cost).
    test('RS-3: BnB recommended when its fee beats SmallestSingle', () {
      final strategies = {
        'SmallestSingle': _result(fee: 300, inputsCount: 1, change: 4000),
        'BnB': _result(fee: 150, inputsCount: 2, change: 0),
        'FIFO': _result(fee: 500, inputsCount: 4, change: 2000),
      };
      expect(recommendStrategy(strategies), equals('BnB'));
    });

    // RS-4: SmallestSingle can win over BnB when its fee is lower despite change.
    // This is intentional: recommendStrategy() optimises for fee first, not change.
    // If waste-metric ranking is needed, implement WasteMetric (Stage 2).
    test('RS-4: SmallestSingle wins over BnB when its fee is lower (expected behaviour)', () {
      final strategies = {
        'BnB': _result(fee: 400, inputsCount: 3, change: 0),
        'SmallestSingle': _result(fee: 200, inputsCount: 1, change: 5000),
      };
      // Lower fee wins even though SmallestSingle has change. Expected behaviour.
      expect(recommendStrategy(strategies), equals('SmallestSingle'));
    });

    // RS-5: If SmallestSingle is absent (e.g. threw CoinSelectionNoSolutionException),
    // recommendation falls back to next best strategy.
    test('RS-5: recommendation falls back correctly when SmallestSingle absent', () {
      final strategies = {
        'FIFO': _result(fee: 500, inputsCount: 3, change: 2000),
        'BnB': _result(fee: 300, inputsCount: 2, change: 0),
      };
      expect(recommendStrategy(strategies), equals('BnB'));
    });
  });
}
