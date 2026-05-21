import 'dart:typed_data';

import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

import 'fakes/fake_broadcast_gateway.dart';
import 'fakes/fake_node_transaction_gateway.dart';
import 'fakes/fake_utxo_repository.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Utxo _utxo({int amountSat = 100000, int confirmations = 1}) => Utxo(
  txid: 'txid_${amountSat}_$confirmations',
  vout: 0,
  amountSat: Satoshi(amountSat),
  confirmations: confirmations,
  address: 'bcrt1qtest',
  scriptPubKey: '0014abcd',
  type: AddressType.nativeSegwit,
  spendable: true,
);

SendOpReturnUseCase _makeUseCase({
  FakeUtxoRepository? utxoRepo,
  FakeNodeTransactionGateway? nodeGateway,
  FakeBroadcastGateway? broadcastGateway,
}) => SendOpReturnUseCase(
  utxoRepository: utxoRepo ?? (FakeUtxoRepository()..utxos = [_utxo()]),
  nodeDataSource: nodeGateway ?? FakeNodeTransactionGateway(),
  broadcastDataSource: broadcastGateway ?? FakeBroadcastGateway(),
  feeEstimator: const P2wpkhFeeEstimator(),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SendOpReturnUseCase', () {
    final data = Uint8List.fromList('Hello'.codeUnits);

    // SOR1
    test('SOR1: happy path returns txid from broadcast gateway', () async {
      final broadcastGateway = FakeBroadcastGateway()
        ..broadcastResult = 'txid_opreturn_001';

      final useCase = _makeUseCase(broadcastGateway: broadcastGateway);

      final txid = await useCase(
        walletName: 'test',
        data: data,
        feeRateSatPerVbyte: 1,
      );

      expect(txid, equals('txid_opreturn_001'));
    });

    // SOR2
    test('SOR2: InsufficientFundsException when no UTXOs cover fee', () async {
      final utxoRepo = FakeUtxoRepository()..utxos = [];
      final useCase = _makeUseCase(utxoRepo: utxoRepo);

      await expectLater(
        useCase(walletName: 'test', data: data, feeRateSatPerVbyte: 1),
        throwsA(isA<InsufficientFundsException>()),
      );
    });

    // SOR3
    test('SOR3: TransactionBroadcastException from broadcast propagates', () async {
      final broadcastGateway = FakeBroadcastGateway()
        ..broadcastThrows = const TransactionBroadcastException();

      final useCase = _makeUseCase(broadcastGateway: broadcastGateway);

      await expectLater(
        useCase(walletName: 'test', data: data, feeRateSatPerVbyte: 1),
        throwsA(isA<TransactionBroadcastException>()),
      );
    });
  });
}
