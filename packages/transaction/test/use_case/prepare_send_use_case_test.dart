import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/application/prepare_send_use_case.dart';
import 'package:transaction/transaction.dart';

import '../fakes/fake_coin_selector.dart';
import '../fakes/fake_fee_estimator.dart';
import '../fakes/fake_utxo_eligibility_filter.dart';
import '../source/helpers/fake_utxo_source.dart';

void main() {
  late FakeUtxoSource fakeSource;
  late FakeCoinSelector selectorA;
  late FakeCoinSelector selectorB;
  late FakeUtxoEligibilityFilter fakeFilter;
  late FakeFeeEstimator fakeEstimator;
  late PrepareSendUseCase useCase;

  const candidate = CoinCandidate(
    txid: 'abc',
    vout: 0,
    amountSat: Satoshi(100000),
    age: 6,
  );

  setUp(() {
    fakeSource = FakeUtxoSource();
    selectorA = FakeCoinSelector(name: 'fifo');
    selectorB = FakeCoinSelector(name: 'lifo');
    fakeFilter = FakeUtxoEligibilityFilter();
    fakeEstimator = FakeFeeEstimator();
    useCase = PrepareSendUseCase(
      selectors: [selectorA, selectorB],
      feeEstimator: fakeEstimator,
      eligibilityFilter: fakeFilter,
    );
  });

  group('PrepareSendUseCase', () {
    // UC1
    test('happy path Node: applies EligibilityPolicy.node and returns SendPreparationResult', () async {
      fakeSource.result = const UtxoSourceResult(
        candidates: [candidate],
        changeAddress: 'bcrt1qchange',
        signingContext: NodeSignerPayload(),
      );
      fakeFilter.result = [candidate];

      final prep = await useCase(
        source: fakeSource,
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 5,
      );

      expect(prep, isA<SendPreparationResult>());
      expect(prep.signingContext, isA<NodeSignerPayload>());
      expect(fakeFilter.capturedPolicy, EligibilityPolicy.node);
      expect(prep.changeAddress, 'bcrt1qchange');
      expect(prep.strategies, hasLength(2));
    });

    // UC2
    test('happy path HD: applies EligibilityPolicy.hd and returns HdSignerPayload', () async {
      fakeSource.result = UtxoSourceResult(
        candidates: const [candidate],
        changeAddress: 'bcrt1qhd',
        signingContext: HdSignerPayload(const {}),
      );
      fakeFilter.result = [candidate];

      final prep = await useCase(
        source: fakeSource,
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 5,
      );

      expect(prep.signingContext, isA<HdSignerPayload>());
      expect(fakeFilter.capturedPolicy, EligibilityPolicy.hd);
    });

    // UC3
    test('all selectors throw InsufficientFundsException: returns empty strategies', () async {
      fakeSource.result = const UtxoSourceResult(
        candidates: [candidate],
        changeAddress: 'bcrt1qchange',
        signingContext: NodeSignerPayload(),
      );
      fakeFilter.result = [candidate];
      selectorA.throwOnSelect = const InsufficientFundsException(
        available: Satoshi(100000),
        required: Satoshi(99999999),
      );
      selectorB.throwOnSelect = const InsufficientFundsException(
        available: Satoshi(100000),
        required: Satoshi(99999999),
      );

      final prep = await useCase(
        source: fakeSource,
        targetSat: const Satoshi(99999999),
        feeRateSatPerVbyte: 5,
      );

      expect(prep.strategies, isEmpty);
    });

    // UC4
    test('source throws TransactionPreparationException: rethrows as-is', () async {
      fakeSource.throwOnResolve = const TransactionPreparationException();

      await expectLater(
        () => useCase(source: fakeSource, targetSat: const Satoshi(50000), feeRateSatPerVbyte: 5),
        throwsA(isA<TransactionPreparationException>()),
      );
    });

    // UC5
    test('source throws non-TransactionException Exception: wraps into TransactionPreparationException', () async {
      fakeSource.throwOnResolve = Exception('infra error');

      await expectLater(
        () => useCase(source: fakeSource, targetSat: const Satoshi(50000), feeRateSatPerVbyte: 5),
        throwsA(isA<TransactionPreparationException>()),
      );
    });

    // UC6
    test('one selector throws InsufficientFundsException, other succeeds: only successful in strategies', () async {
      fakeSource.result = const UtxoSourceResult(
        candidates: [candidate],
        changeAddress: 'bcrt1qchange',
        signingContext: NodeSignerPayload(),
      );
      fakeFilter.result = [candidate];
      selectorA.throwOnSelect = const InsufficientFundsException(
        available: Satoshi(100000),
        required: Satoshi(99999999),
      );

      final prep = await useCase(
        source: fakeSource,
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 5,
      );

      expect(prep.strategies, hasLength(1));
      expect(prep.strategies.first.name, 'lifo');
    });
  });
}
