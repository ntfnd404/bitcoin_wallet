import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/application/source/hd_auto_utxo_source.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

import '../fakes/fake_address_repository.dart';
import '../fakes/fake_utxo_scan_gateway.dart';

void main() {
  late FakeAddressRepository addressRepo;
  late FakeUtxoScanGateway scanGateway;

  setUp(() {
    addressRepo = FakeAddressRepository();
    scanGateway = FakeUtxoScanGateway();
  });

  group('HdAutoUtxoSource', () {
    test('candidates carry age = length - i after ascending height sort', () async {
      addressRepo.addresses = [
        _address('bcrt1qaddr0', index: 0),
        _address('bcrt1qaddr1', index: 1),
      ];
      // Insert out of order to verify sort.
      scanGateway.scanResult = [
        _scanned(txid: 'newer', height: 200, address: 'bcrt1qaddr1'),
        _scanned(txid: 'older', height: 100, address: 'bcrt1qaddr0'),
      ];

      final source = HdAutoUtxoSource(
        walletId: 'w',
        addressRepository: addressRepo,
        utxoScanGateway: scanGateway,
      );

      final result = await source.resolve();

      expect(result.candidates, hasLength(2));
      // After ascending sort: older(i=0) → age=2, newer(i=1) → age=1.
      expect(result.candidates[0].txid, equals('older'));
      expect(result.candidates[0].age, equals(2));
      expect(result.candidates[1].txid, equals('newer'));
      expect(result.candidates[1].age, equals(1));
    });

    test('signingInputs keyed by (txid, vout) for resolvable addresses', () async {
      addressRepo.addresses = [_address('bcrt1qknown', index: 5)];
      scanGateway.scanResult = [
        _scanned(txid: 'a', vout: 1, height: 100, address: 'bcrt1qknown'),
      ];

      final source = HdAutoUtxoSource(
        walletId: 'w',
        addressRepository: addressRepo,
        utxoScanGateway: scanGateway,
      );

      final result = await source.resolve();
      final ctx = result.signingContext;

      expect(ctx, isA<HdSigningContext>());
      final hdCtx = ctx as HdSigningContext;
      expect(hdCtx.inputs.keys, contains(('a', 1)));
      final si = hdCtx.inputs[('a', 1)]!;
      expect(si.derivationIndex, equals(5));
      expect(si.address, equals('bcrt1qknown'));
    });

    test('changeAddress is highest-index native-segwit address', () async {
      addressRepo.addresses = [
        _address('bcrt1qaddr0', index: 0),
        _address('bcrt1qaddr5', index: 5),
        _address('bcrt1qaddr3', index: 3),
      ];
      scanGateway.scanResult = <ScannedUtxo>[];

      final source = HdAutoUtxoSource(
        walletId: 'w',
        addressRepository: addressRepo,
        utxoScanGateway: scanGateway,
      );

      final result = await source.resolve();

      expect(result.changeAddress, equals('bcrt1qaddr5'));
    });

    test('changeAddress is empty when no native-segwit addresses', () async {
      addressRepo.addresses = <Address>[];
      scanGateway.scanResult = <ScannedUtxo>[];

      final source = HdAutoUtxoSource(
        walletId: 'w',
        addressRepository: addressRepo,
        utxoScanGateway: scanGateway,
      );

      final result = await source.resolve();

      expect(result.changeAddress, isEmpty);
    });

    test('HdSigningContext.inputs is unmodifiable', () async {
      addressRepo.addresses = [_address('bcrt1qknown', index: 0)];
      scanGateway.scanResult = [
        _scanned(txid: 'a', height: 1, address: 'bcrt1qknown'),
      ];

      final source = HdAutoUtxoSource(
        walletId: 'w',
        addressRepository: addressRepo,
        utxoScanGateway: scanGateway,
      );

      final result = await source.resolve();
      final hdCtx = result.signingContext as HdSigningContext;

      expect(
        () => hdCtx.inputs[('zzz', 99)] = const SigningInput(
          txid: 'zzz',
          vout: 99,
          amountSat: Satoshi(1),
          address: 'x',
          derivationIndex: 0,
          addressType: AddressType.nativeSegwit,
        ),
        throwsUnsupportedError,
      );
    });

    test('translates AddressException to TransactionPreparationException', () async {
      addressRepo.throwOnGetAddresses = const AddressStorageException();

      final source = HdAutoUtxoSource(
        walletId: 'w',
        addressRepository: addressRepo,
        utxoScanGateway: scanGateway,
      );

      expect(
        source.resolve,
        throwsA(isA<TransactionPreparationException>()),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Address _address(String value, {required int index}) => Address(
  value: value,
  type: AddressType.nativeSegwit,
  walletId: 'w',
  index: index,
);

ScannedUtxo _scanned({
  required String txid,
  int vout = 0,
  required int height,
  required String? address,
}) => ScannedUtxo(
  txid: txid,
  vout: vout,
  amountSat: const Satoshi(10000),
  scriptPubKeyHex: '0014abcd',
  height: height,
  address: address,
);
