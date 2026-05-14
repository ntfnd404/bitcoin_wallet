import 'package:bitcoin_wallet/core/adapters/hd_transaction_signer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keys/keys.dart' show KeysDerivationException, KeysSigningException;
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart' as tx show SigningInput;

import 'helpers/fake_sign_transaction_use_case.dart';

void main() {
  group('HdTransactionSigner', () {
    late FakeSignTransactionUseCase fakeUseCase;
    late HdTransactionSigner signer;

    const walletId = 'wallet-1';
    const bech32Hrp = 'bcrt';

    setUp(() {
      fakeUseCase = FakeSignTransactionUseCase();
      signer = HdTransactionSigner(signTransaction: fakeUseCase.call);
    });

    test('maps tx.SigningInput fields to SigningInputParam correctly', () async {
      fakeUseCase.result = 'hexresult';

      const input = tx.SigningInput(
        txid: 'aaabbbccc',
        vout: 2,
        amountSat: Satoshi(50000),
        address: 'bcrt1qtest',
        derivationIndex: 7,
        addressType: AddressType.nativeSegwit,
      );

      await signer.sign(
        walletId: walletId,
        inputs: [input],
        recipientAddress: 'bcrt1qrecipient',
        amountSat: const Satoshi(40000),
        changeAddress: 'bcrt1qchange',
        changeSat: const Satoshi(9000),
        bech32Hrp: bech32Hrp,
      );

      final captured = fakeUseCase.capturedInputs;
      expect(captured, isNotNull);
      expect(captured!.length, 1);

      final param = captured.first;
      expect(param.txid, equals('aaabbbccc'));
      expect(param.vout, equals(2));
      expect(param.amountSat, equals(const Satoshi(50000)));
      expect(param.derivationIndex, equals(7));
      expect(param.type, equals(AddressType.nativeSegwit));
    });

    test('KeysSigningException from use case propagates unchanged', () async {
      fakeUseCase.throws = const KeysSigningException();

      await expectLater(
        signer.sign(
          walletId: walletId,
          inputs: const [],
          recipientAddress: 'bcrt1qrecipient',
          amountSat: const Satoshi(40000),
          changeAddress: 'bcrt1qchange',
          changeSat: const Satoshi(0),
          bech32Hrp: bech32Hrp,
        ),
        throwsA(isA<KeysSigningException>()),
      );
    });

    test('KeysDerivationException from use case propagates unchanged', () async {
      fakeUseCase.throws = const KeysDerivationException();

      await expectLater(
        signer.sign(
          walletId: walletId,
          inputs: const [],
          recipientAddress: 'bcrt1qrecipient',
          amountSat: const Satoshi(40000),
          changeAddress: 'bcrt1qchange',
          changeSat: const Satoshi(0),
          bech32Hrp: bech32Hrp,
        ),
        throwsA(isA<KeysDerivationException>()),
      );
    });
  });
}
