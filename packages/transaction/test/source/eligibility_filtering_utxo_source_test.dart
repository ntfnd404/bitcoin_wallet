import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

import '../fakes/fake_fee_estimator.dart';
import '../fakes/fake_utxo_eligibility_filter.dart';
import 'helpers/fake_utxo_source.dart';

void main() {
  late FakeUtxoSource inner;
  late FakeUtxoEligibilityFilter filter;
  late FakeFeeEstimator feeEstimator;

  setUp(() {
    inner = FakeUtxoSource();
    filter = FakeUtxoEligibilityFilter();
    feeEstimator = FakeFeeEstimator();
  });

  group('EligibilityFilteringUtxoSource', () {
    test('drops filtered candidates and preserves changeAddress + Node signingContext', () async {
      final all = [
        _candidate(txid: 'a', sat: 1000),
        _candidate(txid: 'b', sat: 2000),
        _candidate(txid: 'c', sat: 3000),
      ];
      final kept = [all[0], all[2]];
      inner.result = UtxoSourceResult(
        candidates: all,
        changeAddress: 'bcrt1qchange-node',
        signingContext: const NodeSignerPayload(),
      );
      filter.result = kept;

      final decorator = EligibilityFilteringUtxoSource(
        inner: inner,
        policy: EligibilityPolicy.node,
        filter: filter,
        feeEstimator: feeEstimator,
        feeRateSatPerVbyte: 5,
      );

      final result = await decorator.resolve();

      expect(result.candidates, equals(kept));
      expect(result.changeAddress, equals('bcrt1qchange-node'));
      expect(result.signingContext, isA<NodeSignerPayload>());
      expect(filter.capturedCandidates, equals(all));
      expect(filter.capturedPolicy, equals(EligibilityPolicy.node));
    });

    test('returns zero candidates when inner returns zero (no NPE)', () async {
      inner.result = const UtxoSourceResult(
        candidates: [],
        changeAddress: 'bcrt1qempty',
        signingContext: NodeSignerPayload(),
      );
      filter.result = const [];

      final decorator = EligibilityFilteringUtxoSource(
        inner: inner,
        policy: EligibilityPolicy.node,
        filter: filter,
        feeEstimator: feeEstimator,
        feeRateSatPerVbyte: 5,
      );

      final result = await decorator.resolve();

      expect(result.candidates, isEmpty);
      expect(result.changeAddress, equals('bcrt1qempty'));
    });

    test('passes through HdSignerPayload unchanged', () async {
      const si = SigningInput(
        txid: 'a',
        vout: 0,
        amountSat: Satoshi(1000),
        address: 'bcrt1qknown',
        derivationIndex: 4,
        addressType: AddressType.nativeSegwit,
      );
      final hdCtx = HdSignerPayload(<(String, int), SigningInput>{('a', 0): si});
      final candidates = [_candidate(txid: 'a', sat: 1000)];
      inner.result = UtxoSourceResult(
        candidates: candidates,
        changeAddress: 'bcrt1qchange-hd',
        signingContext: hdCtx,
      );
      filter.result = candidates;

      final decorator = EligibilityFilteringUtxoSource(
        inner: inner,
        policy: EligibilityPolicy.hd,
        filter: filter,
        feeEstimator: feeEstimator,
        feeRateSatPerVbyte: 7,
      );

      final result = await decorator.resolve();

      expect(result.signingContext, same(hdCtx));
      expect(result.changeAddress, equals('bcrt1qchange-hd'));
      expect(filter.capturedPolicy, equals(EligibilityPolicy.hd));
    });

    test('propagates exceptions from inner source unchanged', () async {
      inner.throwOnResolve = const TransactionFetchException();

      final decorator = EligibilityFilteringUtxoSource(
        inner: inner,
        policy: EligibilityPolicy.node,
        filter: filter,
        feeEstimator: feeEstimator,
        feeRateSatPerVbyte: 5,
      );

      await expectLater(
        () => decorator.resolve(),
        throwsA(isA<TransactionFetchException>()),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CoinCandidate _candidate({required String txid, required int sat}) => CoinCandidate(
      txid: txid,
      vout: 0,
      amountSat: Satoshi(sat),
      age: 1,
    );
