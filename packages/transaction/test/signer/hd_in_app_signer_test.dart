import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/application/signer/hd_in_app_signer.dart';
import 'package:transaction/transaction.dart';

import '../fakes/fake_broadcast_gateway.dart';
import '../fakes/fake_transaction_signer.dart';
import 'helpers/custom_test_exception.dart';

const _kChosenAddress = 'bc1qchosenaddressuniquemarker';
const _kUnrelatedAddress = 'bc1qunrelatedaddress';

void main() {
  group('HdInAppSigner', () {
    late FakeTransactionSigner txSigner;
    late FakeBroadcastGateway broadcastGateway;
    late HdInAppSigner signer;

    setUp(() {
      txSigner = FakeTransactionSigner();
      broadcastGateway = FakeBroadcastGateway();
      signer = HdInAppSigner(
        walletId: 'hd_wallet_1',
        bech32Hrp: 'bc',
        transactionSigner: txSigner,
        broadcastGateway: broadcastGateway,
      );
    });

    test('happy path — returns broadcast txid; captures walletId and bech32Hrp', () async {
      final txid = await signer.signAndBroadcast(
        strategy: _buildStrategy(),
        signingContext: HdSigningContext({
          (_kChosenTxid, 0): _signingInputFor(_kChosenAddress, 0, derivationIndex: 7),
        }),
        recipientAddress: 'bc1qrecipient',
        amountSat: const Satoshi(99000),
        changeAddress: 'bc1qchange',
      );

      expect(txid, 'txid_abc123');
      expect(txSigner.capturedWalletId, 'hd_wallet_1');
      expect(txSigner.capturedBech32Hrp, 'bc');
    });

    test('rejection — NodeSigningContext throws TransactionSigningException; no sign call', () async {
      await expectLater(
        signer.signAndBroadcast(
          strategy: _buildStrategy(),
          signingContext: const NodeSigningContext(),
          recipientAddress: 'bc1qrecipient',
          amountSat: const Satoshi(99000),
          changeAddress: 'bc1qchange',
        ),
        throwsA(isA<TransactionSigningException>()),
      );
      expect(txSigner.capturedWalletId, isNull);
      expect(txSigner.capturedBech32Hrp, isNull);
    });

    test('chosen-subset iteration — extra unrelated map entry is ignored (PRD req #1)', () async {
      await signer.signAndBroadcast(
        strategy: _buildStrategy(),
        signingContext: HdSigningContext({
          (_kChosenTxid, 0): _signingInputFor(_kChosenAddress, 0, derivationIndex: 7),
          ('unrelated_txid', 5): _signingInputFor(_kUnrelatedAddress, 5, derivationIndex: 99),
        }),
        recipientAddress: 'bc1qrecipient',
        amountSat: const Satoshi(99000),
        changeAddress: 'bc1qchange',
      );

      expect(txSigner.capturedInputs, isNotNull);
      expect(txSigner.capturedInputs!.length, 1);
      expect(txSigner.capturedInputs!.single.txid, _kChosenTxid);
      expect(txSigner.capturedInputs!.single.vout, 0);
      expect(
        txSigner.capturedInputs!.any((i) => i.address == _kUnrelatedAddress),
        isFalse,
      );
    });

    test('missing signing input — throws MissingSigningInputException(txid, vout) (PRD req #4)', () async {
      await expectLater(
        signer.signAndBroadcast(
          strategy: _buildStrategy(),
          signingContext: HdSigningContext(const {}),
          recipientAddress: 'bc1qrecipient',
          amountSat: const Satoshi(99000),
          changeAddress: 'bc1qchange',
        ),
        throwsA(
          isA<MissingSigningInputException>()
              .having((e) => e.txid, 'txid', _kChosenTxid)
              .having((e) => e.vout, 'vout', 0),
        ),
      );
    });

    test('MissingSigningInputException.toString() leaks no derivationIndex / address (PRD req #3)', () async {
      // Build a context that contains the address but at the WRONG key, so
      // the chosen candidate lookup misses. This proves that even if the
      // signer "saw" the SigningInput nearby, the thrown exception's
      // toString() carries only (txid, vout).
      const unrelatedTxid = 'completely_unrelated_txid';
      MissingSigningInputException? captured;
      try {
        await signer.signAndBroadcast(
          strategy: _buildStrategy(),
          signingContext: HdSigningContext({
            (unrelatedTxid, 99): _signingInputFor(_kChosenAddress, 99, derivationIndex: 42),
          }),
          recipientAddress: 'bc1qrecipient',
          amountSat: const Satoshi(99000),
          changeAddress: 'bc1qchange',
        );
      } on MissingSigningInputException catch (e) {
        captured = e;
      }

      expect(captured, isNotNull);
      final asString = captured.toString();
      expect(asString.contains('derivationIndex:'), isFalse);
      expect(asString.contains(_kChosenAddress), isFalse);
      expect(asString, 'MissingSigningInputException(txid: $_kChosenTxid, vout: 0)');
    });

    test('signing-layer typed propagation — TransactionSigningException rethrown unchanged', () async {
      txSigner.signThrows = const TransactionSigningException();

      await expectLater(
        signer.signAndBroadcast(
          strategy: _buildStrategy(),
          signingContext: HdSigningContext({
            (_kChosenTxid, 0): _signingInputFor(_kChosenAddress, 0, derivationIndex: 7),
          }),
          recipientAddress: 'bc1qrecipient',
          amountSat: const Satoshi(99000),
          changeAddress: 'bc1qchange',
        ),
        throwsA(isA<TransactionSigningException>()),
      );
    });

    test('broadcast-layer typed propagation — TransactionBroadcastException rethrown, NOT relabeled', () async {
      broadcastGateway.broadcastThrows = const TransactionBroadcastException();

      await expectLater(
        signer.signAndBroadcast(
          strategy: _buildStrategy(),
          signingContext: HdSigningContext({
            (_kChosenTxid, 0): _signingInputFor(_kChosenAddress, 0, derivationIndex: 7),
          }),
          recipientAddress: 'bc1qrecipient',
          amountSat: const Satoshi(99000),
          changeAddress: 'bc1qchange',
        ),
        throwsA(
          isA<TransactionBroadcastException>().having(
            (_) => true,
            'is not signing',
            isTrue,
          ),
        ),
      );
    });

    test(
      'signing-block broad-typed translation — non-TransactionException becomes TransactionSigningException',
      () async {
        txSigner.signThrows = const CustomTestException();

        await expectLater(
          signer.signAndBroadcast(
            strategy: _buildStrategy(),
            signingContext: HdSigningContext({
              (_kChosenTxid, 0): _signingInputFor(_kChosenAddress, 0, derivationIndex: 7),
            }),
            recipientAddress: 'bc1qrecipient',
            amountSat: const Satoshi(99000),
            changeAddress: 'bc1qchange',
          ),
          throwsA(isA<TransactionSigningException>()),
        );
      },
    );
  });
}

const _kChosenTxid = 'utxo_txid';

CoinSelectionStrategyResult _buildStrategy() {
  const candidate = CoinCandidate(
    txid: _kChosenTxid,
    vout: 0,
    amountSat: Satoshi(100000),
    age: 1,
  );

  return const CoinSelectionStrategyResult(
    name: 'fifo',
    isStochastic: false,
    result: CoinSelectionResult(
      inputs: [candidate],
      totalInputSat: Satoshi(100000),
      feeSat: Satoshi(1000),
      changeSat: Satoshi.zero,
    ),
  );
}

SigningInput _signingInputFor(String address, int vout, {required int derivationIndex}) => SigningInput(
  txid: _kChosenTxid,
  vout: vout,
  amountSat: const Satoshi(100000),
  address: address,
  derivationIndex: derivationIndex,
  addressType: AddressType.nativeSegwit,
);

