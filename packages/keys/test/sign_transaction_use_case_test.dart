import 'package:keys/keys.dart'
    show
        KeysDerivationException,
        KeysSeedNotFoundException,
        KeysSigningException,
        Mnemonic,
        SignTransactionUseCase,
        SigningInputParam,
        SigningOutput;
import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';

import 'fakes/fake_key_derivation_service.dart';
import 'fakes/fake_seed_repository.dart';
import 'fakes/fake_transaction_signing_service.dart';

void main() {
  group('SignTransactionUseCase', () {
    late FakeSeedRepository seedRepository;
    late FakeKeyDerivationService derivation;
    late FakeTransactionSigningService signing;
    late SignTransactionUseCase useCase;

    const walletId = 'wallet-1';
    final mnemonic12 = List.filled(12, 'abandon');

    const testInput = SigningInputParam(
      txid: 'aaaa',
      vout: 0,
      amountSat: Satoshi(100000),
      type: AddressType.nativeSegwit,
      derivationIndex: 0,
    );

    const testOutput = SigningOutput(
      address: 'bcrt1qrecipient',
      amountSat: Satoshi(99000),
    );

    setUp(() {
      seedRepository = FakeSeedRepository();
      derivation = FakeKeyDerivationService();
      signing = FakeTransactionSigningService();
      useCase = SignTransactionUseCase(
        seedRepository: seedRepository,
        derivation: derivation,
        signing: signing,
      );
    });

    test('signs transaction and returns hex on happy path', () async {
      seedRepository.storeSeedSync(walletId, Mnemonic(words: mnemonic12));
      signing.signResult = 'aabbcc';

      final result = await useCase(
        walletId: walletId,
        inputs: [testInput],
        outputs: [testOutput],
        bech32Hrp: 'bcrt',
      );

      expect(result, 'aabbcc');
    });

    test('throws KeysSeedNotFoundException when seed not found', () async {
      await expectLater(
        useCase(
          walletId: walletId,
          inputs: [testInput],
          outputs: [testOutput],
          bech32Hrp: 'bcrt',
        ),
        throwsA(isA<KeysSeedNotFoundException>()),
      );
    });

    test('maps StateError from derivation to KeysDerivationException', () async {
      seedRepository.storeSeedSync(walletId, Mnemonic(words: mnemonic12));
      derivation.throwOnDerivePrivateKey = StateError('sentinel_DEADBEEF');

      Object? caught;
      try {
        await useCase(
          walletId: walletId,
          inputs: [testInput],
          outputs: [testOutput],
          bech32Hrp: 'bcrt',
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<KeysDerivationException>());
      expect(caught.toString(), isNot(contains('DEADBEEF')));
    });

    test(
        'maps unexpected signing error to KeysSigningException without leaking message',
        () async {
      seedRepository.storeSeedSync(walletId, Mnemonic(words: mnemonic12));
      signing.signThrows = Exception('raw_key=CAFEBABE');

      Object? caught;
      try {
        await useCase(
          walletId: walletId,
          inputs: [testInput],
          outputs: [testOutput],
          bech32Hrp: 'bcrt',
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<KeysSigningException>());
      expect(caught.toString(), isNot(contains('CAFEBABE')));
    });

    test('preserves original stack trace on KeysDerivationException', () async {
      seedRepository.storeSeedSync(walletId, Mnemonic(words: mnemonic12));
      derivation.throwOnDerivePrivateKey = StateError('sentinel_DEADBEEF');

      StackTrace? capturedTrace;
      try {
        await useCase(
          walletId: walletId,
          inputs: [testInput],
          outputs: [testOutput],
          bech32Hrp: 'bcrt',
        );
      } catch (_, stack) {
        capturedTrace = stack;
      }

      expect(capturedTrace, isNotNull);
      expect(capturedTrace.toString(), isNotEmpty);
    });

    test('preserves original stack trace on KeysSigningException', () async {
      seedRepository.storeSeedSync(walletId, Mnemonic(words: mnemonic12));
      signing.signThrows = Exception('raw_key=CAFEBABE');

      StackTrace? capturedTrace;
      try {
        await useCase(
          walletId: walletId,
          inputs: [testInput],
          outputs: [testOutput],
          bech32Hrp: 'bcrt',
        );
      } catch (_, stack) {
        capturedTrace = stack;
      }

      expect(capturedTrace, isNotNull);
      expect(capturedTrace.toString(), isNotEmpty);
    });

    test(
        'ArgumentError from signing service is mapped to KeysSigningException '
        '(security-first policy)', () async {
      seedRepository.storeSeedSync(walletId, Mnemonic(words: mnemonic12));
      signing.signThrows = ArgumentError('bad inputs');

      await expectLater(
        useCase(
          walletId: walletId,
          inputs: [testInput],
          outputs: [testOutput],
          bech32Hrp: 'bcrt',
        ),
        throwsA(isA<KeysSigningException>()),
      );
    });
  });
}
