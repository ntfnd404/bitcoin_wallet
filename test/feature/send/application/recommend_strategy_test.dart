import 'package:bitcoin_wallet/feature/send/application/recommend_strategy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

CoinSelectionResult _result({
  required int fee,
  required int inputsCount,
  required int change,
}) => CoinSelectionResult(
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
);

void main() {
  group('recommendStrategy', () {
    test('returns null for empty map', () {
      expect(recommendStrategy({}), isNull);
    });

    test('returns the only strategy when one is given', () {
      final strategies = {
        'fifo': _result(fee: 1000, inputsCount: 2, change: 5000),
      };
      expect(recommendStrategy(strategies), equals('fifo'));
    });

    test('prefers the strategy with the lowest fee', () {
      final strategies = {
        'fifo': _result(fee: 2000, inputsCount: 2, change: 5000),
        'min_change': _result(fee: 1500, inputsCount: 3, change: 100),
        'min_inputs': _result(fee: 1200, inputsCount: 1, change: 8000),
      };
      expect(recommendStrategy(strategies), equals('min_inputs'));
    });

    test('on equal fee, prefers fewer inputs', () {
      final strategies = {
        'fifo': _result(fee: 1000, inputsCount: 3, change: 100),
        'min_inputs': _result(fee: 1000, inputsCount: 1, change: 5000),
        'lifo': _result(fee: 1000, inputsCount: 2, change: 2000),
      };
      expect(recommendStrategy(strategies), equals('min_inputs'));
    });

    test('on equal fee and inputs, prefers smaller change', () {
      final strategies = {
        'fifo': _result(fee: 1000, inputsCount: 2, change: 5000),
        'lifo': _result(fee: 1000, inputsCount: 2, change: 100),
        'min_inputs': _result(fee: 1000, inputsCount: 2, change: 2000),
      };
      expect(recommendStrategy(strategies), equals('lifo'));
    });

    test('on full tie, falls back to Map insertion order (G8)', () {
      final strategies = {
        'gamma': _result(fee: 1000, inputsCount: 2, change: 500),
        'alpha': _result(fee: 1000, inputsCount: 2, change: 500),
        'beta': _result(fee: 1000, inputsCount: 2, change: 500),
      };
      expect(recommendStrategy(strategies), equals('gamma'));
    });
  });
}
