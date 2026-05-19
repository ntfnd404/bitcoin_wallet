import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/domain/exception/coin_selection_no_solution_exception.dart';
import 'package:transaction/transaction.dart';

import 'fakes/fake_coin_selector.dart';
import 'fakes/fake_node_transaction_gateway.dart';
import 'fakes/fake_utxo_eligibility_filter.dart';
import 'fakes/fake_utxo_repository.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _estimator = P2wpkhFeeEstimator();

Utxo _utxo({
  required String txid,
  required int sat,
  int confirmations = 2,
  bool spendable = true,
}) =>
    Utxo(
      txid: txid,
      vout: 0,
      amountSat: Satoshi(sat),
      confirmations: confirmations,
      address: 'bcrt1qtest',
      scriptPubKey: '0014abcd',
      type: AddressType.nativeSegwit,
      spendable: spendable,
    );

CoinCandidate _candidate({required String txid, required int sat}) => CoinCandidate(
      txid: txid,
      vout: 0,
      amountSat: Satoshi(sat),
      age: 2,
      confirmations: 2,
    );

PrepareNodeSendUseCase _makeUseCase({
  required FakeUtxoRepository repo,
  required FakeNodeTransactionGateway gateway,
  required FakeCoinSelector selector,
  required FakeUtxoEligibilityFilter filter,
}) =>
    PrepareNodeSendUseCase(
      utxoRepository: repo,
      nodeDataSource: gateway,
      selectors: [selector],
      feeEstimator: _estimator,
      eligibilityFilter: filter,
    );

// ---------------------------------------------------------------------------

void main() {
  late FakeUtxoRepository repo;
  late FakeNodeTransactionGateway gateway;
  late FakeCoinSelector selector;
  late FakeUtxoEligibilityFilter filter;

  setUp(() {
    repo = FakeUtxoRepository();
    gateway = FakeNodeTransactionGateway();
    selector = FakeCoinSelector();
    filter = FakeUtxoEligibilityFilter();
  });

  group('PrepareNodeSendUseCase', () {
    // PN1 — eligibility filter is called with EligibilityPolicy.node.
    test('PN1: calls eligibilityFilter with EligibilityPolicy.node', () async {
      final utxo = _utxo(txid: 'a', sat: 50000);
      repo.utxos = [utxo];
      filter.result = [_candidate(txid: 'a', sat: 50000)];

      final uc = _makeUseCase(
        repo: repo,
        gateway: gateway,
        selector: selector,
        filter: filter,
      );
      await uc(walletName: 'test', targetSat: const Satoshi(1000), feeRateSatPerVbyte: 1);

      expect(filter.capturedPolicy, equals(EligibilityPolicy.node));
    });

    // PN2 — filtered candidates (not raw UTXOs) are passed to selectors.
    test('PN2: passes filtered candidates to selectors, not raw UTXOs', () async {
      // Raw repo has 2 UTXOs; filter returns only 1.
      repo.utxos = [
        _utxo(txid: 'keep', sat: 50000),
        _utxo(txid: 'drop', sat: 100),
      ];
      final kept = _candidate(txid: 'keep', sat: 50000);
      filter.result = [kept];

      final uc = _makeUseCase(
        repo: repo,
        gateway: gateway,
        selector: selector,
        filter: filter,
      );
      await uc(walletName: 'test', targetSat: const Satoshi(1000), feeRateSatPerVbyte: 1);

      expect(selector.capturedCandidates, hasLength(1));
      expect(selector.capturedCandidates?.first.txid, equals('keep'));
    });

    // PN3 — selector throwing InsufficientFundsException is omitted from result.
    test('PN3: omits strategy when selector throws InsufficientFundsException', () async {
      repo.utxos = [_utxo(txid: 'a', sat: 1000)];
      filter.result = [_candidate(txid: 'a', sat: 1000)];
      selector.throwOnSelect = const InsufficientFundsException(
        available: Satoshi(1000),
        required: Satoshi(9000),
      );

      final uc = _makeUseCase(
        repo: repo,
        gateway: gateway,
        selector: selector,
        filter: filter,
      );
      final prep = await uc(
        walletName: 'test',
        targetSat: const Satoshi(5000),
        feeRateSatPerVbyte: 1,
      );

      expect(prep.strategies, isNot(contains('fake')));
    });

    // PN4 — selector throwing CoinSelectionNoSolutionException is omitted.
    test('PN4: omits strategy when selector throws CoinSelectionNoSolutionException', () async {
      repo.utxos = [_utxo(txid: 'a', sat: 50000)];
      filter.result = [_candidate(txid: 'a', sat: 50000)];
      selector.throwOnSelect = const CoinSelectionNoSolutionException();

      final uc = _makeUseCase(
        repo: repo,
        gateway: gateway,
        selector: selector,
        filter: filter,
      );
      final prep = await uc(
        walletName: 'test',
        targetSat: const Satoshi(1000),
        feeRateSatPerVbyte: 1,
      );

      expect(prep.strategies, isNot(contains('fake')));
    });

    // PN5 — all selectors fail → strategies.isEmpty; use case does NOT throw.
    test('PN5: returns empty strategies when all selectors fail — does not throw', () async {
      repo.utxos = [_utxo(txid: 'a', sat: 100)];
      filter.result = [_candidate(txid: 'a', sat: 100)];
      selector.throwOnSelect = const InsufficientFundsException(
        available: Satoshi(100),
        required: Satoshi(9000),
      );

      final uc = _makeUseCase(
        repo: repo,
        gateway: gateway,
        selector: selector,
        filter: filter,
      );
      final prep = await uc(
        walletName: 'test',
        targetSat: const Satoshi(5000),
        feeRateSatPerVbyte: 1,
      );

      expect(prep.strategies, isEmpty);
    });

    // PN6 — unknown exception from repository (infrastructure) is wrapped.
    // Selector programmer errors (TypeError, StateError) are NOT wrapped here;
    // they propagate to the zone handler per selective-catch convention.
    test('PN6: wraps unknown infrastructure exception in TransactionPreparationException', () async {
      repo.throwOnGet = Exception('unexpected network failure');
      filter.result = [];

      final uc = _makeUseCase(
        repo: repo,
        gateway: gateway,
        selector: selector,
        filter: filter,
      );

      expect(
        () => uc(walletName: 'test', targetSat: const Satoshi(1000), feeRateSatPerVbyte: 1),
        throwsA(isA<TransactionPreparationException>()),
      );
    });
  });
}
