import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

import 'fakes/fake_coin_selector.dart';
import 'fakes/fake_fee_estimator.dart';
import 'fakes/fake_node_transaction_gateway.dart';

void main() {
  group('PrepareNodePinnedSendUseCase', () {
    // PNP1: happy path — strategies populated
    test('PNP1: happy path returns NodeSendPreparation with strategies', () async {
      final useCase = _makeUseCase();
      final result = await useCase(
        walletName: 'test',
        pinnedInputs: [_utxo()],
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 1,
      );

      expect(result.strategies, isNotEmpty);
      expect(result.changeAddress, equals('bcrt1qchange'));
    });

    // PNP2: all strategies fail — empty strategies list, no exception
    test('PNP2: all selectors fail → empty strategies list, no throw', () async {
      final selector = FakeCoinSelector(name: 'fail')
        ..throwOnSelect = const InsufficientFundsException(
          available: Satoshi.zero,
          required: Satoshi(99999),
        );
      final useCase = _makeUseCase(selectors: [selector]);

      final result = await useCase(
        walletName: 'test',
        pinnedInputs: [_utxo()],
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 1,
      );

      expect(result.strategies, isEmpty);
    });

    // PNP3: gateway error propagates as TransactionPreparationException
    test('PNP3: gateway error wraps as TransactionPreparationException', () async {
      final gateway = FakeNodeTransactionGateway()
        ..newAddressThrows = Exception('rpc error');
      final useCase = _makeUseCase(gateway: gateway);

      await expectLater(
        useCase(
          walletName: 'test',
          pinnedInputs: [_utxo()],
          targetSat: const Satoshi(50000),
          feeRateSatPerVbyte: 1,
        ),
        throwsA(isA<TransactionPreparationException>()),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Utxo _utxo({int amountSat = 100000}) => Utxo(
  txid: 'utxo_txid',
  vout: 0,
  amountSat: Satoshi(amountSat),
  confirmations: 1,
  address: 'bcrt1qtest',
  scriptPubKey: '0014abcd',
  type: AddressType.nativeSegwit,
  spendable: true,
);

PrepareNodePinnedSendUseCase _makeUseCase({
  FakeNodeTransactionGateway? gateway,
  List<CoinSelector>? selectors,
}) => PrepareNodePinnedSendUseCase(
  nodeDataSource: gateway ?? FakeNodeTransactionGateway(),
  selectors: selectors ?? [FakeCoinSelector()],
  feeEstimator: FakeFeeEstimator(),
);
