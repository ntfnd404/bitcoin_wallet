import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

import 'fakes/fake_address_repository.dart';
import 'fakes/fake_coin_selector.dart';
import 'fakes/fake_utxo_scan_gateway.dart';

const _walletId = 'wallet_1';
const _address = 'bc1qtestaddress';

void main() {
  group('PrepareHdSendUseCase', () {
    test('returns HdSendPreparation with strategy on success', () async {
      final selector = FakeCoinSelector(name: 'fifo');
      final useCase = _makeUseCase(
        addressRepo: _repoWithOneAddress(),
        utxoGateway: _gatewayWithOneUtxo(),
        selectors: [selector],
      );

      final result = await useCase.call(
        walletId: _walletId,
        targetSat: const Satoshi(50000),
        feeRateSatPerVbyte: 5,
      );

      expect(result.strategies, contains('fifo'));
      expect(result.candidates, hasLength(1));
    });

    test('InsufficientFundsException from selector is omitted — strategies table is empty', () async {
      final selector = FakeCoinSelector(name: 'fifo')
        ..throwOnSelect = const InsufficientFundsException(
          available: Satoshi(1000),
          required: Satoshi(99000),
        );
      final useCase = _makeUseCase(
        addressRepo: _repoWithOneAddress(),
        utxoGateway: _gatewayWithOneUtxo(),
        selectors: [selector],
      );

      final result = await useCase.call(
        walletId: _walletId,
        targetSat: const Satoshi(99000),
        feeRateSatPerVbyte: 5,
      );

      expect(result.strategies, isEmpty);
    });

    test('InsufficientFundsException reaching outer catch rethrows unchanged', () async {
      // Tests the outer `on InsufficientFundsException { rethrow }` clause at line 111.
      // Using FakeAddressRepository to inject InsufficientFundsException at the repo boundary
      // — the outer catch rethrows it instead of wrapping as TransactionPreparationException.
      final repo = FakeAddressRepository()
        ..throwOnGetAddresses = const InsufficientFundsException(
          available: Satoshi(0),
          required: Satoshi(50000),
        );
      final useCase = _makeUseCase(
        addressRepo: repo,
        utxoGateway: FakeUtxoScanGateway(),
        selectors: [FakeCoinSelector()],
      );

      await expectLater(
        useCase.call(walletId: _walletId, targetSat: const Satoshi(50000), feeRateSatPerVbyte: 5),
        throwsA(isA<InsufficientFundsException>()),
      );
    });

    test('AddressException from address repo translates to TransactionPreparationException', () async {
      final repo = FakeAddressRepository()..throwOnGetAddresses = const AddressStorageException();
      final useCase = _makeUseCase(
        addressRepo: repo,
        utxoGateway: FakeUtxoScanGateway(),
        selectors: [FakeCoinSelector()],
      );

      await expectLater(
        useCase.call(walletId: _walletId, targetSat: const Satoshi(50000), feeRateSatPerVbyte: 5),
        throwsA(isA<TransactionPreparationException>()),
      );
    });

    test('StateError from selector propagates — not wrapped as TransactionPreparationException', () async {
      final selector = FakeCoinSelector(name: 'fifo')..throwOnSelect = StateError('programmer bug');
      final useCase = _makeUseCase(
        addressRepo: _repoWithOneAddress(),
        utxoGateway: _gatewayWithOneUtxo(),
        selectors: [selector],
      );

      await expectLater(
        useCase.call(walletId: _walletId, targetSat: const Satoshi(50000), feeRateSatPerVbyte: 5),
        throwsA(isA<StateError>()),
      );
    });
  });
}

PrepareHdSendUseCase _makeUseCase({
  required FakeAddressRepository addressRepo,
  required FakeUtxoScanGateway utxoGateway,
  required List<CoinSelector> selectors,
}) => PrepareHdSendUseCase(
  addressRepository: addressRepo,
  utxoScanDataSource: utxoGateway,
  selectors: selectors,
  feeEstimator: const P2wpkhFeeEstimator(),
);

FakeAddressRepository _repoWithOneAddress() {
  final repo = FakeAddressRepository();
  repo.add(
    Address(
      value: _address,
      type: AddressType.nativeSegwit,
      walletId: _walletId,
      index: 0,
    ),
  );

  return repo;
}

FakeUtxoScanGateway _gatewayWithOneUtxo() {
  final gateway = FakeUtxoScanGateway();
  gateway.scanResult = [
    const ScannedUtxo(
      txid: 'utxo_tx',
      vout: 0,
      amountSat: Satoshi(100000),
      scriptPubKeyHex: 'deadbeef',
      height: 100,
      address: _address,
    ),
  ];

  return gateway;
}
