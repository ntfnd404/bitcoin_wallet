import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/application/source/hd_pinned_utxo_source.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

import '../fakes/fake_address_repository.dart';

void main() {
  late FakeAddressRepository addressRepo;

  setUp(() {
    addressRepo = FakeAddressRepository();
  });

  group('HdPinnedUtxoSource', () {
    test('resolves each pinned input to candidate + SigningInput', () async {
      addressRepo.addresses = [
        _address('bcrt1qaddr0', index: 0),
        _address('bcrt1qaddr1', index: 1),
      ];
      final inputs = [
        _utxo(txid: 'a', address: 'bcrt1qaddr0'),
        _utxo(txid: 'b', address: 'bcrt1qaddr1'),
      ];

      final source = HdPinnedUtxoSource(
        walletId: 'w',
        pinnedInputs: inputs,
        addressRepository: addressRepo,
      );

      final result = await source.resolve();

      expect(result.candidates, hasLength(2));
      final hdCtx = result.signingContext as HdSigningContext;
      expect(hdCtx.inputs.keys, containsAll(<(String, int)>[('a', 0), ('b', 0)]));
      expect(hdCtx.inputs[('a', 0)]!.derivationIndex, equals(0));
      expect(hdCtx.inputs[('b', 0)]!.derivationIndex, equals(1));
    });

    test('throws UnknownPinnedInputAddressException when address not in lookup', () async {
      addressRepo.addresses = [_address('bcrt1qknown', index: 0)];
      final inputs = [_utxo(txid: 'unknown', address: 'bcrt1qmissing')];

      final source = HdPinnedUtxoSource(
        walletId: 'w',
        pinnedInputs: inputs,
        addressRepository: addressRepo,
      );

      expect(
        source.resolve,
        throwsA(
          isA<UnknownPinnedInputAddressException>()
              .having((e) => e.txid, 'txid', 'unknown')
              .having((e) => e.vout, 'vout', 0)
              .having((e) => e.address, 'address', 'bcrt1qmissing'),
        ),
      );
    });

    test('throws UnknownPinnedInputAddressException when address is null', () async {
      addressRepo.addresses = [_address('bcrt1qknown', index: 0)];
      final inputs = [_utxo(txid: 'nullAddr', address: null)];

      final source = HdPinnedUtxoSource(
        walletId: 'w',
        pinnedInputs: inputs,
        addressRepository: addressRepo,
      );

      expect(
        source.resolve,
        throwsA(isA<UnknownPinnedInputAddressException>()),
      );
    });

    test('translates AddressException to TransactionPreparationException', () async {
      addressRepo.throwOnGetAddresses = const AddressStorageException();
      final source = HdPinnedUtxoSource(
        walletId: 'w',
        pinnedInputs: const [],
        addressRepository: addressRepo,
      );

      expect(
        source.resolve,
        throwsA(isA<TransactionPreparationException>()),
      );
    });

    test('changeAddress is highest-index native-segwit address', () async {
      addressRepo.addresses = [
        _address('bcrt1qaddr0', index: 0),
        _address('bcrt1qaddr7', index: 7),
        _address('bcrt1qaddr3', index: 3),
      ];

      final source = HdPinnedUtxoSource(
        walletId: 'w',
        pinnedInputs: const [],
        addressRepository: addressRepo,
      );

      final result = await source.resolve();

      expect(result.changeAddress, equals('bcrt1qaddr7'));
    });

    test('does not mutate caller-supplied pinnedInputs list ordering', () async {
      addressRepo.addresses = [
        _address('bcrt1qaddr0', index: 0),
        _address('bcrt1qaddr1', index: 1),
      ];
      final inputs = [
        _utxo(txid: 'z', address: 'bcrt1qaddr1'),
        _utxo(txid: 'a', address: 'bcrt1qaddr0'),
      ];
      final originalOrder = List<Utxo>.of(inputs);

      final source = HdPinnedUtxoSource(
        walletId: 'w',
        pinnedInputs: inputs,
        addressRepository: addressRepo,
      );

      await source.resolve();

      expect(inputs, equals(originalOrder));
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

Utxo _utxo({
  required String txid,
  required String? address,
  int sat = 10000,
}) => Utxo(
  txid: txid,
  vout: 0,
  amountSat: Satoshi(sat),
  confirmations: 3,
  address: address,
  scriptPubKey: '0014abcd',
  type: AddressType.nativeSegwit,
  spendable: true,
);
