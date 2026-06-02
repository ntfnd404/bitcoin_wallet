import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/application/prepare_send_use_case.dart';
import 'package:transaction/transaction.dart';

import '../fakes/fake_coin_selector.dart';
import '../fakes/fake_fee_estimator.dart';
import '../fakes/fake_signer.dart';
import '../fakes/fake_utxo_eligibility_filter.dart';
import 'helpers/fake_utxo_source.dart';

void main() {
  late FakeUtxoSource fakeSource;
  late FakeSigner fakeSigner;
  late FakeUtxoEligibilityFilter fakeFilter;
  late FakeCoinSelector fakeSelector;
  late PrepareSendUseCase prepareUseCase;
  late SendWorkflowImpl workflow;

  setUp(() {
    fakeSource = FakeUtxoSource();
    fakeSigner = FakeSigner();
    fakeFilter = FakeUtxoEligibilityFilter();
    fakeSelector = FakeCoinSelector(name: 'fifo');
    fakeFilter.result = const [
      CoinCandidate(txid: 'abc', vout: 0, amountSat: Satoshi(100000), age: 6),
    ];
    fakeSource.result = const UtxoSourceResult(
      candidates: [CoinCandidate(txid: 'abc', vout: 0, amountSat: Satoshi(100000), age: 6)],
      changeAddress: 'bcrt1qchange',
      signingContext: NodeSignerPayload(),
    );
    prepareUseCase = PrepareSendUseCase(
      selectors: [fakeSelector],
      feeEstimator: FakeFeeEstimator(),
      eligibilityFilter: fakeFilter,
    );
    workflow = SendWorkflowImpl(
      source: fakeSource,
      signer: fakeSigner,
      prepare: prepareUseCase,
    );
  });

  group('SendWorkflowImpl', () {
    // WI1
    test('prepare() delegates to PrepareSendUseCase via source and returns SendPreparation', () async {
      final prep = await workflow.prepare(
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 5,
      );

      expect(prep.strategies, hasLength(1));
      expect(prep.changeAddress, 'bcrt1qchange');
    });

    // WI2
    test('confirm() calls signer with preparation.signingContext and returns txid', () async {
      final prep = await workflow.prepare(
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 5,
      );

      final txid = await workflow.confirm(
        preparation: prep,
        strategyName: 'fifo',
        recipientAddress: 'bcrt1qrecipient',
        amountSat: const Satoshi(50000),
      );

      expect(txid, 'txid_fake');
      expect(fakeSigner.capturedSignerPayload, isA<NodeSignerPayload>());
    });

    // WI3
    test('confirm() with unknown strategyName throws StateError', () async {
      final prep = await workflow.prepare(
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 5,
      );

      await expectLater(
        () => workflow.confirm(
          preparation: prep,
          strategyName: 'no_such_strategy',
          recipientAddress: 'bcrt1qrecipient',
          amountSat: const Satoshi(50000),
        ),
        throwsA(isA<StateError>()),
      );
    });

    // WI4
    test('prepare() propagates TransactionPreparationException from use case', () async {
      fakeSource.throwOnResolve = const TransactionPreparationException();

      await expectLater(
        () => workflow.prepare(targetSat: const Satoshi(50000), feeRateSatPerVbyte: 5),
        throwsA(isA<TransactionPreparationException>()),
      );
    });

    // WI5
    test('confirm() propagates TransactionSigningException from signer', () async {
      final prep = await workflow.prepare(
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 5,
      );
      fakeSigner.throwOnSign = const TransactionSigningException();

      await expectLater(
        () => workflow.confirm(
          preparation: prep,
          strategyName: 'fifo',
          recipientAddress: 'bcrt1qrecipient',
          amountSat: const Satoshi(50000),
        ),
        throwsA(isA<TransactionSigningException>()),
      );
    });

    // WI6
    test('confirm() propagates TransactionBroadcastException from signer', () async {
      final prep = await workflow.prepare(
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 5,
      );
      fakeSigner.throwOnSign = const TransactionBroadcastException();

      await expectLater(
        () => workflow.confirm(
          preparation: prep,
          strategyName: 'fifo',
          recipientAddress: 'bcrt1qrecipient',
          amountSat: const Satoshi(50000),
        ),
        throwsA(isA<TransactionBroadcastException>()),
      );
    });
  });
}
