import 'package:keys/keys.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

import 'fakes/fake_broadcast_gateway.dart';
import 'fakes/fake_transaction_signer.dart';

void main() {
  group('SendHdTransactionUseCase', () {
    late FakeTransactionSigner signer;
    late FakeBroadcastGateway broadcastGateway;
    late SendHdTransactionUseCase useCase;

    setUp(() {
      signer = FakeTransactionSigner();
      broadcastGateway = FakeBroadcastGateway();
      useCase = SendHdTransactionUseCase(
        signer: signer,
        broadcastDataSource: broadcastGateway,
      );
    });

    Future<String> send({Object? signerThrows, Object? broadcastThrows}) {
      signer.signThrows = signerThrows;
      broadcastGateway.broadcastThrows = broadcastThrows;

      return useCase.call(
        preparation: _buildPreparation(),
        strategyName: 'fifo',
        walletId: 'wallet_1',
        recipientAddress: 'bc1qrecipient',
        amountSat: const Satoshi(99000),
        bech32Hrp: 'bc',
      );
    }

    test('returns txid on success', () async {
      expect(await send(), 'txid_abc123');
    });

    test('throws TransactionPreparationException when strategyName not found', () {
      expect(
        () => useCase.call(
          preparation: _buildPreparation(),
          strategyName: 'nonexistent',
          walletId: 'wallet_1',
          recipientAddress: 'bc1qrecipient',
          amountSat: const Satoshi(99000),
          bech32Hrp: 'bc',
        ),
        throwsA(isA<TransactionPreparationException>()),
      );
    });

    group('signing failures → TransactionSigningException (D1 correctness)', () {
      test('KeysSigningException translates to TransactionSigningException', () async {
        await expectLater(
          send(signerThrows: const KeysSigningException()),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('KeysDerivationException translates to TransactionSigningException', () async {
        await expectLater(
          send(signerThrows: const KeysDerivationException()),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('KeysSeedNotFoundException translates to TransactionSigningException', () async {
        await expectLater(
          send(signerThrows: const KeysSeedNotFoundException()),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('KeysStorageException translates to TransactionSigningException', () async {
        await expectLater(
          send(signerThrows: const KeysStorageException()),
          throwsA(isA<TransactionSigningException>()),
        );
      });

      test('signing failure is NOT mislabeled as TransactionBroadcastException', () async {
        await expectLater(
          send(signerThrows: const KeysSigningException()),
          throwsA(isNot(isA<TransactionBroadcastException>())),
        );
      });
    });

    group('broadcast failures → TransactionBroadcastException', () {
      test('RpcException from broadcast translates to TransactionBroadcastException', () async {
        await expectLater(
          send(
            broadcastThrows: const RpcException(
              'sendrawtransaction',
              {'code': -25, 'message': 'Missing inputs'},
            ),
          ),
          throwsA(isA<TransactionBroadcastException>()),
        );
      });
    });

    group('programmer errors propagate', () {
      test('TypeError from signer propagates — not wrapped', () async {
        await expectLater(
          send(signerThrows: TypeError()),
          throwsA(isA<TypeError>()),
        );
      });

      test('StateError from broadcast propagates', () async {
        await expectLater(
          send(broadcastThrows: StateError('programmer bug')),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}

HdSendPreparation _buildPreparation() {
  const candidate = CoinCandidate(
    txid: 'utxo_txid',
    vout: 0,
    amountSat: Satoshi(100000),
    age: 1,
  );

  const signingInput = SigningInput(
    txid: 'utxo_txid',
    vout: 0,
    amountSat: Satoshi(100000),
    address: 'bc1qtest',
    derivationIndex: 0,
    addressType: AddressType.nativeSegwit,
  );

  return const HdSendPreparation(
    candidates: [candidate],
    strategies: {
      'fifo': CoinSelectionResult(
        inputs: [candidate],
        totalInputSat: Satoshi(100000),
        feeSat: Satoshi(1000),
        changeSat: Satoshi.zero,
      ),
    },
    signingInputs: {('utxo_txid', 0): signingInput},
    changeAddress: 'bc1qchange',
  );
}
